import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config.dart';
import 'auth_storage.dart';
import 'dashboard.dart';

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
    setState(() {
      _loading = true;
      _error = null;
    });
    final token =
        await _storage.read(key: 'jwt') ?? await AuthStorage.readToken();
    final dio = Dio(BaseOptions(
        baseUrl: apiBaseUrl,
        headers: token != null ? {'Authorization': 'Bearer $token'} : {}));
    try {
      final p = await dio.get('/internet_plans');
      final me = await dio.get('/customers/me');
      setState(() {
        _plans = p.data as List<dynamic>;
        _balance =
            double.tryParse((me.data['balance'] ?? '0').toString()) ?? 0.0;
      });
    } catch (e) {
      String msg = e.toString();
      if (e is DioException) {
        msg = e.response?.data?.toString() ?? e.message ?? e.toString();
      }
      setState(() {
        _error = 'Failed to load: $msg';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _purchase(int planId, dynamic priceRaw) async {
    final token =
        await _storage.read(key: 'jwt') ?? await AuthStorage.readToken();
    final dio = Dio(BaseOptions(
        baseUrl: apiBaseUrl,
        headers: token != null ? {'Authorization': 'Bearer $token'} : {}));
    try {
      final price = double.tryParse(priceRaw?.toString() ?? '') ?? 0.0;
      if (_balance < price) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insufficient balance')),
        );
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm Purchase'),
          content: Text('Purchase plan for \$${price.toStringAsFixed(2)}?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Buy')),
          ],
        ),
      );
      if (confirmed != true) return;

        await dio.post('/customer/purchase_plan', data: {'plan_id': planId});
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Plan purchased')));
        _load();
    } catch (e) {
      String msg = e.toString();
      if (e is DioException) {
        msg = e.response?.data?.toString() ?? e.message ?? e.toString();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $msg')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const DashboardPage())),
            tooltip: 'Dashboard',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)))
                  ])
                : ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                                'Available balance: \$${_balance.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),
                      ..._plans.map((p) {
                        final plan = p as Map<String, dynamic>;
                        final price = double.tryParse(
                                (plan['price'] ?? '0').toString()) ??
                            0.0;
                        final canBuy = _balance >= price;
                        return ListTile(
                          title: Text(plan['name'] ?? ''),
                          subtitle:
                              Text('Price: \$${price.toStringAsFixed(2)}'),
                          trailing: ElevatedButton(
                            onPressed: canBuy
                                ? () => _purchase(
                                    (plan['id'] as num).toInt(), plan['price'])
                                : null,
                            child: Text(canBuy ? 'Buy' : 'Insufficient'),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
      ),
      // balance is shown in the top card; bottom bar removed to avoid duplication
    );
  }
}
