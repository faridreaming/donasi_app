import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import '../config/donation_config.dart';
import '../models/campaign_model.dart';
import '../models/donation_record_model.dart';
import '../models/user_profile_model.dart';

class CampaignService {
  CampaignService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String get _cloudinaryCloudName =>
      (dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '').trim();
  String get _cloudinaryUploadPreset =>
      (dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '').trim();

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

  Stream<Campaign?> watchCampaign(String campaignId) {
    return _firestore
        .collection('campaigns')
        .doc(campaignId)
        .snapshots()
        .map((doc) => doc.exists ? Campaign.fromDoc(doc) : null);
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
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs.map(DonationRecord.fromDoc).toList();
          items.sort((left, right) {
            final leftTime =
                left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final rightTime =
                right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return rightTime.compareTo(leftTime);
          });
          return items;
        });
  }

  Future<void> donate(
    String campaignId, {
    int amount = kQuickDonateAmount,
    required String displayName,
    required bool isAnonymous,
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
        'displayName': displayName.trim(),
        'isAnonymous': isAnonymous,
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
    if (_cloudinaryCloudName.isEmpty || _cloudinaryUploadPreset.isEmpty) {
      throw Exception(
        'Konfigurasi Cloudinary belum diisi di file .env. Isi CLOUDINARY_CLOUD_NAME dan CLOUDINARY_UPLOAD_PRESET terlebih dahulu.',
      );
    }

    final bytes = await pickedImage.readAsBytes();
    final endpoint = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload',
    );

    onProgress?.call(0.1);

    final request = http.MultipartRequest('POST', endpoint)
      ..fields['upload_preset'] = _cloudinaryUploadPreset
      ..fields['folder'] = 'campaign_images'
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: pickedImage.name),
      );

    final streamed = await request.send();
    final responseBody = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('Upload gagal (${streamed.statusCode}): $responseBody');
    }

    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    final secureUrl = decoded['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary tidak mengembalikan secure_url.');
    }

    onProgress?.call(1.0);
    return secureUrl;
  }

  Future<void> deleteImageByUrl(String imageUrl) async {
    // Unsigned Cloudinary upload cannot securely delete assets from client side.
    // Keep this as no-op unless deletion is implemented via backend.
  }
}
