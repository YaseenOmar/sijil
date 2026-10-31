
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const crypto = require("node:crypto");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const { FieldValue } = admin.firestore;

const STATUS = Object.freeze({
  SOURCE_PENDING: "pending_source_approval",
  SOURCE_REJECTED: "rejected_by_source",
  TARGET_PENDING: "pending_target_approval",
  TARGET_REJECTED: "rejected_by_target",
  ACCEPTED: "accepted",
  IN_PROGRESS: "in_progress",
  COMPLETED: "completed",
});

function requiredString(value, field, maxLength = 500) {
  if (
    typeof value !== "string" ||
    !value.trim() ||
    value.trim().length > maxLength
  ) {
    throw new HttpsError(
      "invalid-argument",
      `قيمة غير صالحة للحقل: ${field}`
    );
  }
  return value.trim();
}

function getReferralId(data) {
  return requiredString(data?.referralId, "referralId", 128);
}

async function getCurrentUser(request) {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "يجب تسجيل الدخول أولاً"
    );
  }

  const uid = request.auth.uid;

  // Check verified email against current Auth state.
  const authUser = await admin.auth().getUser(uid);

  if (!authUser.emailVerified || authUser.disabled) {
    throw new HttpsError(
      "permission-denied",
      "الحساب غير مفعل أو البريد الإلكتروني غير موثق"
    );
  }

  const userDoc = await db.collection("users").doc(uid).get();

  if (!userDoc.exists) {
    throw new HttpsError(
      "permission-denied",
      "حساب الموظف غير موجود"
    );
  }

  const user = userDoc.data();

  if (
    user.status !== "active" ||
    !["field_worker", "supervisor"].includes(user.role) ||
    !user.organizationId
  ) {
    throw new HttpsError(
      "permission-denied",
      "لا تملك صلاحية تنفيذ العملية"
    );
  }

  return { ...user, uid };
}

function requireSupervisor(user) {
  if (user.role !== "supervisor") {
    throw new HttpsError(
      "permission-denied",
      "هذه العملية متاحة للمشرف فقط"
    );
  }
}

function assertStatus(referral, expected) {
  if (referral.status !== expected) {
    throw new HttpsError(
      "failed-precondition",
      "حالة الإحالة لا تسمح بهذه العملية"
    );
  }
}

function appendEvent(tx, referralRef, type, user, note = null) {
  const eventRef = referralRef.collection("events").doc();

  tx.create(eventRef, {
    type,
    actorId: user.uid,
    actorOrganizationId: user.organizationId,
    note,
    createdAt: FieldValue.serverTimestamp(),
  });
}

function receivedFamilyKey(sourceOrgId, familyId) {
  return crypto
    .createHash("sha256")
    .update(JSON.stringify([sourceOrgId, familyId]))
    .digest("hex");
}

// --------------------------------------------------
// 1. Create referral
// --------------------------------------------------

