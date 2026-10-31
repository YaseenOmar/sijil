
import 'package:get/get.dart';

import '../data/models/service_model.dart';
import '../repositories/service_repository.dart';

class ServiceCatalogController extends GetxController {
  final ServiceRepository _repository;

  ServiceCatalogController({
    ServiceRepository? repository,
  }) : _repository = repository ?? ServiceRepository();

  final services = <ServiceModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  final updatingServiceIds = <String>[].obs;

  int get totalServices => services.length;

  int get activeServices =>
      services.where((service) => service.isActive).length;

  int get inactiveServices =>
      services.where((service) => !service.isActive).length;

  @override
  void onInit() {
    super.onInit();
    loadServices();
  }

  Future<void> loadServices() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _repository.getServices();

      result.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      services.assignAll(result);
    } catch (e) {
      errorMessage.value =
          _errorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changeServiceStatus(
      ServiceModel service,
      bool newStatus,
      ) async {
    if (updatingServiceIds.contains(service.id)) return;

    updatingServiceIds.add(service.id);

    try {
      await _repository.updateServiceStatus(
        service.id,
        newStatus,
      );

      final index = services.indexWhere(
            (item) => item.id == service.id,
      );

      if (index != -1) {
        services[index] = service.copyWith(
          isActive: newStatus,
        );
      }

      Get.snackbar(
        'تم تحديث الخدمة',
        newStatus
            ? 'تم تفعيل الخدمة بنجاح'
            : 'تم إيقاف الخدمة بنجاح',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'تعذر تحديث الخدمة',
        _errorMessage(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      updatingServiceIds.remove(service.id);
    }
  }

  String _errorMessage(Object error) {
    final message = error.toString();

    if (message.contains('permission-denied')) {
      return 'ليس لديك صلاحية لتنفيذ هذه العملية';
    }

    if (message.contains('unavailable')) {
      return 'تعذر الاتصال بالخادم';
    }

    return message.replaceFirst('Exception: ', '');
  }
}
