import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

class MFASetupPage extends StatefulWidget {
  final String username;
  final String masterPassword;

  const MFASetupPage(
      {super.key, required this.username, required this.masterPassword});

  @override
  State<MFASetupPage> createState() => _MFASetupPageState();
}

class _MFASetupPageState extends State<MFASetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _totpController = TextEditingController();
  bool _isLoading = false;
  String? _secretKey;
  String? _qrCodeData;

  @override
  void initState() {
    super.initState();
    _generateMFASetup();
  }

  @override
  void dispose() {
    _totpController.dispose();
    super.dispose();
  }

  Future<void> _generateMFASetup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://setup-mfa-271131837642.us-west1.run.app'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'username': widget.username,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _secretKey = data['secret'];
          _qrCodeData = data['qr_code_uri'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Failed to generate MFA setup');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Network error. Please check your connection.');
    }
  }

  Future<void> _verifyAndCompleteMFASetup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('https://complete-mfa-setup-271131837642.us-west1.run.app'),
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
          // MFA setup successful, navigate to vault
          Navigator.of(context).pushReplacementNamed(
            '/vault',
            arguments: {
              'username': widget.username,
              'master_password': widget.masterPassword
            },
          );
        } else {
          final error = jsonDecode(response.body)['error'] ?? 'Setup failed';
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

  void _copySecretKey() {
    if (_secretKey != null) {
      Clipboard.setData(ClipboardData(text: _secretKey!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Secret key copied to clipboard')),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup Failed'),
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
      appBar: AppBar(
        title: const Text('Setup Two-Factor Authentication'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.security, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    'Step 1: Scan QR Code',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Scan this QR code with your authenticator app (Google Authenticator, Authy, etc.):',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              if (_qrCodeData != null)
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: QrImageView(
                                      data: _qrCodeData!,
                                      version: QrVersions.auto,
                                      size: 200.0,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.key, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text(
                                    'Manual Entry (Optional)',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'If you cannot scan the QR code, manually enter this secret key:',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              if (_secretKey != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _secretKey!,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _copySecretKey,
                                        icon: const Icon(Icons.copy),
                                        tooltip: 'Copy secret key',
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.verified_user,
                                        color: Colors.green),
                                    SizedBox(width: 8),
                                    Text(
                                      'Step 2: Verify Setup',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Enter the 6-digit code from your authenticator app to complete setup:',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 16),

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

                                // Complete Setup Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _verifyAndCompleteMFASetup,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
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
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'Complete Setup',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Skip MFA Button (for now)
                                SizedBox(
                                  width: double.infinity,
                                  height: 40,
                                  child: TextButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Skip MFA Setup?'),
                                          content: const Text(
                                              'You can set up two-factor authentication later from the vault menu. Your account will be less secure without MFA.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                Navigator.of(context)
                                                    .pushReplacementNamed(
                                                  '/vault',
                                                  arguments: {
                                                    'username': widget.username,
                                                    'master_password':
                                                        widget.masterPassword
                                                  },
                                                );
                                              },
                                              child: const Text('Skip for Now'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Skip for Now',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
