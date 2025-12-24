import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config.dart';
import 'auth_storage.dart';

class OwnerIncomePage extends StatefulWidget {
  const OwnerIncomePage({super.key});

  @override
  State<OwnerIncomePage> createState() => _OwnerIncomePageState();
}

class _OwnerIncomePageState extends State<OwnerIncomePage> {
  final _storage = const FlutterSecureStorage();
  bool _loading = true;
  List<dynamic> _rows = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final token = await _storage.read(key: 'jwt') ?? await AuthStorage.readToken();
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl, headers: token != null ? {'Authorization': 'Bearer $token'} : {}));
    try {
      final resp = await dio.get('/admin/owner_income');
      setState(() { _rows = resp.data as List<dynamic>; });
    } catch (e) {
      setState(() { _error = 'Failed to load owner income: $e'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner Income')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red)))])
                : ListView.separated(
                    separatorBuilder: (_, __) => const Divider(),
                    itemCount: _rows.length,
                    itemBuilder: (ctx, i) {
                      final r = _rows[i] as Map<String, dynamic>;
                      return ListTile(
                        title: Text(r['period'] ?? ''),
                        subtitle: Text('Revenue: ${r['revenue_total'] ?? '0'}  Tax: ${r['tax_total'] ?? '0'}'),
                      );
                    },
                  ),
      ),
    );
  }
}
