import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/donation_config.dart';
import '../models/campaign_model.dart';
import '../models/donation_record_model.dart';
import '../services/auth_service.dart';
import '../services/campaign_service.dart';
import 'campaign_detail_screen.dart';
import '../utils/currency_formatter.dart';
import '../widgets/campaign_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final CampaignService _campaignService = CampaignService();
  int _selectedIndex = 0;

  String _greetingName(User? user) {
    final email = user?.email;
    if (email == null || email.isEmpty) {
      return 'Pengguna';
    }
    return email.split('@').first;
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return '-';
    }

    final dd = dateTime.day.toString().padLeft(2, '0');
    final mm = dateTime.month.toString().padLeft(2, '0');
    final yyyy = dateTime.year.toString();
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final min = dateTime.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  PreferredSizeWidget _buildTopBar(User? user) {
    final titles = ['Beranda Donatur', 'Riwayat Saya'];
    final subtitles = [
      'Temukan campaign aktif dan bantu hari ini.',
      'Pantau semua kontribusi yang sudah kamu kirim.',
    ];

    return AppBar(
      toolbarHeight: 76,
      titleSpacing: 16,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF2E6), Color(0xFFFDE1CC)],
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD84A24).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _selectedIndex == 0
                  ? Icons.volunteer_activism
                  : Icons.receipt_long_outlined,
              color: const Color(0xFFB43D1E),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titles[_selectedIndex],
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E1C15),
                    fontSize: 18,
                  ),
                ),
                Text(
                  subtitles[_selectedIndex],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.brown.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(30),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEAD8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Halo ${_greetingName(user)}. Terima kasih sudah terus membantu sesama.',
              style: const TextStyle(
                color: Color(0xFF7A3A20),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignTab(User? user) {
    final quickDonateAmount = formatRupiah(kQuickDonateAmount);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8F1), Color(0xFFF8EFE6)],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC64022), Color(0xFFF08A55)],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB43A1E).withOpacity(0.26),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aksi baik hari ini, ${_greetingName(user)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Semua campaign diperbarui real-time. Pilih yang paling ingin kamu bantu.',
                  style: TextStyle(
                    color: Color(0xFFFFEFE5),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.shield_outlined,
                    label: 'Akun aman',
                    value: 'Verifikasi aktif',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.bolt,
                    label: 'Donasi cepat',
                    value: 'Rp $quickDonateAmount',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<Campaign>>(
              stream: _campaignService.watchCampaigns(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.cloud_off, size: 48),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Kampanye belum bisa dimuat saat ini. Silakan coba beberapa saat lagi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final campaigns = snapshot.data ?? const <Campaign>[];

                if (campaigns.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.volunteer_activism,
                              size: 34,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum ada campaign donasi aktif.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tim kami sedang menyiapkan campaign baru. Cek kembali sebentar lagi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: campaigns.length,
                  itemBuilder: (context, index) {
                    final campaign = campaigns[index];

                    return CampaignCard(
                      campaign: campaign,
                      onOpenDetail: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CampaignDetailScreen(campaign: campaign),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(User? user) {
    if (user == null) {
      return const Center(child: Text('Sesi login tidak ditemukan.'));
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8F1), Color(0xFFF8EFE6)],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFDEC9)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.history, color: Color(0xFFB83D1E)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Semua riwayat donasimu tersimpan di sini.',
                      style: TextStyle(
                        color: Colors.brown.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<DonationRecord>>(
              stream: _campaignService.watchUserDonations(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Riwayat donasi belum bisa dimuat sekarang.',
                        style: TextStyle(color: Colors.grey.shade700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final donations = snapshot.data ?? const <DonationRecord>[];
                if (donations.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.receipt_long,
                              size: 34,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Belum ada riwayat donasi.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Mulai donasi pertama kamu, lalu riwayatnya akan muncul di halaman ini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: donations.length,
                  itemBuilder: (context, index) {
                    final item = donations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(
                            0xFF14A35F,
                          ).withOpacity(0.14),
                          child: const Icon(
                            Icons.payments,
                            color: Color(0xFF11854D),
                          ),
                        ),
                        title: Text(
                          item.campaignTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${item.isAnonymous ? 'Hamba Allah' : item.displayName}\n${_formatDate(item.createdAt)}',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          'Rp ${formatRupiah(item.amount)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF11854D),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final pages = [_buildCampaignTab(user), _buildHistoryTab(user)];

    return Scaffold(
      appBar: _buildTopBar(user),
      body: pages[_selectedIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              height: 72,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'Riwayat',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFDEC9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A2F24).withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFE5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFD84A24)),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(color: Colors.brown.shade600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Color(0xFF35221A),
            ),
          ),
        ],
      ),
    );
  }
}
