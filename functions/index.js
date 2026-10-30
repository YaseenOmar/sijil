
const { onCall, HttpsError } =
  require("firebase-functions/v2/https");

const admin = require("firebase-admin");
const crypto = require("node:crypto");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const Timestamp = admin.firestore.Timestamp;

const REGION = "us-central1";
const DAY_MS = 24 * 60 * 60 * 1000;
const MAX_FAMILIES = 20;

// ========================================
// Shared Helpers
// ========================================

function validId(value) {
  return (
    typeof value === "string" &&
    value.length > 0 &&
    value.length <= 120 &&
    value !== "." &&
    value !== ".." &&
    !value.includes("/")
  );
}

function requiredText(value, maxLength = 200) {
  return (
    typeof value === "string" &&
    value.trim().length > 0 &&
    value.trim().length <= maxLength
  );
}

function requireAuthentication(request) {
  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError(
      "unauthenticated",
      "يجب تسجيل الدخول أولاً"
    );
  }

  if (request.auth.token.email_verified !== true) {
    throw new HttpsError(
      "permission-denied",
      "يجب توثيق البريد الإلكتروني"
    );
  }

  return uid;
}

function orgReference(orgId) {
  return db.collection("organizations").doc(orgId);
}

function eligibilityDocumentId(familyId, assistanceId) {
  return crypto
    .createHash("sha256")
    .update(JSON.stringify([familyId, assistanceId]))
    .digest("hex");
}

// Validate the real user account and, for workers,
// its linked invitation/employee record.
//
// Must be called inside a Firestore transaction,
// before any writes.
async function getAuthorizedUser(
  tx,
  uid,
  organizationId,
  supervisorOnly = false
) {
  const userRef = db.collection("users").doc(uid);
  const userSnap = await tx.get(userRef);

  if (!userSnap.exists) {
    throw new HttpsError(
      "permission-denied",
      "حساب المستخدم غير موجود"
    );
  }

  const user = userSnap.data();

  if (
    user.status !== "active" ||
    user.organizationId !== organizationId
  ) {
    throw new HttpsError(
      "permission-denied",
      "حسابك غير فعال أو غير مرتبط بهذه المؤسسة"
    );
  }

  if (user.role === "supervisor") {
    return {
      uid,
      role: "supervisor",
      organizationId,
      fullName: user.fullName || "",
      areaId: null,
    };
  }

  if (supervisorOnly) {
    throw new HttpsError(
      "permission-denied",
      "هذه العملية متاحة للمشرف فقط"
    );
  }

  if (
    user.role !== "field_worker" ||
    !validId(user.invitationId)
  ) {
    throw new HttpsError(
      "permission-denied",
      "ليس لديك صلاحية تنفيذ هذه العملية"
    );
  }

  const employeeRef = orgReference(organizationId)
    .collection("employees")
    .doc(user.invitationId);

  const employeeSnap = await tx.get(employeeRef);

  if (!employeeSnap.exists) {
    throw new HttpsError(
      "permission-denied",
      "سجل الموظف المرتبط بالحساب غير موجود"
    );
  }

  const employee = employeeSnap.data();

  if (
    employee.uid !== uid ||
    employee.status !== "active" ||
    employee.role !== "field_worker" ||
    employee.organizationId !== organizationId ||
    !validId(employee.areaId)
  ) {
    throw new HttpsError(
      "permission-denied",
      "سجل الموظف غير صالح"
    );
  }

  return {
    uid,
    role: "field_worker",
    organizationId,
    fullName: user.fullName || employee.fullName || "",
    areaId: employee.areaId,
  };
}

function canAccessFamily(actor, family) {
  return (
    family.organizationId === actor.organizationId &&
    (
      actor.role === "supervisor" ||
      family.areaId === actor.areaId
    )
  );
}

function getErrorMessage(error) {
  if (error instanceof HttpsError) {
    return error.message;
  }

  console.error("Cloud Function error:", error);

  return "حدث خطأ غير متوقع، يرجى إعادة المحاولة";
}

// ========================================
// 1. Create Family
// ========================================

