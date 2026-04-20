import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../config/donation_config.dart';
import '../models/campaign_model.dart';
import '../models/donation_record_model.dart';
import '../models/user_profile_model.dart';

class CampaignService {
  CampaignService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

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

  Stream<List<UserProfile>> watchUsers() {
    return _firestore
        .collection('users')
        .orderBy('lastLoginAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserProfile.fromDoc(doc))
              .toList(growable: false),
        );
  }

  Stream<List<DonationRecord>> watchDonations({int limit = 120}) {
    return _firestore
        .collection('donations')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DonationRecord.fromDoc(doc))
              .toList(growable: false),
        );
  }

  Stream<List<DonationRecord>> watchUserDonations(
    String userId, {
    int limit = 80,
  }) {
    return _firestore
        .collection('donations')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DonationRecord.fromDoc(doc))
              .toList(growable: false),
        );
  }

  Future<void> donate(
    String campaignId, {
    int amount = kQuickDonateAmount,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Kamu harus login dulu untuk berdonasi.');
    }

    final campaignRef = _firestore.collection('campaigns').doc(campaignId);
    final donationRef = _firestore.collection('donations').doc();

    await _firestore.runTransaction((transaction) async {
      final campaignSnap = await transaction.get(campaignRef);
      if (!campaignSnap.exists) {
        throw Exception('Campaign tidak ditemukan.');
      }

      final campaignData = campaignSnap.data() ?? <String, dynamic>{};
      final campaignTitle = campaignData['title'] as String? ?? 'Campaign';

      transaction.update(campaignRef, {
        'collected': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(donationRef, {
        'campaignId': campaignId,
        'campaignTitle': campaignTitle,
        'userId': user.uid,
        'userEmail': user.email?.trim().toLowerCase() ?? '-',
        'amount': amount,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> createCampaign({
    required String title,
    required String description,
    required int target,
    int collected = 0,
    String? imageUrl,
  }) {
    return _firestore.collection('campaigns').add({
      'title': title.trim(),
      'description': description.trim(),
      'target': target,
      'collected': collected,
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCampaign({
    required String campaignId,
    required String title,
    required String description,
    required int target,
    required int collected,
    String? imageUrl,
  }) {
    return _firestore.collection('campaigns').doc(campaignId).update({
      'title': title.trim(),
      'description': description.trim(),
      'target': target,
      'collected': collected,
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCampaign(String campaignId, {String? imageUrl}) async {
    await _firestore.collection('campaigns').doc(campaignId).delete();

    if (imageUrl != null && imageUrl.isNotEmpty) {
      await deleteImageByUrl(imageUrl);
    }
  }

  Future<String> uploadCampaignImage(
    XFile pickedImage, {
    void Function(double progress)? onProgress,
  }) async {
    final bytes = await pickedImage.readAsBytes();
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${pickedImage.name}';
    final ref = _storage.ref().child('campaign_images').child(fileName);

    final task = ref.putData(bytes);
    final subscription = task.snapshotEvents.listen((snapshot) {
      final total = snapshot.totalBytes;
      if (onProgress != null && total > 0) {
        onProgress(snapshot.bytesTransferred / total);
      }
    });

    await task;
    await subscription.cancel();
    return ref.getDownloadURL();
  }

  Future<void> deleteImageByUrl(String imageUrl) async {
    try {
      await _storage.refFromURL(imageUrl).delete();
    } on FirebaseException {
      // Ignore when image already deleted or URL is no longer valid.
    }
  }
}
