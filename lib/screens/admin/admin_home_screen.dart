import 'package:flutter/material.dart';

import '../../models/donation_record_model.dart';
import '../../models/user_profile_model.dart';
import '../../services/auth_service.dart';
import '../../services/campaign_service.dart';
import '../../utils/currency_formatter.dart';
import 'admin_campaign_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final CampaignService _campaignService = CampaignService();
  int _currentIndex = 0;

  static const List<String> _titles = [
    'Admin Dashboard',
    'Kelola Campaign',
    'Daftar User',
    'Riwayat Donasi',
  ];

  static const List<String> _subtitles = [
    'Ringkasan performa platform donasi',
    'Kelola campaign aktif dan konten visual',
    'Pantau role dan aktivitas akun pengguna',
    'Audit transaksi donasi terbaru',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      _AdminDashboardTab(campaignService: _campaignService),
      const AdminCampaignScreen(embedded: true),
      _AdminUsersTab(campaignService: _campaignService),
      _AdminDonationHistoryTab(campaignService: _campaignService),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: 16,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF5EC), Color(0xFFFEE8D8)],
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
              child: const Icon(
                Icons.admin_panel_settings_outlined,
                color: Color(0xFFB43D1E),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titles[_currentIndex],
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E1C15),
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    _subtitles[_currentIndex],
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
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              tooltip: 'Notifikasi',
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().logout();
            },
            icon: const Icon(Icons.logout),
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
              child: const Text(
                'Admin mode aktif. Semua perubahan tersimpan real-time.',
                style: TextStyle(
                  color: Color(0xFF7A3A20),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF4EA), Color(0xFFFDE8D6), Color(0xFFF7EFE5)],
          ),
        ),
        child: SafeArea(child: pages[_currentIndex]),
      ),
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
              selectedIndex: _currentIndex,
              elevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              height: 72,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.campaign_outlined),
                  selectedIcon: Icon(Icons.campaign),
                  label: 'Campaign',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: 'User',
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

class _AdminDashboardTab extends StatelessWidget {
  const _AdminDashboardTab({required this.campaignService});

  final CampaignService campaignService;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFB63B1D), Color(0xFFF2854E)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB63B1D).withOpacity(0.26),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
              SizedBox(height: 10),
              Text(
                'Portal Admin Donasi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Kelola campaign, pantau user, dan audit transaksi donasi dalam satu tempat.',
                style: TextStyle(color: Colors.white, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SummaryCard(
          title: 'Total Campaign',
          icon: Icons.campaign,
          stream: campaignService.watchCampaigns(),
          valueBuilder: (items) => items.length.toString(),
        ),
        _SummaryCard(
          title: 'Total User Terdaftar',
          icon: Icons.people,
          stream: campaignService.watchUsers(),
          valueBuilder: (items) => items.length.toString(),
        ),
        _SummaryCard(
          title: 'Jumlah Riwayat Donasi',
          icon: Icons.receipt_long,
          stream: campaignService.watchDonations(),
          valueBuilder: (items) => items.length.toString(),
        ),
      ],
    );
  }
}

class _SummaryCard<T> extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.stream,
    required this.valueBuilder,
  });

  final String title;
  final IconData icon;
  final Stream<List<T>> stream;
  final String Function(List<T>) valueBuilder;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<T>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 52,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Text(
                'Gagal memuat data $title',
                style: TextStyle(color: Colors.red.shade400),
              );
            }

            final items = snapshot.data ?? <T>[];

            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0E6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFFD84A24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(color: Colors.brown.shade600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        valueBuilder(items),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Color(0xFF35221A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdminUsersTab extends StatelessWidget {
  const _AdminUsersTab({required this.campaignService});

  final CampaignService campaignService;

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserProfile>>(
      stream: campaignService.watchUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Data user belum tersedia. Pastikan koleksi users sudah bisa dibaca.',
                style: TextStyle(color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final users = snapshot.data ?? const <UserProfile>[];
        if (users.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Belum ada data user. Data akan muncul setelah user login/registrasi.',
                style: TextStyle(color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final roleColor = user.isAdmin ? Colors.red : Colors.blueGrey;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: roleColor.withOpacity(0.14),
                  child: Icon(Icons.person, color: roleColor),
                ),
                title: Text(user.email),
                subtitle: Text(
                  'Login terakhir: ${_formatDate(user.lastLoginAt)}',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminDonationHistoryTab extends StatelessWidget {
  const _AdminDonationHistoryTab({required this.campaignService});

  final CampaignService campaignService;

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DonationRecord>>(
      stream: campaignService.watchDonations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Riwayat donasi belum bisa dimuat. Pastikan koleksi donations tersedia.',
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
              child: Text(
                'Belum ada transaksi donasi tercatat.',
                style: TextStyle(color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: donations.length,
          itemBuilder: (context, index) {
            final item = donations[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF14A35F).withOpacity(0.14),
                  child: const Icon(Icons.payments, color: Color(0xFF11854D)),
                ),
                title: Text(item.campaignTitle),
                subtitle: Text(
                  '${item.userEmail}\n${_formatDate(item.createdAt)}',
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
    );
  }
}