exports.createReferral = onCall(async (request) => {
  const user = await getCurrentUser(request);
  const data = request.data || {};

  const familyId = requiredString(
    data.familyId, "familyId", 128
  );
  const targetOrganizationId = requiredString(
    data.targetOrganizationId, "targetOrganizationId", 128
  );
  const targetServiceId = requiredString(
    data.targetServiceId, "targetServiceId", 128
  );
  const reason = requiredString(
    data.reason, "reason", 2000
  );

  if (data.sharingConfirmed !== true) {
    throw new HttpsError(
      "failed-precondition",
      "يجب تأكيد إبلاغ الأسرة بنطاق مشاركة البيانات"
    );
  }

  const sourceOrganizationId = user.organizationId;

  if (sourceOrganizationId === targetOrganizationId) {
    throw new HttpsError(
      "invalid-argument",
      "لا يمكن إحالة الأسرة إلى نفس المؤسسة"
    );
  }

  const sourceOrgRef = db
    .collection("organizations")
    .doc(sourceOrganizationId);

  const targetOrgRef = db
    .collection("organizations")
    .doc(targetOrganizationId);

  const familyRef = sourceOrgRef
    .collection("families")
    .doc(familyId);

  const serviceRef = targetOrgRef
    .collection("services")
    .doc(targetServiceId);

  const referralRef = db.collection("referrals").doc();

  await db.runTransaction(async (tx) => {
    // All transaction reads happen before writes.
    const [sourceOrgDoc, targetOrgDoc, familyDoc, serviceDoc] =
      await Promise.all([
        tx.get(sourceOrgRef),
        tx.get(targetOrgRef),
        tx.get(familyRef),
        tx.get(serviceRef),
      ]);

    if (
      !sourceOrgDoc.exists ||
      !targetOrgDoc.exists ||
      !familyDoc.exists ||
      !serviceDoc.exists
    ) {
      throw new HttpsError(
        "not-found",
        "المؤسسة أو الأسرة أو الخدمة غير موجودة"
      );
    }

    const family = familyDoc.data();
    const service = serviceDoc.data();


    if (
      typeof family.headName !== "string" ||
      !family.headName.trim() ||
      !Number.isInteger(family.membersCount) ||
      family.membersCount < 1 ||
      typeof family.phoneNumber !== "string" ||
      typeof family.address !== "string" ||
      typeof family.areaId !== "string" ||
      !family.areaId.trim()
    ) {
      throw new HttpsError(
        "failed-precondition",
        "بيانات الأسرة غير مكتملة أو غير صالحة للإحالة"
      );
    }



    if (
      user.role === "field_worker" &&
      (
        !user.areaId ||
        family.areaId !== user.areaId
      )
    ) {
      throw new HttpsError(
        "permission-denied",
        "الأسرة خارج منطقة عملك"
      );
    }

    if (
      service.isActive !== true ||
      service.acceptsReferrals !== true
    ) {
      throw new HttpsError(
        "failed-precondition",
        "الخدمة غير متاحة لاستقبال الإحالات"
      );
    }

    const sourceOrg = sourceOrgDoc.data();
    const targetOrg = targetOrgDoc.data();


    if (targetOrg.isActive === false) {
      throw new HttpsError(
        "failed-precondition",
        "المؤسسة المستقبلة غير متاحة للإحالات"
      );
    }


    const sourceName = requiredString(
      sourceOrg.name, "sourceOrganizationName"
    );
    const targetName = requiredString(
      targetOrg.name, "targetOrganizationName"
    );
    const serviceName = requiredString(
      service.name, "serviceName"
    );

    const status = user.role === "supervisor"
      ? STATUS.TARGET_PENDING
      : STATUS.SOURCE_PENDING;

    tx.create(referralRef, {
      number: referralRef.id.substring(0, 10),

      sourceOrganizationId,
      targetOrganizationId,

      sourceOrganizationName: sourceName,
      targetOrganizationName: targetName,

      sourceFamilyId: familyId,
      targetServiceId,
      serviceName,

      areaId: family.areaId,

      familySnapshot: {
        headName: family.headName,
        membersCount: family.membersCount,
        phoneNumber: family.phoneNumber,
        address: family.address,
      },

      reason,
      status,
      createdBy: user.uid,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),

      sourceApprovedBy:
        user.role === "supervisor" ? user.uid : null,
      sourceApprovedAt:
        user.role === "supervisor"
          ? FieldValue.serverTimestamp()
          : null,

      targetReviewedBy: null,
      targetReviewedAt: null,
      rejectionReason: null,

      receivedFamilyId: null,

      startedAt: null,
      completedAt: null,
      completedBy: null,
      result: null,
      resultNote: null,

      sharingConfirmed: true,
      sharingConfirmedAt: FieldValue.serverTimestamp(),
    });

    appendEvent(tx, referralRef, "created", user);

    if (user.role === "supervisor") {
      appendEvent(tx, referralRef, "source_approved", user);
    }
  });

  return {
    referralId: referralRef.id,
    success: true,
  };
});

// --------------------------------------------------
// 2. Approve outgoing referral
// --------------------------------------------------

