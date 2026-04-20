import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/donation_config.dart';
import '../models/campaign_model.dart';
import '../services/campaign_service.dart';
import '../utils/currency_formatter.dart';

class CampaignDetailScreen extends StatefulWidget {
  const CampaignDetailScreen({super.key, required this.campaign});

  final Campaign campaign;

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  final CampaignService _campaignService = CampaignService();
  bool _isProcessing = false;

  String _greetingName(User? user) {
    final email = user?.email;
    if (email == null || email.isEmpty) {
      return 'Pengguna';
    }
    return email.split('@').first;
  }

  Future<_DonationInput?> _showDonationDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    return showModalBottomSheet<_DonationInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _DonationDialog(
          userName: _greetingName(user),
          presetAmount: kQuickDonateAmount,
        );
      },
    );
  }

  Future<void> _handleDonate() async {
    final input = await _showDonationDialog();
    if (input == null || !mounted) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _campaignService.donate(
        widget.campaign.id,
        amount: input.amount,
        displayName: input.displayName,
        isAnonymous: input.isAnonymous,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            input.isAnonymous
                ? 'Donasi berhasil dikirim sebagai Hamba Allah.'
                : 'Donasi berhasil dikirim atas nama ${input.displayName}.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Donasi gagal: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Campaign')),
      body: StreamBuilder<Campaign?>(
        stream: _campaignService.watchCampaign(widget.campaign.id),
        initialData: widget.campaign,
        builder: (context, snapshot) {
          final campaign = snapshot.data ?? widget.campaign;
          final progressPercent = (campaign.progress * 100).toStringAsFixed(0);

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF8F1), Color(0xFFF8EFE6)],
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (campaign.imageUrl != null && campaign.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      campaign.imageUrl!,
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (campaign.imageUrl != null && campaign.imageUrl!.isNotEmpty)
                  const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFFFDDC8)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4D2F23).withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E1C15),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        campaign.description,
                        style: TextStyle(
                          color: Colors.brown.shade600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
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
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Terkumpul Rp ${formatRupiah(campaign.collected)} dari kebutuhan Rp ${formatRupiah(campaign.target)}',
                        style: TextStyle(
                          color: Colors.brown.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _handleDonate,
                          icon: const Icon(Icons.favorite),
                          label: Text(
                            _isProcessing ? 'Memproses...' : 'Lanjut Donasi',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DonationInput {
  const _DonationInput({
    required this.amount,
    required this.displayName,
    required this.isAnonymous,
  });

  final int amount;
  final String displayName;
  final bool isAnonymous;
}

class _DonationDialog extends StatefulWidget {
  const _DonationDialog({required this.userName, required this.presetAmount});

  final String userName;
  final int presetAmount;

  @override
  State<_DonationDialog> createState() => _DonationDialogState();
}

class _DonationDialogState extends State<_DonationDialog> {
  final TextEditingController _customAmountController = TextEditingController();
  final List<int> _presetAmounts = const [50000, 100000, 250000, 500000];

  int? _selectedAmount;
  bool _isAnonymous = false;

  @override
  void initState() {
    super.initState();
    _selectedAmount = widget.presetAmount;
    _customAmountController.text = widget.presetAmount.toString();
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = _selectedAmount == null
        ? int.tryParse(_customAmountController.text.trim())
        : _selectedAmount;

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal donasi yang valid.')),
      );
      return;
    }

    final displayName = _isAnonymous ? 'Hamba Allah' : widget.userName;
    Navigator.pop(
      context,
      _DonationInput(
        amount: amount,
        displayName: displayName,
        isAnonymous: _isAnonymous,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Nominal Donasi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetAmounts
                    .map(
                      (amount) => ChoiceChip(
                        label: Text('Rp ${formatRupiah(amount)}'),
                        selected: _selectedAmount == amount,
                        onSelected: (_) {
                          setState(() {
                            _selectedAmount = amount;
                            _customAmountController.text = amount.toString();
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _customAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal custom',
                  prefixText: 'Rp ',
                ),
                onTap: () {
                  setState(() {
                    _selectedAmount = null;
                  });
                },
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tampilkan sebagai Hamba Allah'),
                subtitle: const Text('Aktifkan untuk donasi anonim'),
                value: _isAnonymous,
                onChanged: (value) {
                  setState(() {
                    _isAnonymous = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Konfirmasi Donasi'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
