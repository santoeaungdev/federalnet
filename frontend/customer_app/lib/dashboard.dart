import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config.dart';
import 'auth_storage.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _storage = const FlutterSecureStorage();
  bool _loading = true;
  double _balance = 0.0;
  List<dynamic> _activity = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatDt(DateTime dt) {
    return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';
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
      final me = await dio.get('/customers/me');
      double balance =
          double.tryParse((me.data['balance'] ?? '0').toString()) ?? 0.0;
      List<dynamic> activity = [];

      try {
        final act = await dio.get('/customer/activity');
        if (act.statusCode == 200) {
          activity = act.data as List<dynamic>;
        }
      } catch (e) {
        String msg = e.toString();
        if (e is DioException) {
          msg = e.response?.data?.toString() ?? e.message ?? e.toString();
        }
        setState(() {
          _error = 'Failed to load dashboard: $msg';
        });
      }

      if (mounted) {
        setState(() {
          _balance = balance;
          _activity = activity;
        });
      }
    } catch (e) {
      String msg = e.toString();
      if (e is DioException) {
        msg = e.response?.data?.toString() ?? e.message ?? e.toString();
      }
      setState(() {
        _error = 'Failed to load dashboard: $msg';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // prepare sorted entries with parsed timestamps
    final entries = _activity
        .map((a) => Map<String, dynamic>.from(a as Map))
        .map((item) {
      final t = (item['time'] ?? item['created_at'] ?? item['timestamp'] ?? '').toString();
      DateTime parsed;
      try {
        parsed = DateTime.parse(t).toLocal();
      } catch (_) {
        parsed = DateTime.now();
      }
      item['_dt'] = parsed;
      return item;
    }).toList();
    entries.sort((a, b) => (b['_dt'] as DateTime).compareTo(a['_dt'] as DateTime));
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Wallet',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Text('\$${_balance.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: const Text('Recent activity',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 8),
                      ...entries.map((item) {
                        final type = (item['type'] ?? '').toString();
                        final dt = item['_dt'] as DateTime;
                        final timeStr = _formatDt(dt);
                        String title = 'Activity';
                        String? amountStr;
                        Color? amountColor;

                        if (type == 'topup') {
                          final owner = item['owner_id']?.toString() ?? '';
                          final note = (item['note'] ?? '').toString();
                          final amt = item['amount'] != null ? double.tryParse(item['amount'].toString()) ?? 0.0 : 0.0;
                          title = note.isNotEmpty ? 'Topup: $note' : 'Topup from owner $owner';
                          amountStr = '+\$${amt.toStringAsFixed(2)}';
                          amountColor = Colors.green[700];
                        } else if (type == 'purchase') {
                          final plan = (item['plan_name'] ?? item['invoice'] ?? '').toString();
                          final price = item['price'] != null ? double.tryParse(item['price'].toString()) ?? 0.0 : 0.0;
                          title = plan.isNotEmpty ? 'Purchase: $plan' : 'Purchase';
                          amountStr = '-\$${price.toStringAsFixed(2)}';
                          amountColor = Colors.red[700];
                        } else {
                          title = (item['description'] ?? item['desc'] ?? type ?? 'Activity').toString();
                          if (item['amount'] != null) {
                            final a = double.tryParse(item['amount'].toString()) ?? 0.0;
                            amountStr = '\$${a.toStringAsFixed(2)}';
                            amountColor = a >= 0 ? Colors.green[700] : Colors.red[700];
                          }
                        }

                        return ListTile(
                          title: Text(title),
                          subtitle: Text(timeStr),
                          trailing: amountStr != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: amountColor?.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    amountStr,
                                    style: TextStyle(color: amountColor, fontWeight: FontWeight.w600),
                                  ),
                                )
                              : null,
                        );
                      }).toList(),
                      if (_activity.isEmpty)
                        Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('No recent activity',
                                style: TextStyle(color: Colors.grey[600]))),
                    ],
                  ),
      ),
    );
  }
}
