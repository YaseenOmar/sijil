
import '../repositories/referral_repository.dart';

class ReferralService {
  final ReferralRepository _repository;

  ReferralService({
    ReferralRepository? repository,
  }) : _repository = repository ?? ReferralRepository();

  ReferralRepository get repository => _repository;

  Future<String> createReferral({
    required String familyId,
    required String targetOrganizationId,
    required String targetServiceId,
    required String reason,
    required bool sharingConfirmed,
  }) async {
    if (familyId.trim().isEmpty ||
        targetOrganizationId.trim().isEmpty ||
        targetServiceId.trim().isEmpty) {
      throw Exception('يرجى تعبئة جميع الحقول المطلوبة');
    }

    if (reason.trim().isEmpty) {
      throw Exception('يرجى إدخال سبب الإحالة');
    }

    if (!sharingConfirmed) {
      throw Exception(
        'يرجى تأكيد توضيح غرض الإحالة للأسرة',
      );
    }

    return _repository.createReferral(
      familyId: familyId,
      targetOrganizationId: targetOrganizationId,
      targetServiceId: targetServiceId,
      reason: reason.trim(),
      sharingConfirmed: sharingConfirmed,
    );
  }

  Future<void> approveOutgoing(String referralId) {
    return _repository.approveOutgoing(referralId);
  }

  Future<void> rejectOutgoing({
    required String referralId,
    required String reason,
  }) {
    if (reason.trim().isEmpty) {
      throw Exception('يرجى إدخال سبب الرفض');
    }

    return _repository.rejectOutgoing(
      referralId: referralId,
      reason: reason.trim(),
    );
  }

  Future<void> acceptIncoming(String referralId) {
    return _repository.acceptIncoming(referralId);
  }

  Future<void> rejectIncoming({
    required String referralId,
    required String reason,
  }) {
    if (reason.trim().isEmpty) {
      throw Exception('يرجى إدخال سبب الرفض');
    }

    return _repository.rejectIncoming(
      referralId: referralId,
      reason: reason.trim(),
    );
  }

  Future<void> startService(String referralId) {
    return _repository.startService(referralId);
  }

  Future<void> completeService({
    required String referralId,
    required String result,
    String? resultNote,
  }) {
    if (result.trim().isEmpty) {
      throw Exception('يرجى إدخال نتيجة الخدمة');
    }

    return _repository.completeService(
      referralId: referralId,
      result: result.trim(),
      resultNote: resultNote?.trim(),
    );
  }
}
