import 'package:get/get.dart';
import '../data/datasources/family_remote_datasource.dart';
import '../data/models/family_model.dart';

class FamilyListController extends GetxController {
  final FamilyRemoteDataSource _dataSource;

  FamilyListController({FamilyRemoteDataSource? dataSource})
    : _dataSource = dataSource ?? FamilyRemoteDataSource();

  final List<FamilyModel> _allFamilies = [];

  final RxList<FamilyModel> families = <FamilyModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchFamilies();
  }

  Future<void> fetchFamilies() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _dataSource.getFamilies();
      _allFamilies.clear();
      _allFamilies.addAll(result);

      filterFamilies(searchQuery.value);
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء تحميل البيانات: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  void filterFamilies(String query) {
    searchQuery.value = query.trim();

    if (searchQuery.value.isEmpty) {
      families.assignAll(_allFamilies);
      return;
    }

    final lowerQuery = searchQuery.value.toLowerCase();

    final filtered = _allFamilies.where((family) {
      final matchesName = family.headName.toLowerCase().contains(lowerQuery);
      final matchesNationalId = family.nationalId.contains(lowerQuery);
      final matchesPhone = family.phoneNumber.contains(lowerQuery);

      return matchesName || matchesNationalId || matchesPhone;
    }).toList();

    families.assignAll(filtered);
  }
}
