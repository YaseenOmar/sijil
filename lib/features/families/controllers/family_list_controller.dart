
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

  // All authorized families loaded from Firestore.
  final List<FamilyModel> _allFamilies = [];

  // Families currently displayed after searching.
  final RxList<FamilyModel> families =
      <FamilyModel>[].obs;

  final RxBool isLoading = false.obs;

  final RxString errorMessage = ''.obs;

  final RxString searchQuery = ''.obs;

  // Total authorized families before search filtering.
  final RxInt totalFamilies = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchFamilies();
  }

  // ==========================================
  // Fetch Families
  // ==========================================

  Future<void> fetchFamilies() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Data source applies organization and area
      // permissions based on the active user.
      final result = await _dataSource.getFamilies();

      if (isClosed) return;

      _allFamilies
        ..clear()
        ..addAll(result);

      totalFamilies.value = _allFamilies.length;

      filterFamilies(searchQuery.value);
    } on FirebaseException catch (e) {
      if (isClosed) return;

      _clearFamilyData();

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
          'حدث خطأ أثناء تحميل بيانات الأسر: '
              '${e.message ?? e.code}';
      }
    } catch (e) {
      if (isClosed) return;

      _clearFamilyData();

      errorMessage.value =
      'تعذر تحميل بيانات الأسر: $e';
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  // ==========================================
  // Normalize Search Text
  // ==========================================

  String _normalizeSearch(String value) {
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const persianDigits = '۰۱۲۳۴۵۶۷۸۹';

    const englishDigits = '0123456789';

    var normalized = value.trim().toLowerCase();

    for (var i = 0; i < 10; i++) {
      normalized = normalized.replaceAll(
        arabicDigits[i],
        englishDigits[i],
      );

      normalized = normalized.replaceAll(
        persianDigits[i],
        englishDigits[i],
      );
    }

    return normalized.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
  }

  String _normalizePhone(String value) {
    return _normalizeSearch(value).replaceAll(
      RegExp(r'[\s\-()]'),
      '',
    );
  }

  // ==========================================
  // Search Families
  // ==========================================

  void filterFamilies(String query) {
    if (isClosed) return;

    searchQuery.value = query.trim();

    final normalizedQuery =
    _normalizeSearch(searchQuery.value);

    if (normalizedQuery.isEmpty) {
      families.assignAll(_allFamilies);
      return;
    }

    final normalizedPhoneQuery =
    _normalizePhone(searchQuery.value);

    final filtered = _allFamilies.where((family) {
      final name =
      _normalizeSearch(family.headName);

      final nationalId =
      _normalizeSearch(family.nationalId);

      final phone =
      _normalizePhone(family.phoneNumber);

      final matchesName =
      name.contains(normalizedQuery);

      final matchesNationalId =
      nationalId.contains(normalizedQuery);

      final matchesPhone =
          normalizedPhoneQuery.isNotEmpty &&
              phone.contains(normalizedPhoneQuery);

      return matchesName ||
          matchesNationalId ||
          matchesPhone;
    }).toList();

    families.assignAll(filtered);
  }

  // ==========================================
  // Reset
  // ==========================================

  void _clearFamilyData() {
    _allFamilies.clear();
    families.clear();
    totalFamilies.value = 0;
  }
}
