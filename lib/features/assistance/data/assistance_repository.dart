
import '../models/assistance_model.dart';
import '../models/assistance_assignment_model.dart';
import '../models/assistance_eligibility_model.dart';
import 'assistance_remote_data_source.dart';

class AssistanceRepository {
  final AssistanceRemoteDataSource remoteDataSource;

  AssistanceRepository({
    required this.remoteDataSource,
  });

  Future<List<AssistanceAssignmentModel>>
  getDashboardAssignments({
    required String organizationId,
  }) {
    return remoteDataSource.getDashboardAssignments(
      organizationId: organizationId,
    );
  }

  Future<List<AssistanceModel>> getActiveAssistances(
      String organizationId,
      ) {
    return remoteDataSource.getActiveAssistances(
      organizationId,
    );
  }

  Future<List<AssistanceModel>> getAllAssistances(
      String organizationId,
      ) {
    return remoteDataSource.getAllAssistances(
      organizationId,
    );
  }

  Future<AssistanceModel?> getAssistanceById({
    required String organizationId,
    required String assistanceId,
  }) {
    return remoteDataSource.getAssistanceById(
      organizationId: organizationId,
      assistanceId: assistanceId,
    );
  }

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

  Future<AssistanceEligibilityModel?> getEligibility({
    required String organizationId,
    required String eligibilityId,
  }) {
    return remoteDataSource.getEligibility(
      organizationId: organizationId,
      eligibilityId: eligibilityId,
    );
  }

  Future<Map<String, dynamic>> assignAssistance({
    required String organizationId,
    required String assistanceId,
    required List<String> familyIds,
    required String requestId,
    String notes = '',
  }) {
    return remoteDataSource.assignAssistance(
      organizationId: organizationId,
      assistanceId: assistanceId,
      familyIds: familyIds,
      requestId: requestId,
      notes: notes,
    );
  }
}
