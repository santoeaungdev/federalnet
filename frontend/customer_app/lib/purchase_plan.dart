import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config.dart';
import 'auth_storage.dart';

class PurchasePlanPage extends StatefulWidget {
  const PurchasePlanPage({super.key});

  @override
  State<PurchasePlanPage> createState() => _PurchasePlanPageState();
}

class _PurchasePlanPageState extends State<PurchasePlanPage> {
  final _storage = const FlutterSecureStorage();
  bool _loading = true;
  List<dynamic> _plans = [];
  String? _error;
  double _balance = 0.0;

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
      final p = await dio.get('/admin/internet_plans');
      final me = await dio.get('/customers/me');
      setState(() {
        _plans = p.data as List<dynamic>;
        _balance = double.tryParse((me.data['balance'] ?? '0').toString()) ?? 0.0;
      });
    } catch (e) {
      setState(() { _error = 'Failed to load: $e'; });
    } finally { if (mounted) setState(() { _loading = false; }); }
  }

  Future<void> _purchase(int planId) async {
    final token = await _storage.read(key: 'jwt') ?? await AuthStorage.readToken();
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl, headers: token != null ? {'Authorization': 'Bearer $token'} : {}));
    try {
      final resp = await dio.post('/customer/purchase_plan', data: {'plan_id': planId});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan purchased')));
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Plan')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red)))])
                : ListView.builder(
                    itemCount: _plans.length,
                    itemBuilder: (ctx, i) {
                      final plan = _plans[i] as Map<String, dynamic>;
                      return ListTile(
                        title: Text(plan['name'] ?? ''),
                        subtitle: Text('Price: ${plan['price'] ?? ''}'),
                        trailing: ElevatedButton(
                          onPressed: () => _purchase((plan['id'] as num).toInt()),
                          child: const Text('Buy'),
                        ),
                      );
                    },
                  ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text('Balance: $_balance', textAlign: TextAlign.center),
      ),
    );
  }
}
