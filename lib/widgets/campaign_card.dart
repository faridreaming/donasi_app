import 'package:flutter/material.dart';

import '../models/campaign_model.dart';

class CampaignCard extends StatelessWidget {
  const CampaignCard({
    super.key,
    required this.campaign,
    required this.onDonate,
  });

  final Campaign campaign;
  final Future<void> Function() onDonate;

  String _formatCurrency(int value) {
    final digits = value.toString();
    final reversed = digits.split('').reversed.toList();
    final buffer = StringBuffer();

    for (var i = 0; i < reversed.length; i++) {
      buffer.write(reversed[i]);
      if (i != reversed.length - 1 && (i + 1) % 3 == 0) {
        buffer.write('.');
      }
    }

    return buffer.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFFF7043)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        campaign.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress Donasi',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(campaign.progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: campaign.progress,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFFE53935),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Terkumpul Rp ${_formatCurrency(campaign.collected)} dari target Rp ${_formatCurrency(campaign.target)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await onDonate();
                },
                icon: const Icon(Icons.volunteer_activism, size: 20),
                label: const Text('Donasi 50k'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
