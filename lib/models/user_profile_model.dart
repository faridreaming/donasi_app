import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.lastLoginAt,
  });

  final String uid;
  final String email;
  final String role;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  bool get isAdmin => role.toLowerCase() == 'admin';

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdTimestamp = data['createdAt'] as Timestamp?;
    final lastLoginTimestamp = data['lastLoginAt'] as Timestamp?;

    return UserProfile(
      uid: doc.id,
      email: data['email'] as String? ?? '-',
      role: data['role'] as String? ?? 'user',
      createdAt: createdTimestamp?.toDate(),
      lastLoginAt: lastLoginTimestamp?.toDate(),
    );
  }
}
