import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/donation_config.dart';
import '../models/campaign_model.dart';

class CampaignService {
  CampaignService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Campaign>> watchCampaigns() {
    return _firestore
        .collection('campaigns')
        .orderBy('title')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Campaign.fromDoc(doc))
              .toList(growable: false),
        );
  }

  Future<void> donate(String campaignId, {int amount = kQuickDonateAmount}) {
    return _firestore.collection('campaigns').doc(campaignId).update({
      'collected': FieldValue.increment(amount),
    });
  }
}
