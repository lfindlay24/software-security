import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TOTPVerificationPage extends StatefulWidget {
  final String username;
  final String masterPassword;

  const TOTPVerificationPage(
      {super.key, required this.username, required this.masterPassword});

  @override
  State<TOTPVerificationPage> createState() => _TOTPVerificationPageState();
}

class _TOTPVerificationPageState extends State<TOTPVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _totpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _totpController.dispose();
    super.dispose();
  }

  Future<void> _verifyTOTP() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('https://verify-totp-271131837642.us-west1.run.app'),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            'username': widget.username,
            'totp_code': _totpController.text.trim(),
          }),
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200) {
          // TOTP verification successful, navigate to vault
          Navigator.of(context).pushReplacementNamed(
            '/vault',
            arguments: {
              'username': widget.username,
              'master_password': widget.masterPassword
            },
          );
        } else {
          final error =
              jsonDecode(response.body)['error'] ?? 'Verification failed';
          _showErrorDialog(error);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Network error. Please check your connection.');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verification Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.security,
                          size: 80,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Two-Factor Authentication',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter the 6-digit code from your authenticator app',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // TOTP Code Field
                        TextFormField(
                          controller: _totpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: '6-Digit Code',
                            prefixIcon: const Icon(Icons.pin),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            counterText: '',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the 6-digit code';
                            }
                            if (value.length != 6) {
                              return 'Code must be 6 digits';
                            }
                            if (!RegExp(r'^\d+$').hasMatch(value)) {
                              return 'Code must contain only numbers';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Verify Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyTOTP,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Verify',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Back to Login
                        TextButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pushReplacementNamed('/login');
                          },
                          child: const Text(
                            'Back to Login',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
