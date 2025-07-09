import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:login_app/main.dart';

void main() {
  testWidgets('Login page smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the login page is displayed
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
  });

  testWidgets('Username field validation', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Tap the Sign In button without entering username
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    // Should show validation error
    expect(find.text('Please enter your username'), findsOneWidget);
  });

  testWidgets('Password field validation', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Enter username but leave password empty
    await tester.enterText(find.byType(TextFormField).first, 'testuser');
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    // Should show validation error for password
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('Password visibility toggle', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Find the password field and visibility button
    final passwordField = find.byType(TextFormField).last;
    final visibilityButton = find.byIcon(Icons.visibility_off);

    // Initially password should be obscured
    expect(visibilityButton, findsOneWidget);

    // Tap the visibility button
    await tester.tap(visibilityButton);
    await tester.pump();

    // Now it should show the visibility icon (password visible)
    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });
}
