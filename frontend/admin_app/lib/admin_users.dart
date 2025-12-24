import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config.dart';
import 'auth_storage.dart';
import 'owner_list.dart';
import 'jwt_utils.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _storage = const FlutterSecureStorage();
  bool _loading = false;
  String? _error;
  List<dynamic> _owners = [];
  List<dynamic> _operators = [];

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
      final o = await dio.get('/admin/owners');
      final p = await dio.get('/admin/operators');
      setState(() {
        _owners = o.data as List<dynamic>;
        _operators = p.data as List<dynamic>;
      });
    } on DioException catch (e) {
      setState(() => _error = 'Failed to load users: ${e.message}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreateDialog() {
    final username = TextEditingController();
    final fullname = TextEditingController();
    final password = TextEditingController();
    String role = 'Owner';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: username, decoration: const InputDecoration(labelText: 'Username')),
              const SizedBox(height: 8),
              TextField(controller: fullname, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 8),
              TextField(controller: password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role,
                items: const [
                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'Report', child: Text('Report')),
                  DropdownMenuItem(value: 'Owner', child: Text('Owner')),
                  DropdownMenuItem(value: 'Operator', child: Text('Operator')),
                ],
                onChanged: (v) { if (v != null) role = v; },
                decoration: const InputDecoration(labelText: 'Role'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final u = username.text.trim();
              final p = password.text.trim();
              final f = fullname.text.trim();
              if (u.isEmpty || p.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username and password required')));
                return;
              }
              Navigator.of(ctx).pop();
              await _createUser(u, p, f, role);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createUser(String username, String password, String fullname, String role) async {
    final token = await _storage.read(key: 'jwt') ?? await AuthStorage.readToken();
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl, headers: token != null ? {'Authorization': 'Bearer $token'} : {}));
    try {
      await dio.post('/admin/users', data: {
        'username': username,
        'password': password,
        'fullname': fullname,
        'user_type': role,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User created')));
        _load();
      }
    } on DioException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create user: ${e.message}')));
    }
  }

  Future<void> _deleteUser(String type, dynamic id) async {
    final token = await _storage.read(key: 'jwt') ?? await AuthStorage.readToken();
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl, headers: token != null ? {'Authorization': 'Bearer $token'} : {}));
    try {
      if (type == 'Owner') {
        await dio.delete('/admin/owners/$id');
      } else if (type == 'Operator') {
        await dio.delete('/admin/operators/$id');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
        _load();
      }
    } on DioException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: ${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [Padding(padding: const EdgeInsets.all(16.0), child: Text(_error!, style: const TextStyle(color: Colors.red)))] )
                : ListView(
                    children: [
                      ListTile(
                        title: const Text('Create new user'),
                        trailing: ElevatedButton(onPressed: _showCreateDialog, child: const Text('Create')),
                      ),
                      const Divider(),
                      const Padding(padding: EdgeInsets.all(8.0), child: Text('Owners', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      ..._owners.map((o) => FutureBuilder<String?>(
                        future: getRole(),
                        builder: (ctx, snap) {
                          final role = snap.data;
                          final canDelete = role == 'admin' || role == 'superadmin';
                          return ListTile(
                            title: Text(o['username'] ?? ''),
                            subtitle: Text(o['fullname'] ?? ''),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(icon: const Icon(Icons.edit), onPressed: () async {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OwnerListPage())).then((_) => _load());
                              }),
                              if (canDelete) IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteUser('Owner', o['id'])),
                            ]),
                          );
                        },
                      )),
                          
                      const Divider(),
                      const Padding(padding: EdgeInsets.all(8.0), child: Text('Operators', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      ..._operators.map((o) => ListTile(
                            title: Text(o['username'] ?? ''),
                            subtitle: Text(o['fullname'] ?? ''),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(icon: const Icon(Icons.edit), onPressed: () async {
                                // navigate to operator edit - not implemented separately, reuse create UI
                                // For now, open create dialog prefilled by showing snackbar
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit operator via Operators screen')));
                              }),
                              IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteUser('Operator', o['id'])),
                            ]),
                          )),
                    ],
                  ),
      ),
    );
  }
}
