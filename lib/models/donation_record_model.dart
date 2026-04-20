import 'package:cloud_firestore/cloud_firestore.dart';

class DonationRecord {
  const DonationRecord({
    required this.id,
    required this.campaignId,
    required this.campaignTitle,
    required this.userId,
    required this.userEmail,
    required this.displayName,
    required this.isAnonymous,
    required this.amount,
    required this.createdAt,
  });

  final String id;
  final String campaignId;
  final String campaignTitle;
  final String userId;
  final String userEmail;
  final String displayName;
  final bool isAnonymous;
  final int amount;
  final DateTime? createdAt;

  factory DonationRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdTimestamp = data['createdAt'] as Timestamp?;

    return DonationRecord(
      id: doc.id,
      campaignId: data['campaignId'] as String? ?? '',
      campaignTitle: data['campaignTitle'] as String? ?? 'Campaign',
      userId: data['userId'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '-',
      displayName: data['displayName'] as String? ?? '-',
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      createdAt: createdTimestamp?.toDate(),
    );
  }
}
