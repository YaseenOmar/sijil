import 'package:sijil/features/referrals/models/referral_model.dart';

// Family used by the create referral form
class DemoFamily {
  final String name;
  final int membersCount;
  final String phone;
  final String area;

  const DemoFamily({
    required this.name,
    required this.membersCount,
    required this.phone,
    required this.area,
  });
}

// Temporary data until referrals and families come from Firestore.
// Replace it with the real services before production use.
class ReferralDemoData {
  ReferralDemoData._();

  static const String currentOrg = 'جمعية الأمان';
  static const String fieldWorkerLabel = 'أحمد سالم · العامل الميداني';
  static const String supervisorLabel = 'نورا إبراهيم · مشرفة جمعية الأمان';
  static const String sender = 'أحمد سالم · جمعية الأمان';

  // Line under the title of the supervisor referrals page
  static const String supervisorHeaderLabel = 'نورا إبراهيم · جمعية الأمان';

  // TODO: replace it with the real last sync time of the sync service
  static final DateTime lastSyncAt = DateTime(2026, 10, 21, 8, 55);

  static const List<DemoFamily> families = [
    DemoFamily(
      name: 'سامي يوسف الخطيب',
      membersCount: 5,
      phone: '0599123456',
      area: 'حي النور',
    ),
    DemoFamily(
      name: 'محمود حسن العلي',
      membersCount: 6,
      phone: '0597654321',
      area: 'حي النور',
    ),
    DemoFamily(
      name: 'هناء علي منصور',
      membersCount: 4,
      phone: '0568123456',
      area: 'حي النور',
    ),
  ];

  static List<ReferralModel> get outgoing => [
    ReferralModel(
      id: 'ref_001',
      number: '0044',
      familyName: 'سامي يوسف الخطيب',
      membersCount: 5,
      fromOrg: currentOrg,
      toOrg: 'مركز الشفاء',
      service: 'تأهيل حركي',
      reason: 'تحتاج الأسرة إلى تقييم تأهيلي لأحد أفرادها وتحديد برنامج متابعة مناسب.',
      area: 'حي النور',
      contactPhone: '0599123456',
      status: ReferralStatus.pendingSend,
      createdAt: DateTime(2026, 10, 21, 8, 10),
    ),
    ReferralModel(
      id: 'ref_002',
      number: '0042',
      familyName: 'محمود حسن العلي',
      membersCount: 6,
      fromOrg: currentOrg,
      toOrg: 'مركز الشفاء',
      service: 'رعاية صحية',
      reason: 'تقييم حالة صحية مزمنة وترتيب متابعة علاجية.',
      area: 'حي النور',
      contactPhone: '0597654321',
      status: ReferralStatus.completed,
      createdAt: DateTime(2026, 10, 17, 10, 30),
      sentAt: DateTime(2026, 10, 17, 10, 30),
      sentBy: sender,
      receivedAt: DateTime(2026, 10, 18, 9, 0),
      receivedBy: 'مركز الشفاء · تأكيد الاستلام',
      reviewedAt: DateTime(2026, 10, 19, 11, 15),
      reviewedBy: 'مشرف الخدمات · مركز الشفاء',
      completedAt: DateTime(2026, 10, 20, 14, 0),
      completedBy: 'فريق الرعاية · مركز الشفاء',
      notifiedAt: DateTime(2026, 10, 20, 14, 5),
      result: 'أجري التقييم ووُضعت خطة متابعة، وسُلّمت توصية للمراجعة الدورية إلى الأسرة.',
      resultNote: 'أغلقت بواسطة مشرف مركز الشفاء في ٢٠ أكتوبر ٢٠٢٦.',
    ),
    ReferralModel(
      id: 'ref_003',
      number: '0043',
      familyName: 'هناء علي منصور',
      membersCount: 4,
      fromOrg: currentOrg,
      toOrg: 'مؤسسة السند',
      service: 'دعم سكني',
      reason: 'تحتاج الأسرة إلى دعم سكني عاجل بعد تضرر مسكنها.',
      area: 'حي النور',
      contactPhone: '0568123456',
      status: ReferralStatus.underReview,
      createdAt: DateTime(2026, 10, 19, 9, 0),
      sentAt: DateTime(2026, 10, 19, 9, 0),
      sentBy: sender,
      receivedAt: DateTime(2026, 10, 20, 10, 0),
      receivedBy: 'مؤسسة السند · تأكيد الاستلام',
      reviewedAt: DateTime(2026, 10, 20, 12, 0),
      reviewedBy: 'مشرف الخدمات · مؤسسة السند',
    ),
  ];