exports.createFamily = onCall(
  {
    region: REGION,
    timeoutSeconds: 60,
  },
  async (request) => {
    const uid = requireAuthentication(request);

    const { organizationId, family } = request.data || {};

    if (
      !validId(organizationId) ||
      !family ||
      typeof family !== "object" ||
      Array.isArray(family)
    ) {
      throw new HttpsError(
        "invalid-argument",
        "بيانات الأسرة غير صحيحة"
      );
    }

    const headName = family.headName?.trim();
    const nationalId = family.nationalId?.trim();
    const areaId = family.areaId;

    if (
      !requiredText(headName, 200) ||
      !validId(nationalId) ||
      !validId(areaId)
    ) {
      throw new HttpsError(
        "invalid-argument",
        "اسم رب الأسرة أو رقم الهوية أو المنطقة غير صحيح"
      );
    }

    if (
      !Number.isInteger(family.membersCount) ||
      family.membersCount < 1
    ) {
      throw new HttpsError(
        "invalid-argument",
        "عدد أفراد الأسرة غير صحيح"
      );
    }

    const phoneNumber = family.phoneNumber ?? "";
    const address = family.address ?? "";
    const housingStatus = family.housingStatus ?? "";
    const needs = family.needs ?? [];
    const idCardImagePath = family.idCardImagePath ?? null;

    if (
      typeof phoneNumber !== "string" ||
      phoneNumber.length > 30 ||
      typeof address !== "string" ||
      address.length > 500 ||
      typeof housingStatus !== "string" ||
      housingStatus.length > 100 ||
      !Array.isArray(needs) ||
      needs.length > 50 ||
      !needs.every(
        (need) =>
          typeof need === "string" &&
          need.length <= 100
      ) ||
      (
        idCardImagePath !== null &&
        (
          typeof idCardImagePath !== "string" ||
          idCardImagePath.length > 1000
        )
      )
    ) {
      throw new HttpsError(
        "invalid-argument",
        "بعض بيانات الأسرة غير صحيحة"
      );
    }

    const orgRef = orgReference(organizationId);

    const nationalIdRef = orgRef
      .collection("familyNationalIds")
      .doc(nationalId);

    const familyRef = orgRef
      .collection("families")
      .doc();

    return db.runTransaction(async (tx) => {
      const actor = await getAuthorizedUser(
        tx,
        uid,
        organizationId
      );

      const duplicateSnap = await tx.get(nationalIdRef);

      if (
        actor.role === "field_worker" &&
        actor.areaId !== areaId
      ) {
        throw new HttpsError(
          "permission-denied",
          "لا يمكنك إضافة أسرة خارج منطقتك"
        );
      }

      if (duplicateSnap.exists) {
        const previous = duplicateSnap.data();

        throw new HttpsError(
          "already-exists",
          "الأسرة مسجلة مسبقًا من قبل: " +
            (previous.createdByName || "موظف آخر"),
          {
            familyId: previous.familyId || null,
            createdByName: previous.createdByName || null,
          }
        );
      }

      const createdAt = Timestamp.now();

      tx.create(familyRef, {
        headName,
        nationalId,
        phoneNumber,
        membersCount: family.membersCount,
        address,
        housingStatus,
        needs,
        areaId,
        organizationId,
        createdBy: uid,
        createdAt,
        ...(idCardImagePath !== null
          ? { idCardImagePath }
          : {}),
      });

      tx.create(nationalIdRef, {
        familyId: familyRef.id,
        nationalId,
        createdBy: uid,
        createdByName: actor.fullName,
        createdAt,
      });

      return {
        success: true,
        familyId: familyRef.id,
        message: "تم تسجيل الأسرة بنجاح",
      };
    });
  }
);

// ========================================
// 2. Assign Assistance
// ========================================

