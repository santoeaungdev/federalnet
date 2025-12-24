import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config.dart';
import 'auth_storage.dart';
import 'jwt_utils.dart';

class OperatorListPage extends StatefulWidget {
  const OperatorListPage({super.key});

  @override
  State<OperatorListPage> createState() => _OperatorListPageState();
}

class _OperatorListPageState extends State<OperatorListPage> {
  final _storage = const FlutterSecureStorage();
  bool _loading = true;
  List<dynamic> _operators = [];
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
      final resp = await dio.get('/admin/operators');
      setState(() { _operators = resp.data as List<dynamic>; });
    } catch (e) {
      setState(() { _error = 'Failed: $e'; });
    } finally { if (mounted) setState(() { _loading = false; }); }
  }

  void _showEditDialog(Map<String,dynamic> op) {
    final username = TextEditingController(text: op['username'] ?? '');
    final fullname = TextEditingController(text: op['fullname'] ?? '');
    final password = TextEditingController();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Edit Operator'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: username, decoration: const InputDecoration(labelText: 'Username')),
        TextField(controller: fullname, decoration: const InputDecoration(labelText: 'Full Name')),
        TextField(controller: password, decoration: const InputDecoration(labelText: 'Password (leave blank to keep)'), obscureText: true),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          Navigator.of(ctx).pop();
          await _updateOperator(op['id'], username.text.trim(), password.text.trim(), fullname.text.trim());
        }, child: const Text('Save')),
      ],
    ));
  }

  Future<void> _updateOperator(dynamic id, String username, String password, String fullname) async {
    final token = await _storage.read(key: 'jwt') ?? await AuthStorage.readToken();
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl, headers: token != null ? {'Authorization': 'Bearer $token'} : {}));
    try {
      await dio.post('/admin/operators/$id', data: {
        'username': username,
        'password': password.isEmpty ? null : password,
        'fullname': fullname,
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Operator updated'))); _load(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _deleteOperator(dynamic id) async {
    final token = await _storage.read(key: 'jwt') ?? await AuthStorage.readToken();
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl, headers: token != null ? {'Authorization': 'Bearer $token'} : {}));
    try {
      await dio.delete('/admin/operators/$id');
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'))); _load(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Operators')),
      body: RefreshIndicator(onRefresh: _load, child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? ListView(children: [Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red)))]) : ListView.builder(
        itemCount: _operators.length,
        itemBuilder: (ctx, i) {
          final o = _operators[i] as Map<String,dynamic>;
          return ListTile(
            title: Text(o['username'] ?? ''),
            subtitle: Text(o['fullname'] ?? ''),
                          trailing: FutureBuilder<String?>(
                            future: getRole(),
                            builder: (ctx, snap) {
                              final role = snap.data;
                              final canDelete = role == 'admin' || role == 'superadmin';
                              return Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditDialog(o)),
                                if (canDelete) IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteOperator(o['id'])),
                              ]);
                            },
                          ),
          );
        },
      )),
    );
  }
}
