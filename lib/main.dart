import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Import file yang baru di-generate

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sekarang Firebase tahu konfigurasi untuk SEMUA platform
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const DonasiApp());
}

class DonasiApp extends StatelessWidget {
  const DonasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Donasi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('Firebase Berhasil Jalan! 🚀')),
      ),
    );
  }
}
