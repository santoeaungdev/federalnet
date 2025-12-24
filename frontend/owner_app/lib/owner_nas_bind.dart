import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config.dart';
import 'auth_storage.dart';

class OwnerNasBindPage extends StatefulWidget {
  const OwnerNasBindPage({super.key});

  @override
  State<OwnerNasBindPage> createState() => _OwnerNasBindPageState();
}

class _OwnerNasBindPageState extends State<OwnerNasBindPage> {
  final _storage = const FlutterSecureStorage();
  bool _loading = true;
  List<dynamic> _nas = [];
  String? _error;
  

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    final token = await _storage.read(key: 'jwt') ?? await AuthStorage.readToken();
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl, headers: token != null ? {'Authorization': 'Bearer $token'} : {}));
    try {
      final resp = await dio.get('/admin/nas');
      if (mounted) setState(() { _nas = resp.data as List<dynamic>; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load NAS: $e'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _bind(int nasId) async {
    final token = await _storage.read(key: 'jwt') ?? await AuthStorage.readToken();
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl, headers: token != null ? {'Authorization': 'Bearer $token'} : {}));
    try {
      // call admin_update_nas with owner_id set to owner's id; owner claims will enforce own id on server
      await dio.post('/admin/nas/$nasId', data: {
        'owner_id': null, // server will set if owner
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bind request sent')));
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bind/Unbind NAS')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red)))] )
                : ListView.separated(
                    separatorBuilder: (_, __) => const Divider(),
                    itemCount: _nas.length,
                    itemBuilder: (ctx, i) {
                      final n = _nas[i] as Map<String, dynamic>;
                      return ListTile(
                        title: Text(n['nasname'] ?? ''),
                        subtitle: Text(n['description'] ?? ''),
                        trailing: ElevatedButton(
                          onPressed: () => _bind(n['id']),
                          child: const Text('Bind/Unbind'),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
