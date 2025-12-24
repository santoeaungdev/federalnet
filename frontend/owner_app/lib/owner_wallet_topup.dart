import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config.dart';
import 'auth_storage.dart';

class OwnerWalletTopupPage extends StatefulWidget {
  const OwnerWalletTopupPage({super.key});

  @override
  State<OwnerWalletTopupPage> createState() => _OwnerWalletTopupPageState();
}

class _OwnerWalletTopupPageState extends State<OwnerWalletTopupPage> {
  final _storage = const FlutterSecureStorage();
  final _amount = TextEditingController();
  final _customerId = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    final a = _amount.text.trim();
    final cid = int.tryParse(_customerId.text.trim());
    if (a.isEmpty || cid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amount and customer id required')));
      }
      return;
    }
    if (mounted) setState(() { _loading = true; });
    final token = await _storage.read(key: 'jwt') ?? await AuthStorage.readToken();
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl, headers: token != null ? {'Authorization': 'Bearer $token'} : {}));
    try {
      // owner_id passed in path; admin owner endpoints accept owner_id path. For owner self, we assume token.sub available server-side.
      await dio.post('/admin/owners/0/topup_customer', data: {
        'customer_id': cid,
        'amount': a,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Top-up requested')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner Wallet Top-up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _customerId, decoration: const InputDecoration(labelText: 'Customer ID'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: _amount, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loading ? null : _submit, child: Text(_loading ? 'Submitting...' : 'Top-up')),
          ],
        ),
      ),
    );
  }
}
