import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_referral_repository.dart';

/// Spark demo: all referral writes go through Firestore, not Cloud Functions.
class ReferralRepository extends FirestoreReferralRepository {
  ReferralRepository({FirebaseFirestore? firestore}) : super(firestore: firestore);
}
