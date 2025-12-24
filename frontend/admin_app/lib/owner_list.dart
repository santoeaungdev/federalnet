import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'jwt_utils.dart';

import 'config.dart';
import 'auth_storage.dart';

class OwnerListPage extends StatefulWidget {
  const OwnerListPage({super.key});

  @override
  State<OwnerListPage> createState() => _OwnerListPageState();
}

class _OwnerListPageState extends State<OwnerListPage> {
  final _storage = const FlutterSecureStorage();
  bool _loading = true;
  String? _error;
  List<dynamic> _owners = [];

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
    var token = await _storage.read(key: 'jwt');
    token ??= await AuthStorage.readToken();
    final dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    ));

    try {
      final resp = await dio.get('/admin/owners');
      setState(() {
        _owners = resp.data as List<dynamic>;
      });
    } on DioException catch (e) {
      setState(() {
        _error = 'Failed to load owners: ${e.message}';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreateDialog() {
    final username = TextEditingController();
    final fullname = TextEditingController();
    final password = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Owner'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: username, decoration: const InputDecoration(labelText: 'Username')),
              const SizedBox(height: 12),
              TextField(controller: fullname, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 12),
              TextField(controller: password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username and password are required')));
                return;
              }
              Navigator.of(ctx).pop();
              await _createOwner(u, p, f);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createOwner(String username, String password, String fullname) async {
    final token = await _storage.read(key: 'jwt');
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl, headers: {'Authorization': 'Bearer $token'}));
    try {
      await dio.post('/admin/owners', data: {
        'username': username,
        'password': password,
        'fullname': fullname,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Owner created')));
        _load();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create owner: ${e.message}')));
      }
    }
  }

  void _showEditDialog(Map<String, dynamic> owner) {
    final username = TextEditingController(text: owner['username'] ?? '');
    final fullname = TextEditingController(text: owner['fullname'] ?? '');
    final password = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Owner'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: username, decoration: const InputDecoration(labelText: 'Username')),
              const SizedBox(height: 12),
              TextField(controller: fullname, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 12),
              TextField(controller: password, decoration: const InputDecoration(labelText: 'Password (leave blank to keep)'), obscureText: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final u = username.text.trim();
              final f = fullname.text.trim();
              final p = password.text.trim();
              Navigator.of(ctx).pop();
              await _updateOwner(owner['id'], u, p.isEmpty ? null : p, f);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOwner(dynamic id, String username, String? password, String fullname) async {
    final token = await _storage.read(key: 'jwt');
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl, headers: {'Authorization': 'Bearer $token'}));
    try {
      await dio.post('/admin/owners/$id', data: {
        'username': username,
        'password': password,
        'fullname': fullname,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Owner updated')));
        _load();
      }
    } on DioException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update owner: ${e.message}')));
    }
  }

  Future<void> _deleteOwner(dynamic id) async {
    final token = await _storage.read(key: 'jwt');
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl, headers: {'Authorization': 'Bearer $token'}));
    try {
      await dio.delete('/admin/owners/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Owner deleted')));
        _load();
      }
    } on DioException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete owner: ${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owners')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _owners.isEmpty
                  ? const Center(child: Text('No owners found'))
                  : ListView.builder(
                      itemCount: _owners.length,
                      itemBuilder: (ctx, i) {
                        final o = _owners[i] as Map<String, dynamic>;
                        return FutureBuilder<String?>(
                          future: getRole(),
                          builder: (context, snap) {
                            final role = snap.data;
                            final canDelete = role == 'admin' || role == 'superadmin';
                            return ListTile(
                              title: Text(o['username'] ?? ''),
                              subtitle: Text(o['fullname'] ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditDialog(o)),
                                  if (canDelete) IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteOwner(o['id'])),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
