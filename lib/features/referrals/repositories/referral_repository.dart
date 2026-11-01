
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'cloud_functions_referral_repository.dart';

/// Main repository used by ReferralService.
///
/// Currently delegates to the existing Cloud Functions
/// implementation.
///
/// Later, Firestore operations can replace the
/// Cloud Functions implementation without changing
/// the screens or controllers.

class ReferralRepository
    extends CloudFunctionsReferralRepository {

  ReferralRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : super(
    firestore: firestore,
    functions: functions,
  );
}
