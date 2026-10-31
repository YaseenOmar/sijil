
import '../data/datasources/service_remote_data_source.dart';
import '../data/models/service_model.dart';

class ServiceRepository {
  final ServiceRemoteDataSource _remoteDataSource;

  ServiceRepository({
    ServiceRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource =
      remoteDataSource ?? ServiceRemoteDataSource();

  // Add a new service.
  Future<void> addService(ServiceModel service) {
    return _remoteDataSource.addService(service);
  }

  // Get all services in the organization.
  Future<List<ServiceModel>> getServices({
    bool activeOnly = false,
  }) {
    return _remoteDataSource.getServices(
      activeOnly: activeOnly,
    );
  }

  // Get a specific service by ID.
  Future<ServiceModel?> getServiceById(
      String serviceId,
      ) {
    return _remoteDataSource.getServiceById(
      serviceId,
    );
  }

  // Update service information.
  Future<void> updateService(
      ServiceModel service,
      ) {
    return _remoteDataSource.updateService(service);
  }

  // Activate or deactivate a service.
  Future<void> updateServiceStatus(
      String serviceId,
      bool isActive,
      ) {
    return _remoteDataSource.updateServiceStatus(
      serviceId,
      isActive,
    );
  }
}
