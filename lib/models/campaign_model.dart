import 'package:cloud_firestore/cloud_firestore.dart';

class Campaign {
  const Campaign({
    required this.id,
    required this.title,
    required this.description,
    required this.collected,
    required this.target,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String description;
  final int collected;
  final int target;
  final String? imageUrl;

  double get progress {
    if (target <= 0) return 0;
    return (collected / target).clamp(0.0, 1.0);
  }

  factory Campaign.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return Campaign(
      id: doc.id,
      title: data['title'] as String? ?? 'Tanpa Judul',
      description:
          data['description'] as String? ?? 'Belum ada deskripsi kampanye.',
      collected: (data['collected'] as num?)?.toInt() ?? 0,
      target: (data['target'] as num?)?.toInt() ?? 0,
      imageUrl: data['imageUrl'] as String?,
    );
  }
}
