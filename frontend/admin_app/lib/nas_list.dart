import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';
import 'auth_storage.dart';

class NasListPage extends StatefulWidget {
  const NasListPage({super.key});

  @override
  State<NasListPage> createState() => _NasListPageState();
}

class _NasListPageState extends State<NasListPage> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> _nasList = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNasList();
  }

  Future<void> _loadNasList() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final token = await _storage.read(key: 'jwt');
    if (token == null) {
      setState(() {
        _loading = false;
        _error = 'No authentication token found. Please log in.';
      });
      return;
    }

    final dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Authorization': 'Bearer $token'},
    ));

    try {
      final resp = await dio.get('/admin/nas');
      setState(() {
        _nasList = resp.data as List<dynamic>;
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _loading = false;
        _error = _describeError(e);
      });
    }
  }

  String _describeError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) {
      return 'Session expired. Please log in again.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Check your network and retry.';
    }
    return 'Network error. Please try again.';
  }

  void _showCreateDialog() {
    final nasnameCtrl = TextEditingController();
    final shortnameCtrl = TextEditingController();
    final secretCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create NAS (Router)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nasnameCtrl,
                decoration: const InputDecoration(
                  labelText: 'NAS Name (IP or hostname)',
                  hintText: '192.168.1.1',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: shortnameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Short Name',
                  hintText: 'router1',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: secretCtrl,
                decoration: const InputDecoration(
                  labelText: 'RADIUS Secret',
                  hintText: 'mysecret123',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Main Router',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nasname = nasnameCtrl.text.trim();
              final secret = secretCtrl.text.trim();
              if (nasname.isEmpty || secret.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('NAS Name and Secret are required')),
                );
                return;
              }

              Navigator.of(ctx).pop();
              await _createNas(
                nasname,
                shortnameCtrl.text.trim(),
                secret,
                descCtrl.text.trim(),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createNas(
    String nasname,
    String shortname,
    String secret,
    String description,
  ) async {
    final token = await _storage.read(key: 'jwt');
    final dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      headers: {'Authorization': 'Bearer $token'},
    ));

    try {
      await dio.post('/admin/nas', data: {
        'nasname': nasname,
        'shortname': shortname.isEmpty ? null : shortname,
        'secret': secret,
        'description': description.isEmpty ? null : description,
        'type': 'other',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NAS created successfully')),
        );
        _loadNasList();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create NAS: ${_describeError(e)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NAS (Routers)'),
        backgroundColor: Colors.blue,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadNasList,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _nasList.isEmpty
                  ? const Center(child: Text('No NAS entries found'))
                  : ListView.builder(
                      itemCount: _nasList.length,
                      itemBuilder: (ctx, idx) {
                        final nas = _nasList[idx] as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(nas['nasname'] ?? ''),
                            subtitle: Text(
                              'Shortname: ${nas['shortname'] ?? 'N/A'}\n'
                              'Type: ${nas['nas_type'] ?? 'other'}\n'
                              'Description: ${nas['description'] ?? 'N/A'}',
                            ),
                            isThreeLine: true,
                            leading: const CircleAvatar(
                              child: Icon(Icons.router),
                            ),
                          ),
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
