import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'forgotpw_page.dart';
import 'vault_page.dart';
import 'mfa_setup_page.dart';
import 'totp_verification_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/vault': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, String>?;
          return VaultPage(
            username: args?['username'] ?? '',
            masterPassword: args?['master_password'] ?? '',
          );
        },
        '/mfa-setup': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, String>?;
          return MFASetupPage(
            username: args?['username'] ?? '',
            masterPassword: args?['master_password'] ?? '',
          );
        },
        '/totp-verification': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, String>?;
          return TOTPVerificationPage(
            username: args?['username'] ?? '',
            masterPassword: args?['master_password'] ?? '',
          );
        },
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
