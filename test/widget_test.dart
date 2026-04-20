// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donasi_app/main.dart';

void main() {
  testWidgets('renders the app shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      const DonasiApp(authStateChanges: Stream<User?>.empty()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Ruang Donasi'), findsOneWidget);
    expect(find.text('Belum punya akun donatur? Daftar'), findsOneWidget);
  });
}