exports.approveOutgoingReferral = onCall(async (request) => {
  const user = await getCurrentUser(request);
  requireSupervisor(user);

  const referralId = getReferralId(request.data);
  const ref = db.collection("referrals").doc(referralId);

  await db.runTransaction(async (tx) => {
    const doc = await tx.get(ref);

    if (!doc.exists) {
      throw new HttpsError("not-found", "الإحالة غير موجودة");
    }

    const referral = doc.data();

    if (referral.sourceOrganizationId !== user.organizationId) {
      throw new HttpsError("permission-denied", "غير مصرح");
    }

    assertStatus(referral, STATUS.SOURCE_PENDING);

    // Recheck that the receiving service is still available.
    const serviceRef = db
      .collection("organizations")
      .doc(referral.targetOrganizationId)
      .collection("services")
      .doc(referral.targetServiceId);


    const targetOrgRef = db
      .collection("organizations")
      .doc(referral.targetOrganizationId);

    const [targetOrgDoc, serviceDoc] = await Promise.all([
      tx.get(targetOrgRef),
      tx.get(serviceRef),
    ]);

    if (
      !targetOrgDoc.exists ||
      targetOrgDoc.data().isActive === false
    ) {
      throw new HttpsError(
        "failed-precondition",
        "المؤسسة المستقبلة لم تعد متاحة للإحالات"
      );
    }



    if (
      !serviceDoc.exists ||
      serviceDoc.data().isActive !== true ||
      serviceDoc.data().acceptsReferrals !== true
    ) {
      throw new HttpsError(
        "failed-precondition",
        "الخدمة لم تعد متاحة للإحالات"
      );
    }

    tx.update(ref, {
      status: STATUS.TARGET_PENDING,
      sourceApprovedBy: user.uid,
      sourceApprovedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    appendEvent(tx, ref, "source_approved", user);
  });

  return { success: true };
});

// --------------------------------------------------
// 3. Reject outgoing referral
// --------------------------------------------------

exports.rejectOutgoingReferral = onCall(async (request) => {
  const user = await getCurrentUser(request);
  requireSupervisor(user);

  const referralId = getReferralId(request.data);
  const reason = requiredString(
    request.data?.reason, "reason", 1000
  );

  const ref = db.collection("referrals").doc(referralId);

  await db.runTransaction(async (tx) => {
    const doc = await tx.get(ref);

    if (!doc.exists) {
      throw new HttpsError("not-found", "الإحالة غير موجودة");
    }

    const referral = doc.data();

    if (referral.sourceOrganizationId !== user.organizationId) {
      throw new HttpsError("permission-denied", "غير مصرح");
    }

    assertStatus(referral, STATUS.SOURCE_PENDING);

    tx.update(ref, {
      status: STATUS.SOURCE_REJECTED,
      rejectionReason: reason,
      updatedAt: FieldValue.serverTimestamp(),
    });

    appendEvent(tx, ref, "source_rejected", user, reason);
  });

  return { success: true };
});

// --------------------------------------------------
// 4. Accept incoming referral
// --------------------------------------------------

exports.acceptIncomingReferral = onCall(async (request) => {
  const user = await getCurrentUser(request);
  requireSupervisor(user);

  const referralId = getReferralId(request.data);
  const ref = db.collection("referrals").doc(referralId);

  const receivedFamilyId = await db.runTransaction(async (tx) => {
    const referralDoc = await tx.get(ref);

    if (!referralDoc.exists) {
      throw new HttpsError("not-found", "الإحالة غير موجودة");
    }

    const referral = referralDoc.data();

    if (referral.targetOrganizationId !== user.organizationId) {
      throw new HttpsError("permission-denied", "غير مصرح");
    }

    assertStatus(referral, STATUS.TARGET_PENDING);

    const id = receivedFamilyKey(
      referral.sourceOrganizationId,
      referral.sourceFamilyId
    );

    const familyRef = db
      .collection("organizations")
      .doc(user.organizationId)
      .collection("receivedFamilies")
      .doc(id);

    // Read before all writes.
    const existingFamily = await tx.get(familyRef);

    const family = referral.familySnapshot;

    if (!family || typeof family !== "object") {
      throw new HttpsError(
        "failed-precondition",
        "بيانات الأسرة غير مكتملة"
      );
    }

    if (!existingFamily.exists) {
      tx.create(familyRef, {
        sourceOrganizationId: referral.sourceOrganizationId,
        sourceFamilyId: referral.sourceFamilyId,
        targetOrganizationId: user.organizationId,

        headName: family.headName,
        membersCount: family.membersCount,
        phoneNumber: family.phoneNumber,
        address: family.address,
        areaId: referral.areaId,

        firstReferralId: referralId,
        receivedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    tx.update(ref, {
      status: STATUS.ACCEPTED,
      targetReviewedBy: user.uid,
      targetReviewedAt: FieldValue.serverTimestamp(),
      receivedFamilyId: id,
      updatedAt: FieldValue.serverTimestamp(),
    });

    appendEvent(tx, ref, "target_accepted", user);

    return id;
  });

  return {
    success: true,
    receivedFamilyId,
  };
});

// --------------------------------------------------
// 5. Reject incoming referral
// --------------------------------------------------

exports.rejectIncomingReferral = onCall(async (request) => {
  const user = await getCurrentUser(request);
  requireSupervisor(user);

  const referralId = getReferralId(request.data);
  const reason = requiredString(
    request.data?.reason, "reason", 1000
  );

  const ref = db.collection("referrals").doc(referralId);

  await db.runTransaction(async (tx) => {
    const doc = await tx.get(ref);

    if (!doc.exists) {
      throw new HttpsError("not-found", "الإحالة غير موجودة");
    }

    const referral = doc.data();

    if (referral.targetOrganizationId !== user.organizationId) {
      throw new HttpsError("permission-denied", "غير مصرح");
    }

    assertStatus(referral, STATUS.TARGET_PENDING);

    tx.update(ref, {
      status: STATUS.TARGET_REJECTED,
      targetReviewedBy: user.uid,
      targetReviewedAt: FieldValue.serverTimestamp(),
      rejectionReason: reason,
      updatedAt: FieldValue.serverTimestamp(),
    });

    appendEvent(tx, ref, "target_rejected", user, reason);
  });

  return { success: true };
});

/**
 * 6. Start referral service
 *
 * accepted -> in_progress
 * Only the receiving organization's supervisor.
 */
exports.startReferralService = onCall(async (request) => {
  const user = await getCurrentUser(request);
  requireSupervisor(user);

  const referralId = getReferralId(request.data);
  const referralRef = db.collection("referrals").doc(referralId);

  await db.runTransaction(async (tx) => {
    const snapshot = await tx.get(referralRef);

    if (!snapshot.exists) {
      throw new HttpsError(
        "not-found",
        "الإحالة غير موجودة"
      );
    }

    const referral = snapshot.data();

    // Only the receiving organization can start the service.
    if (referral.targetOrganizationId !== user.organizationId) {
      throw new HttpsError(
        "permission-denied",
        "لا يمكنك بدء خدمة تابعة لمؤسسة أخرى"
      );
    }

    assertStatus(referral, STATUS.ACCEPTED);

    if (!referral.receivedFamilyId) {
      throw new HttpsError(
        "failed-precondition",
        "لا يوجد سجل أسرة مستقبلة مرتبط بالإحالة"
      );
    }

    const familyRef = db
      .collection("organizations")
      .doc(user.organizationId)
      .collection("receivedFamilies")
      .doc(referral.receivedFamilyId);

    const familyDoc = await tx.get(familyRef);

    if (!familyDoc.exists) {
      throw new HttpsError(
        "failed-precondition",
        "سجل الأسرة المستقبلة غير موجود"
      );
    }

    tx.update(referralRef, {
      status: STATUS.IN_PROGRESS,
      startedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    appendEvent(
      tx,
      referralRef,
      "service_started",
      user
    );
  });

  return { success: true };
});

/**
 * 7. Complete referral service
 *
 * in_progress -> completed
 * Saves the service result and optional note.
 */
exports.completeReferralService = onCall(async (request) => {
  const user = await getCurrentUser(request);
  requireSupervisor(user);

  const referralId = getReferralId(request.data);

  const result = requiredString(
    request.data?.result,
    "result",
    2000
  );

  const rawNote = request.data?.resultNote;

  if (
    rawNote != null &&
    typeof rawNote !== "string"
  ) {
    throw new HttpsError(
      "invalid-argument",
      "ملاحظات الخدمة غير صالحة"
    );
  }

  const resultNote = rawNote == null
    ? null
    : rawNote.trim();

  if (resultNote && resultNote.length > 2000) {
    throw new HttpsError(
      "invalid-argument",
      "ملاحظات الخدمة طويلة جدًا"
    );
  }

  const referralRef = db.collection("referrals").doc(referralId);

  await db.runTransaction(async (tx) => {
    const snapshot = await tx.get(referralRef);

    if (!snapshot.exists) {
      throw new HttpsError(
        "not-found",
        "الإحالة غير موجودة"
      );
    }

    const referral = snapshot.data();

    if (referral.targetOrganizationId !== user.organizationId) {
      throw new HttpsError(
        "permission-denied",
        "لا يمكنك إكمال خدمة تابعة لمؤسسة أخرى"
      );
    }

    assertStatus(referral, STATUS.IN_PROGRESS);

    if (!referral.startedAt || !referral.receivedFamilyId) {
      throw new HttpsError(
        "failed-precondition",
        "لم تبدأ الخدمة أو لا يوجد سجل أسرة مرتبط"
      );
    }

    tx.update(referralRef, {
      status: STATUS.COMPLETED,
      result,
      resultNote: resultNote || null,
      completedBy: user.uid,
      completedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    appendEvent(
      tx,
      referralRef,
      "service_completed",
      user,
      "تم إكمال الخدمة"
    );
  });

  return { success: true };
});
