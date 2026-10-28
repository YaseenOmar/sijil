
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../data/datasources/family_remote_datasource.dart';
import '../data/models/family_model.dart';

class FamilyListController extends GetxController {
  final FamilyRemoteDataSource _dataSource;

  FamilyListController({
    FamilyRemoteDataSource? dataSource,
  }) : _dataSource =
      dataSource ?? FamilyRemoteDataSource();

  final List<FamilyModel> _allFamilies = [];

  final RxList<FamilyModel> families =
      <FamilyModel>[].obs;

  final RxBool isLoading = false.obs;

  final RxString errorMessage = ''.obs;

  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchFamilies();
  }

  // Load families according to the signed-in user's role.
  Future<void> fetchFamilies() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _dataSource.getFamilies();

      _allFamilies
        ..clear()
        ..addAll(result);

      filterFamilies(searchQuery.value);
    } on FirebaseException catch (e) {
      _allFamilies.clear();
      families.clear();

      switch (e.code) {
        case 'permission-denied':
          errorMessage.value =
          'ليس لديك صلاحية لعرض هذه الأسر';
          break;

        case 'unavailable':
          errorMessage.value =
          'تعذر الاتصال بالخادم، يرجى المحاولة لاحقاً';
          break;

        case 'failed-precondition':
          errorMessage.value =
          'تحتاج قاعدة البيانات إلى إعداد فهرس للاستعلام';
          break;

        default:
          errorMessage.value =
          'حدث خطأ أثناء تحميل بيانات الأسر: ${e.message ?? e.code}';
      }
    } catch (e) {
      _allFamilies.clear();
      families.clear();

      errorMessage.value =
      'تعذر تحميل بيانات الأسر: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Filter the already loaded and authorized families.
  void filterFamilies(String query) {
    searchQuery.value = query.trim();

    if (searchQuery.value.isEmpty) {
      families.assignAll(_allFamilies);
      return;
    }

    final lowerQuery = searchQuery.value.toLowerCase();

    final filtered = _allFamilies.where((family) {
      final matchesName = family.headName
          .toLowerCase()
          .contains(lowerQuery);

      final matchesNationalId =
      family.nationalId.contains(lowerQuery);

      final matchesPhone =
      family.phoneNumber.contains(lowerQuery);

      return matchesName ||
          matchesNationalId ||
          matchesPhone;
    }).toList();

    families.assignAll(filtered);
  }
}
