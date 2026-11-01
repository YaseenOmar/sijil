
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

function eligibilityDocumentId(familyId, serviceId) {
  return crypto
    .createHash("sha256")
    .update(JSON.stringify([familyId, serviceId]))
    .digest("hex");
}

// Validate user account and linked employee record.
// Must be called inside a transaction before writes.
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
  { region: REGION, timeoutSeconds: 120 },
  async (request) => {
    const uid = requireAuthentication(request);
    const {
      organizationId,
      serviceId,
      familyIds,
      requestId,
      notes = "",
    } = request.data || {};

    if (
      !validId(organizationId) ||
      !validId(serviceId) ||
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
    const serviceRef = orgRef
      .collection("services")
      .doc(serviceId);

    const requestRef = orgRef
      .collection("assistanceRequests")
      .doc(requestId);

    const sortedFamilyIds = [...familyIds].sort();

    // Reserve the request identity.
    // A retry must have identical parameters.
    await db.runTransaction(async (tx) => {
      await getAuthorizedUser(tx, uid, organizationId);

      const savedRequest = await tx.get(requestRef);

      if (savedRequest.exists) {
        const previous = savedRequest.data();

        if (
          previous.uid !== uid ||
          previous.serviceId !== serviceId ||
          previous.notes !== notes ||
          JSON.stringify(previous.familyIds) !==
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
        serviceId,
        familyIds: sortedFamilyIds,
        notes,
        createdAt: Timestamp.now(),
      });
    });

    const results = [];

    // Each family's decision and writes are atomic.
    for (const familyId of sortedFamilyIds) {
      const familyRef = orgRef
        .collection("families")
        .doc(familyId);

      const assignmentRef = orgRef
        .collection("assistanceAssignments")
        .doc(`${requestId}_${familyId}`);

      const eligibilityRef = orgRef
        .collection("assistanceEligibility")
        .doc(eligibilityDocumentId(familyId, serviceId));

      const resultRef = requestRef
        .collection("results")
        .doc(familyId);

      // Unexpected errors must not become final rejections.
      // Retry an uncertain request using the same requestId.
      const result = await db.runTransaction(async (tx) => {
        const actor = await getAuthorizedUser(
          tx,
          uid,
          organizationId
        );

        const [
          resultSnap,
          serviceSnap,
          familySnap,
          eligibilitySnap,
          assignmentSnap,
        ] = await Promise.all([
          tx.get(resultRef),
          tx.get(serviceRef),
          tx.get(familyRef),
          tx.get(eligibilityRef),
          tx.get(assignmentRef),
        ]);

        if (resultSnap.exists) {
          return resultSnap.data();
        }

        let rejection = null;
        let rejectionCode = null;
        let cooldownDetails = {};

        const service = serviceSnap.exists
          ? serviceSnap.data()
          : null;

        const family = familySnap.exists
          ? familySnap.data()
          : null;

        if (!service) {
          rejection = "الخدمة غير موجودة";
          rejectionCode = "service_not_found";
        } else if (service.isActive !== true) {
          rejection = "الخدمة غير فعالة";
          rejectionCode = "service_inactive";
        } else if (
          service.organizationId &&
          service.organizationId !== organizationId
        ) {
          rejection = "الخدمة لا تتبع المؤسسة";
          rejectionCode = "invalid_service_organization";
        }

        const hasCooldown =
          service?.hasCooldown === true;

        const cooldownDays = hasCooldown
          ? service.cooldownDays
          : 0;

        if (
          !rejection &&
          hasCooldown &&
          (
            !Number.isInteger(cooldownDays) ||
            cooldownDays < 0 ||
            cooldownDays > 36500
          )
        ) {
          rejection = "فترة منع التكرار غير صحيحة";
          rejectionCode = "invalid_cooldown";
        }

        if (!rejection && !family) {
          rejection = "الأسرة غير موجودة";
          rejectionCode = "family_not_found";
        } else if (
          !rejection &&
          !canAccessFamily(actor, family)
        ) {
          rejection = "الأسرة خارج نطاق صلاحياتك";
          rejectionCode = "permission_denied";
        }

        if (!rejection && assignmentSnap.exists) {
          throw new HttpsError(
            "failed-precondition",
            "يوجد تخصيص بنفس معرف الطلب دون نتيجة محفوظة؛ راجع السجلات"
          );
        }

        const nowMs = Date.now();

        if (
          !rejection &&
          hasCooldown &&
          eligibilitySnap.exists
        ) {
          const previous = eligibilitySnap.data();

          if (
            !(previous.nextEligibleAt instanceof Timestamp)
          ) {
            rejection = "بيانات أهلية الأسرة غير صحيحة";
            rejectionCode = "invalid_eligibility";
          } else if (
            previous.nextEligibleAt.toMillis() > nowMs
          ) {
            rejection =
              "الأسرة ضمن فترة منع تكرار هذه الخدمة";
            rejectionCode = "cooldown_active";

            cooldownDetails = {
              lastAssignmentId:
                previous.lastAssignmentId || null,

              lastAssignedAt:
                previous.lastAssignedAt instanceof Timestamp
                  ? previous.lastAssignedAt
                      .toDate()
                      .toISOString()
                  : null,

              nextEligibleAt:
                previous.nextEligibleAt
                  .toDate()
                  .toISOString(),
            };
          }
        }

        if (rejection) {
          const rejectedResult = {
            familyId,
            success: false,
            code: rejectionCode,
            message: rejection,
            ...cooldownDetails,
          };

          tx.create(resultRef, rejectedResult);

          return rejectedResult;
        }

        const assignedAt =
          Timestamp.fromMillis(nowMs);

        const nextEligibleAt =
          hasCooldown && cooldownDays > 0
            ? Timestamp.fromMillis(
                nowMs + cooldownDays * DAY_MS
              )
            : null;

        tx.create(assignmentRef, {
          organizationId,
          serviceId,
          familyId,
          areaId: family.areaId,
          assignedBy: uid,
          assignedAt,
          nextEligibleAt,
          status: "assigned",
          notes,
        });

        if (nextEligibleAt) {
          tx.set(eligibilityRef, {
            familyId,
            serviceId,
            lastAssignmentId: assignmentRef.id,
            lastAssignedAt: assignedAt,
            nextEligibleAt,
          });
        }

        const acceptedResult = {
          familyId,
          success: true,
          assignmentId: assignmentRef.id,
          message: "تم تخصيص المساعدة بنجاح",
        };

        tx.create(resultRef, acceptedResult);

        return acceptedResult;
      });

      results.push(result);
    }

    return {
      results,
      successfulCount: results.filter(
        (r) => r.success === true
      ).length,
      failedCount: results.filter(
        (r) => r.success === false
      ).length,
    };
  }
);

