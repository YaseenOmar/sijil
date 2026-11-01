
import 'package:sijil/features/service_catalog/data/models/service_model.dart';

import '../models/assistance_assignment_model.dart';
import '../models/assistance_eligibility_model.dart';
import 'assistance_remote_data_source.dart';

class AssistanceRepository {
  final AssistanceRemoteDataSource remoteDataSource;

  AssistanceRepository({
    required this.remoteDataSource,
  });

  // ==========================================
  // Services
  // ==========================================

  /// Returns active services available for assignment.
  Future<List<ServiceModel>> getActiveServices(
      String organizationId,
      ) {
    return remoteDataSource.getActiveServices(
      organizationId,
    );
  }

  /// Returns all services, including inactive ones.
  Future<List<ServiceModel>> getAllServices(
      String organizationId,
      ) {
    return remoteDataSource.getAllServices(
      organizationId,
    );
  }

  /// Returns a specific service by its ID.
  Future<ServiceModel?> getServiceById({
    required String organizationId,
    required String serviceId,
  }) {
    return remoteDataSource.getServiceById(
      organizationId: organizationId,
      serviceId: serviceId,
    );
  }

  // ==========================================
  // Assistance Assignments
  // ==========================================

  /// Returns the assistance assignments displayed
  /// on the dashboard.
  Future<List<AssistanceAssignmentModel>>
  getDashboardAssignments({
    required String organizationId,
  }) {
    return remoteDataSource.getDashboardAssignments(
      organizationId: organizationId,
    );
  }

  /// Returns assistance assignment history
  /// for a specific family.
  Future<List<AssistanceAssignmentModel>>
  getFamilyAssignments({
    required String organizationId,
    required String familyId,
  }) {
    return remoteDataSource.getFamilyAssignments(
      organizationId: organizationId,
      familyId: familyId,
    );
  }

  // ==========================================
  // Assistance Eligibility
  // ==========================================

  /// Returns the eligibility information for
  /// one family and one service.
  Future<AssistanceEligibilityModel?> getEligibility({
    required String organizationId,
    required String familyId,
    required String serviceId,
  }) {
    return remoteDataSource.getEligibility(
      organizationId: organizationId,
      familyId: familyId,
      serviceId: serviceId,
    );
  }

  // ==========================================
  // Assign Assistance
  // ==========================================

  /// Assigns one service to one or more families
  /// using Firestore transactions.
  ///
  /// The data source validates:
  /// - User and organization.
  /// - Family access permissions.
  /// - Service availability.
  /// - Cooldown restrictions.
  /// - Request identity.
  ///
  /// Firestore Security Rules must independently
  /// enforce authorization and data integrity.
  Future<Map<String, dynamic>> assignAssistance({
    required String organizationId,
    required String serviceId,
    required List<String> familyIds,
    required String requestId,
    String notes = '',
  }) {
    return remoteDataSource.assignAssistance(
      organizationId: organizationId,
      serviceId: serviceId,
      familyIds: familyIds,
      requestId: requestId,
      notes: notes,
    );
  }
}
