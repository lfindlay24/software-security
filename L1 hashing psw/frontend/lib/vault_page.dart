import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VaultPage extends StatefulWidget {
  final String username;
  final String masterPassword;
  const VaultPage(
      {super.key, required this.username, required this.masterPassword});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = false;
  bool _mfaEnabled = false;

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
    _checkMFAStatus();
  }

  Future<void> _checkMFAStatus() async {
    try {
      final response = await http.post(
        Uri.parse('https://check-mfa-status-271131837642.us-west1.run.app'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'username': widget.username}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _mfaEnabled = data['mfa_enabled'] ?? false;
        });
      }
    } catch (e) {
      // Handle error silently or show a notification
      debugPrint('Failed to check MFA status: $e');
    }
  }

  Future<void> _fetchAccounts() async {
    setState(() {
      _isLoading = true;
    });
    final response = await http.post(
      Uri.parse('https://get-accounts-271131837642.us-west1.run.app'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'username': widget.username,
        'master_password': widget.masterPassword,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _accounts = List<Map<String, dynamic>>.from(data['accounts'] ?? []);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load accounts')),
      );
    }
  }

  void _showAddAccountDialog() {
    final _formKey = GlobalKey<FormState>();
    final _accountIdController = TextEditingController();
    final _accountUsernameController = TextEditingController();
    final _accountPasswordController = TextEditingController();
    final _commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Account'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _accountIdController,
                    decoration: const InputDecoration(labelText: 'Account ID'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _accountUsernameController,
                    decoration:
                        const InputDecoration(labelText: 'Account Username'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _accountPasswordController,
                    decoration:
                        const InputDecoration(labelText: 'Account Password'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _commentController,
                    decoration:
                        const InputDecoration(labelText: 'Comment (optional)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final response = await http.post(
                    Uri.parse(
                        'https://add-account-271131837642.us-west1.run.app'),
                    headers: {
                      'Content-Type': 'application/json; charset=UTF-8'
                    },
                    body: jsonEncode({
                      'username': widget.username,
                      'master_password': widget.masterPassword,
                      'account_id': _accountIdController.text.trim(),
                      'account_username':
                          _accountUsernameController.text.trim(),
                      'account_password':
                          _accountPasswordController.text.trim(),
                      'comment': _commentController.text.trim(),
                    }),
                  );
                  if (response.statusCode == 200) {
                    Navigator.of(context).pop();
                    _fetchAccounts();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add account')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Password Vault'),
            if (_mfaEnabled) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.verified_user,
                color: Colors.green,
                size: 20,
              ),
              const Text(
                ' (MFA)',
                style: TextStyle(fontSize: 12, color: Colors.green),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAccounts,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddAccountDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'mfa_setup') {
                Navigator.of(context).pushNamed(
                  '/mfa-setup',
                  arguments: {
                    'username': widget.username,
                    'master_password': widget.masterPassword
                  },
                );
              } else if (value == 'logout') {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'mfa_setup',
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Setup MFA'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
              ? const Center(child: Text('No accounts stored.'))
              : ListView.builder(
                  itemCount: _accounts.length,
                  itemBuilder: (context, i) {
                    final acc = _accounts[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(acc['account_id'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Username: ${acc['account_username'] ?? ''}'),
                            Text('Password: ${acc['account_password'] ?? ''}'),
                            if ((acc['comment'] ?? '').isNotEmpty)
                              Text('Comment: ${acc['comment']}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
