import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config.dart';

class OwnerMembersPage extends StatefulWidget {
  const OwnerMembersPage({super.key});

  @override
  State<OwnerMembersPage> createState() => _OwnerMembersPageState();
}

class _OwnerMembersPageState extends State<OwnerMembersPage> {
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
    final token = await _storage.read(key: 'jwt');
    final dio = Dio(BaseOptions(
        baseUrl: apiBaseUrl,
        headers: token != null ? {'Authorization': 'Bearer $token'} : {}));
    try {
      final resp = await dio.get('/admin/owners');
      setState(() {
        _owners = resp.data as List<dynamic>;
      });
    } on DioException catch (e) {
      setState(() {
        _error = 'Failed to load family members: ${e.message}';
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
              title: const Text('Create Family Member'),
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: username,
                      decoration: const InputDecoration(labelText: 'Username')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: fullname,
                      decoration:
                          const InputDecoration(labelText: 'Full Name')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: password,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true),
                ]),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () async {
                      final u = username.text.trim();
                      final f = fullname.text.trim();
                      final p = password.text.trim();
                      if (u.isEmpty || p.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Username and password required')));
                        return;
                      }
                      Navigator.of(ctx).pop();
                      await _createMember(u, p, f);
                    },
                    child: const Text('Create'))
              ],
            ));
  }

  Future<void> _createMember(
      String username, String password, String fullname) async {
    final token = await _storage.read(key: 'jwt');
    final dio = Dio(BaseOptions(
        baseUrl: apiBaseUrl, headers: {'Authorization': 'Bearer $token'}));
    try {
      await dio.post('/admin/owners', data: {
        'username': username,
        'password': password,
        'fullname': fullname
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Family member created')));
        _load();
      }
    } on DioException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: ${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Members')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)))
              : _owners.isEmpty
                  ? const Center(child: Text('No family members'))
                  : ListView.builder(
                      itemCount: _owners.length,
                      itemBuilder: (ctx, i) {
                        final o = _owners[i] as Map<String, dynamic>;
                        return ListTile(
                          title: Text(o['username'] ?? ''),
                          subtitle: Text(o['fullname'] ?? ''),
                        );
                      }),
      floatingActionButton: FloatingActionButton(
          onPressed: _showCreateDialog, child: const Icon(Icons.add)),
    );
  }
}
