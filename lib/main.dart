import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'config/admin_config.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Keep app running; upload service will show clear message if env is missing.
  }

  // Sekarang Firebase tahu konfigurasi untuk SEMUA platform
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const DonasiApp());
}

class DonasiApp extends StatelessWidget {
  const DonasiApp({super.key, this.authStateChanges});

  final Stream<User?>? authStateChanges;

  @override
  Widget build(BuildContext context) {
    final stream = authStateChanges ?? FirebaseAuth.instance.authStateChanges();

    return MaterialApp(
      title: 'Aplikasi Donasi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD84A24),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F2EA),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF2E1C15),
          titleTextStyle: TextStyle(
            color: Color(0xFF2E1C15),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFD84A24),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFFFE1D0),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected
                  ? const Color(0xFFB63B1D)
                  : const Color(0xFF8C6B5A),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            );
          }),
        ),
      ),
      // Gunakan StreamBuilder sebagai pemeriksa status login (Listener)
      home: StreamBuilder<User?>(
        stream: stream,
        builder: (context, snapshot) {
          // Jika masih loading mengecek status...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Jika ada data user (berarti sudah login)
          if (snapshot.hasData) {
            if (isAdminEmail(snapshot.data?.email)) {
              return const AdminHomeScreen();
            }
            return const DashboardScreen();
          }

          // Jika tidak ada user (berarti belum login / sudah logout)
          return const LoginScreen();
        },
      ),
    );
  }
}
