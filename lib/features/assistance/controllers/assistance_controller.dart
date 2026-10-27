import 'package:get/get.dart';
import '../data/models/assistance_model.dart';

class AssistanceController extends GetxController {
  var selectedTypeFilter = 'جميع الأنواع'.obs;
  final List<String> assistanceTypes = [
    'جميع الأنواع',
    'طرد غذائي',
    'مستلزمات نظافة',
    'كسوة شتاء',
  ];

  var allAssistances = <AssistanceRecord>[
    AssistanceRecord(
      id: '1',
      beneficiaryId: '408532936',
      beneficiaryName: 'يوسف ناصر حمد',
      assistanceType: 'طرد غذائي',
      quantity: 'طرد واحد',
      deliveryDate: DateTime(2026, 10, 21),
      officerName: 'أحمد سالم',
      area: 'حي النور',
      status: 'pending',
      proofType: 'signature',
    ),
    AssistanceRecord(
      id: '2',
      beneficiaryId: '408532937',
      beneficiaryName: 'هناء علي منصور',
      assistanceType: 'مستلزمات نظافة',
      quantity: 'حقيبة واحدة',
      deliveryDate: DateTime(2026, 10, 20),
      officerName: 'أحمد سالم',
      area: 'حي النور',
      status: 'synced',
      proofType: 'photo',
    ),
    AssistanceRecord(
      id: '3',
      beneficiaryId: '408532936',
      beneficiaryName: 'محمود حسن العلي',
      assistanceType: 'طرد غذائي',
      quantity: 'طرد واحد',
      deliveryDate: DateTime(2026, 10, 8),
      officerName: 'أحمد سالم',
      area: 'حي النور',
      status: 'synced',
      proofType: 'signature',
    ),
  ].obs;

  int get monthlyDeliveredCount => allAssistances.length;

  int get benefitedFamiliesCount =>
      allAssistances.map((e) => e.beneficiaryId).toSet().length;

  List<AssistanceRecord> get filteredAssistances {
    if (selectedTypeFilter.value == 'جميع الأنواع') {
      return allAssistances;
    }
    return allAssistances
        .where((item) => item.assistanceType == selectedTypeFilter.value)
        .toList();
  }

  List<AssistanceRecord> getHistoryForBeneficiary(String beneficiaryId) {
    return allAssistances
        .where((e) => e.beneficiaryId == beneficiaryId)
        .toList();
  }

  AssistanceRecord? checkDuplicate(
    String beneficiaryId,
    String assistanceType,
    DateTime date,
  ) {
    try {
      return allAssistances.firstWhere((record) {
        if (record.beneficiaryId == beneficiaryId &&
            record.assistanceType == assistanceType) {
          final differenceInDays = date
              .difference(record.deliveryDate)
              .inDays
              .abs();
          return differenceInDays < 30;
        }
        return false;
      });
    } catch (_) {
      return null;
    }
  }

  bool addAssistance(AssistanceRecord newRecord) {
    allAssistances.insert(0, newRecord);
    update();
    return true;
  }
}