exports.assignAssistance = onCall(
  {
    region: REGION,
    timeoutSeconds: 120,
  },
  async (request) => {
    const uid = requireAuthentication(request);

    const {
      organizationId,
      assistanceId,
      familyIds,
      requestId,
      notes = "",
    } = request.data || {};

    if (
      !validId(organizationId) ||
      !validId(assistanceId) ||
      !validId(requestId) ||
      !Array.isArray(familyIds) ||
      familyIds.length < 1 ||
      familyIds.length > MAX_FAMILIES ||
      !familyIds.every(validId) ||
      new Set(familyIds).size !== familyIds.length ||
      typeof notes !== "string" ||
      notes.length > 500
    ) {
      throw new HttpsError(
        "invalid-argument",
        "بيانات طلب التخصيص غير صحيحة"
      );
    }

    const orgRef = orgReference(organizationId);

    const assistanceRef = orgRef
      .collection("assistances")
      .doc(assistanceId);

    const requestRef = orgRef
      .collection("assistanceRequests")
      .doc(requestId);

    const sortedFamilyIds = [...familyIds].sort();

    // Reserve the request identity. Retries must
    // have exactly the same request parameters.
    await db.runTransaction(async (tx) => {
      await getAuthorizedUser(tx, uid, organizationId);

      const savedRequest = await tx.get(requestRef);

      if (savedRequest.exists) {
        const old = savedRequest.data();

        if (
          old.uid !== uid ||
          old.assistanceId !== assistanceId ||
          old.notes !== notes ||
          JSON.stringify(old.familyIds) !==
            JSON.stringify(sortedFamilyIds)
        ) {
          throw new HttpsError(
            "already-exists",
            "معرف الطلب مستخدم لعملية مختلفة"
          );
        }

        return;
      }

      tx.create(requestRef, {
        uid,
        assistanceId,
        familyIds: sortedFamilyIds,
        notes,
        createdAt: Timestamp.now(),
      });
    });

    const results = [];

    // Each family has an independent atomic transaction.
    for (const familyId of sortedFamilyIds) {
      const familyRef = orgRef
        .collection("families")
        .doc(familyId);

      const assignmentRef = orgRef
        .collection("assistanceAssignments")
        .doc(`${requestId}_${familyId}`);

      const eligibilityRef = orgRef
        .collection("assistanceEligibility")
        .doc(
          eligibilityDocumentId(familyId, assistanceId)
        );

      const resultRef = requestRef
        .collection("results")
        .doc(familyId);

      try {
        const result = await db.runTransaction(
          async (tx) => {
            const actor = await getAuthorizedUser(
              tx,
              uid,
              organizationId
            );

            const [
              previousResultSnap,
              assistanceSnap,
              familySnap,
              eligibilitySnap,
              assignmentSnap,
            ] = await Promise.all([
              tx.get(resultRef),
              tx.get(assistanceRef),
              tx.get(familyRef),
              tx.get(eligibilityRef),
              tx.get(assignmentRef),
            ]);

            // Return the original result when retrying.
            if (previousResultSnap.exists) {
              return previousResultSnap.data();
            }

            let rejection = null;

            if (!assistanceSnap.exists) {
              rejection = "المساعدة غير موجودة";
            } else if (
              assistanceSnap.data().isActive !== true
            ) {
              rejection = "المساعدة غير فعالة";
            }

            const assistance = assistanceSnap.exists
              ? assistanceSnap.data()
              : null;

            const cooldownDays = assistance?.cooldownDays;

            if (
              !rejection &&
              (
                !Number.isInteger(cooldownDays) ||
                cooldownDays < 0 ||
                cooldownDays > 36500
              )
            ) {
              rejection = "فترة منع التكرار غير صحيحة";
            }

            if (!rejection && !familySnap.exists) {
              rejection = "الأسرة غير موجودة";
            }

            const family = familySnap.exists
              ? familySnap.data()
              : null;

            if (
              !rejection &&
              !canAccessFamily(actor, family)
            ) {
              rejection = "الأسرة خارج نطاق صلاحياتك";
            }

            const now = Date.now();

            if (!rejection && assignmentSnap.exists) {
              rejection = "تعارض في معرف سجل التخصيص";
            }

            if (!rejection && eligibilitySnap.exists) {
              const previous = eligibilitySnap.data();

              if (
                !(previous.nextEligibleAt instanceof Timestamp)
              ) {
                rejection = "بيانات أهلية الأسرة غير صحيحة";
              } else if (
                previous.nextEligibleAt.toMillis() > now
              ) {
                rejection =
                  "الأسرة حصلت على هذه المساعدة خلال فترة المنع";
              }
            }

            // Store business rejections too.
            // This makes retries return the same result.
            if (rejection) {
              const rejectedResult = {
                familyId,
                success: false,
                message: rejection,
              };

              tx.create(resultRef, rejectedResult);
              return rejectedResult;
            }

            const assignedAt = Timestamp.fromMillis(now);

            const nextEligibleAt = Timestamp.fromMillis(
              now + cooldownDays * DAY_MS
            );

            tx.create(assignmentRef, {
              assistanceId,
              familyId,
              areaId: family.areaId,
              assignedBy: uid,
              assignedAt,
              nextEligibleAt,
              status: "assigned",
              notes,
            });

            tx.set(eligibilityRef, {
              familyId,
              assistanceId,
              lastAssignmentId: assignmentRef.id,
              lastAssignedAt: assignedAt,
              nextEligibleAt,
            });

            const acceptedResult = {
              familyId,
              success: true,
              assignmentId: assignmentRef.id,
              message: "تم تخصيص المساعدة بنجاح",
            };

            tx.create(resultRef, acceptedResult);

            return acceptedResult;
          }
        );

        results.push(result);
      } catch (error) {
        results.push({
          familyId,
          success: false,
          message: getErrorMessage(error),
        });
      }
    }

    return {
      results,
      successfulCount: results.filter(
        (result) => result.success
      ).length,
      failedCount: results.filter(
        (result) => !result.success
      ).length,
    };
  }
);