  static List<ReferralModel> get incoming => [
    ReferralModel(
      id: 'ref_101',
      number: '0101',
      familyName: 'أمينة خالد صالح',
      membersCount: 4,
      fromOrg: 'جمعية العون',
      toOrg: currentOrg,
      service: 'مساعدات غذائية',
      reason: 'تحتاج الأسرة إلى دعم غذائي عاجل بعد توقف مصدر دخلها. يُرجى تقييم الاحتياج وتحديد موعد للخدمة.',
      area: 'حي النور',
      contactPhone: '0955123467',
      status: ReferralStatus.received,
      createdAt: DateTime(2026, 10, 21, 8, 40),
      receivedAt: DateTime(2026, 10, 21, 8, 40),
    ),
    ReferralModel(
      id: 'ref_102',
      number: '0102',
      familyName: 'خالد محمد الشريف',
      membersCount: 6,
      fromOrg: 'جمعية العون',
      toOrg: currentOrg,
      service: 'رعاية صحية',
      reason: 'تحتاج الأسرة إلى متابعة صحية لأحد أفرادها وترتيب موعد تقييم.',
      area: 'حي النور',
      contactPhone: '0597001122',
      status: ReferralStatus.received,
      createdAt: DateTime(2026, 10, 20, 14, 15),
      receivedAt: DateTime(2026, 10, 20, 14, 15),
    ),
    ReferralModel(
      id: 'ref_103',
      number: '0103',
      familyName: 'ليلى أحمد حمدان',
      membersCount: 3,
      fromOrg: 'مركز الشفاء',
      toOrg: currentOrg,
      service: 'مساعدات غذائية',
      reason: 'تحتاج الأسرة إلى سلة غذائية عاجلة بعد فقدان المعيل.',
      area: 'حي السلام',
      contactPhone: '0568223344',
      status: ReferralStatus.received,
      createdAt: DateTime(2026, 10, 19, 11, 0),
      receivedAt: DateTime(2026, 10, 19, 11, 0),
    ),
    ReferralModel(
      id: 'ref_104',
      number: '0104',
      familyName: 'يوسف علي النجار',
      membersCount: 7,
      fromOrg: 'مؤسسة السند',
      toOrg: currentOrg,
      service: 'دعم سكني',
      reason: 'تحتاج الأسرة إلى دعم في ترميم المسكن قبل بدء الشتاء.',
      area: 'حي النور',
      contactPhone: '0599334455',
      status: ReferralStatus.received,
      createdAt: DateTime(2026, 10, 18, 9, 30),
      receivedAt: DateTime(2026, 10, 18, 9, 30),
    ),
    ReferralModel(
      id: 'ref_105',
      number: '0105',
      familyName: 'رنا سمير الحلو',
      membersCount: 5,
      fromOrg: 'جمعية العون',
      toOrg: currentOrg,
      service: 'تأهيل حركي',
      reason: 'تحتاج الأسرة إلى تقييم حركي لأحد الأطفال وتحديد برنامج متابعة.',
      area: 'حي السلام',
      contactPhone: '0597445566',
      status: ReferralStatus.received,
      createdAt: DateTime(2026, 10, 17, 13, 45),
      receivedAt: DateTime(2026, 10, 17, 13, 45),
    ),
  ];
}
