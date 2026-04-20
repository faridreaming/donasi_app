import 'package:flutter/material.dart';

import '../models/campaign_model.dart';
import '../utils/currency_formatter.dart';

class CampaignCard extends StatelessWidget {
  const CampaignCard({
    super.key,
    required this.campaign,
    required this.onOpenDetail,
  });

  final Campaign campaign;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final progressPercent = (campaign.progress * 100).toStringAsFixed(0);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenDetail,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (campaign.imageUrl != null &&
                  campaign.imageUrl!.isNotEmpty) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        campaign.imageUrl!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.58),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Campaign Aktif',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
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
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF372119),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          campaign.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.brown.shade600,
                            height: 1.35,
                          ),
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
                    'Progress pendanaan',
                    style: TextStyle(
                      color: Colors.brown.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$progressPercent%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB83D1E),
                    ),
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
                'Terkumpul Rp ${formatRupiah(campaign.collected)} dari kebutuhan Rp ${formatRupiah(campaign.target)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.brown.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD84A24).withOpacity(0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: onOpenDetail,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text('Lihat detail'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
