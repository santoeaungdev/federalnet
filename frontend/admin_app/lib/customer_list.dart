import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config.dart';
import 'edit_customer.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final _storage = const FlutterSecureStorage();
  bool _loading = false;
  String? _error;
  List<_CustomerRow> _customers = [];

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
    final token = await _storage.read(key: 'jwt');
    final dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      ),
    );

    try {
      final resp = await dio.get('/admin/customers');
      final data = resp.data as List<dynamic>;
      final items = data
          .map((e) => _CustomerRow.fromJson(
              Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
          .toList();
      setState(() => _customers = items);
    } catch (e) {
      setState(() => _error = 'Failed to load customers: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: _customers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final c = _customers[index];
                      return ListTile(
                        title: Text(c.username),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (c.fullname.isNotEmpty)
                              Text('Name: ${c.fullname}'),
                            Text('PPPoE: ${c.pppoeUsername}'),
                            Text('Group: ${c.groupname?.isNotEmpty == true ? c.groupname! : '-'}'),
                          ],
                        ),
                        trailing: Text('#${c.id}'),
                        onTap: () async {
                          final changed = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => EditCustomerPage(customerId: c.id),
                            ),
                          );
                          if (changed == true) {
                            _load();
                          }
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class _CustomerRow {
  final int id;
  final String username;
  final String fullname;
  final String pppoeUsername;
  final String? groupname;

  _CustomerRow({
    required this.id,
    required this.username,
    required this.fullname,
    required this.pppoeUsername,
    required this.groupname,
  });

  factory _CustomerRow.fromJson(Map<String, dynamic> json) {
    return _CustomerRow(
      id: (json['id'] as num).toInt(),
      username: json['username']?.toString() ?? '',
      fullname: json['fullname']?.toString() ?? '',
      pppoeUsername: json['pppoe_username']?.toString() ?? '',
      groupname: json['groupname']?.toString(),
    );
  }
}