// ========================================
// 3. Cancel Assistance Assignment
// ========================================

exports.cancelAssistanceAssignment = onCall(
  {
    region: REGION,
    timeoutSeconds: 60,
  },
  async (request) => {
    const uid = requireAuthentication(request);

    const {
      organizationId,
      assignmentId,
      reason = "",
    } = request.data || {};

    if (
      !validId(organizationId) ||
      !validId(assignmentId) ||
      typeof reason !== "string" ||
      reason.length > 500
    ) {
      throw new HttpsError(
        "invalid-argument",
        "بيانات إلغاء التخصيص غير صحيحة"
      );
    }

    const orgRef = orgReference(organizationId);

    const assignmentsRef = orgRef
      .collection("assistanceAssignments");

    const assignmentRef = assignmentsRef.doc(assignmentId);

    return db.runTransaction(async (tx) => {
      // Only supervisors may cancel assignments.
      await getAuthorizedUser(
        tx,
        uid,
        organizationId,
        true
      );

      const assignmentSnap = await tx.get(assignmentRef);

      if (!assignmentSnap.exists) {
        throw new HttpsError(
          "not-found",
          "سجل التخصيص غير موجود"
        );
      }

      const assignment = assignmentSnap.data();

      if (assignment.status === "cancelled") {
        return {
          success: true,
          assignmentId,
          message: "التخصيص ملغى مسبقًا",
        };
      }

      if (
        !["assigned", "delivered"].includes(
          assignment.status
        )
      ) {
        throw new HttpsError(
          "failed-precondition",
          "حالة التخصيص لا تسمح بالإلغاء"
        );
      }

      const familyId = assignment.familyId;
      const assistanceId = assignment.assistanceId;

      if (
        !validId(familyId) ||
        !validId(assistanceId)
      ) {
        throw new HttpsError(
          "failed-precondition",
          "بيانات التخصيص غير صحيحة"
        );
      }

      const eligibilityRef = orgRef
        .collection("assistanceEligibility")
        .doc(
          eligibilityDocumentId(familyId, assistanceId)
        );

      // Find up to two latest active assignments:
      // the current record and its predecessor.
      const recentQuery = assignmentsRef
        .where("familyId", "==", familyId)
        .where("assistanceId", "==", assistanceId)
        .where("status", "in", [
          "assigned",
          "delivered",
        ])
        .orderBy("assignedAt", "desc")
        .limit(2);

      const recentSnap = await tx.get(recentQuery);
      const eligibilitySnap = await tx.get(eligibilityRef);

      // All reads have completed.
      tx.update(assignmentRef, {
        status: "cancelled",
        cancelledBy: uid,
        cancelledAt: Timestamp.now(),
        cancellationReason: reason,
      });

      // Only alter eligibility when this is
      // the latest tracked assignment.
      if (
        eligibilitySnap.exists &&
        eligibilitySnap.data().lastAssignmentId ===
          assignmentId
      ) {
        const previous = recentSnap.docs.find(
          (doc) => doc.id !== assignmentId
        );

        if (previous) {
          const previousData = previous.data();

          tx.set(eligibilityRef, {
            familyId,
            assistanceId,
            lastAssignmentId: previous.id,
            lastAssignedAt: previousData.assignedAt,
            nextEligibleAt: previousData.nextEligibleAt,
          });
        } else {
          tx.delete(eligibilityRef);
        }
      }

      return {
        success: true,
        assignmentId,
        message: "تم إلغاء تخصيص المساعدة بنجاح",
      };
    });
  }
);