// ========================================
// 3. Cancel Assistance Assignment
// ========================================

exports.cancelAssistanceAssignment = onCall(
  { region: REGION, timeoutSeconds: 60 },
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

    const assignmentRef =
      assignmentsRef.doc(assignmentId);

    return db.runTransaction(async (tx) => {
      await getAuthorizedUser(
        tx,
        uid,
        organizationId,
        true
      );

      const assignmentSnap =
        await tx.get(assignmentRef);

      if (!assignmentSnap.exists) {
        throw new HttpsError(
          "not-found",
          "سجل التخصيص غير موجود"
        );
      }

      const assignment = assignmentSnap.data();

      if (assignment.status === "canceled") {
        return {
          success: true,
          assignmentId,
          message: "التخصيص ملغى مسبقًا",
        };
      }

      // Delivery is a separate real-world event.
      if (assignment.status !== "assigned") {
        throw new HttpsError(
          "failed-precondition",
          "يمكن إلغاء التخصيصات غير المسلّمة فقط"
        );
      }

      const { familyId, serviceId } = assignment;

      if (
        !validId(familyId) ||
        !validId(serviceId)
      ) {
        throw new HttpsError(
          "failed-precondition",
          "بيانات التخصيص غير صحيحة"
        );
      }

      const eligibilityRef = orgRef
        .collection("assistanceEligibility")
        .doc(
          eligibilityDocumentId(familyId, serviceId)
        );

      // Find the latest active assignments.
      const recentQuery = assignmentsRef
        .where("familyId", "==", familyId)
        .where("serviceId", "==", serviceId)
        .where("status", "in", [
          "assigned",
          "delivered",
        ])
        .orderBy("assignedAt", "desc")
        .limit(2);

      const recentSnap =
        await tx.get(recentQuery);

      const eligibilitySnap =
        await tx.get(eligibilityRef);

      tx.update(assignmentRef, {
        status: "canceled",
        canceledBy: uid,
        canceledAt: Timestamp.now(),
        cancellationReason: reason,
      });

      if (
        eligibilitySnap.exists &&
        eligibilitySnap.data().lastAssignmentId ===
          assignmentId
      ) {
        const previous = recentSnap.docs.find(
          (doc) => doc.id !== assignmentId
        );

        if (
          previous &&
          previous.data().nextEligibleAt instanceof Timestamp
        ) {
          tx.set(eligibilityRef, {
            familyId,
            serviceId,
            lastAssignmentId: previous.id,
            lastAssignedAt:
              previous.data().assignedAt,
            nextEligibleAt:
              previous.data().nextEligibleAt,
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

// ========================================
// Referrals
// ========================================

Object.assign(
  exports,
  require("./referrals/referral_functions")
);
