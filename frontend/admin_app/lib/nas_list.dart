import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';

class NasListPage extends StatefulWidget {
  const NasListPage({super.key});

  @override
  State<NasListPage> createState() => _NasListPageState();
}

class _NasListPageState extends State<NasListPage> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> _nasList = [];
  List<dynamic> _owners = [];
  bool _loading = true;
  String? _error;
  int? _filterOwnerId; // null = all, -1 = unassigned, >0 = owner id

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
      // load owners for assignment dropdown
      _loadOwners();
    } on DioException catch (e) {
      setState(() {
        _loading = false;
        _error = _describeError(e);
      });
    }
  }

  Future<void> _loadOwners() async {
    final token = await _storage.read(key: 'jwt');
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl, headers: {'Authorization': 'Bearer $token'}));
    try {
      final resp = await dio.get('/admin/owners');
      if (mounted) setState(() => _owners = resp.data as List<dynamic>);
    } catch (_) {}
  }

  List<dynamic> _filteredNasList() {
    if (_filterOwnerId == null) return _nasList;
    if (_filterOwnerId == -1) {
      return _nasList.where((n) => n['owner_id'] == null).toList();
    }
    return _nasList.where((n) => n['owner_id'] != null && (n['owner_id'] as num).toInt() == _filterOwnerId).toList();
  }

  String _ownerNameForId(dynamic id) {
    if (id == null) return 'Unassigned';
    final iid = (id as num).toInt();
    final found = _owners.cast<Map<String, dynamic>>().firstWhere(
      (o) => (o['id'] as num).toInt() == iid,
      orElse: () => {},
    );
    if (found.isNotEmpty) return (found['fullname'] ?? found['username'] ?? 'Owner #$iid').toString();
    return 'Owner #$iid';
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
    // ensure owners are loaded for assignment
    _loadOwners();

    int? selectedOwner;

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
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: selectedOwner,
                decoration: const InputDecoration(labelText: 'Assigned Owner (optional)'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Unassigned')),
                  ..._owners.map((o) {
                    final m = o as Map<String, dynamic>;
                    return DropdownMenuItem<int?>(value: (m['id'] as num).toInt(), child: Text(m['fullname'] ?? m['username'] ?? ''));
                  }).toList(),
                ],
                onChanged: (v) => selectedOwner = v,
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
                selectedOwner,
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  static const String defaultNasType = 'other';

  Future<void> _createNas(
    String nasname,
    String shortname,
    String secret,
    String description,
    int? ownerId,
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
        'owner_id': ownerId,
        'type': defaultNasType,
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

  void _showEditDialog(Map<String, dynamic> nas) {
    final nasnameCtrl = TextEditingController(text: nas['nasname'] ?? '');
    final shortnameCtrl = TextEditingController(text: nas['shortname'] ?? '');
    final secretCtrl = TextEditingController(text: nas['secret'] ?? '');
    final descCtrl = TextEditingController(text: nas['description'] ?? '');
    int? selectedOwner = nas['owner_id'] != null ? (nas['owner_id'] as num).toInt() : null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit NAS'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nasnameCtrl,
                decoration: const InputDecoration(labelText: 'NAS Name (IP or hostname)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: shortnameCtrl,
                decoration: const InputDecoration(labelText: 'Short Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: secretCtrl,
                decoration: const InputDecoration(labelText: 'RADIUS Secret'),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: selectedOwner,
                decoration: const InputDecoration(labelText: 'Assigned Owner (optional)'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Unassigned')),
                  ..._owners.map((o) {
                    final m = o as Map<String, dynamic>;
                    return DropdownMenuItem<int?>(value: (m['id'] as num).toInt(), child: Text(m['fullname'] ?? m['username'] ?? ''));
                  }).toList(),
                ],
                onChanged: (v) => selectedOwner = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final nasname = nasnameCtrl.text.trim();
              final secret = secretCtrl.text.trim();
              if (nasname.isEmpty || secret.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NAS Name and Secret are required')));
                return;
              }
              Navigator.of(ctx).pop();
              await _updateNas(nas['id'], nasname, shortnameCtrl.text.trim(), secret, descCtrl.text.trim(), selectedOwner);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateNas(int id, String nasname, String shortname, String secret, String description, int? ownerId) async {
    final token = await _storage.read(key: 'jwt');
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl, headers: {'Authorization': 'Bearer $token'}));
    try {
      await dio.post('/admin/nas/$id', data: {
        'nasname': nasname,
        'shortname': shortname.isEmpty ? null : shortname,
        'secret': secret,
        'description': description.isEmpty ? null : description,
        'owner_id': ownerId,
        'type': defaultNasType,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NAS updated')));
        _loadNasList();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update NAS: ${_describeError(e)}')));
      }
    }
  }

  void _confirmDelete(dynamic id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete NAS'),
        content: const Text('Are you sure you want to delete this NAS? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _deleteNas(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNas(dynamic id) async {
    final token = await _storage.read(key: 'jwt');
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl, headers: {'Authorization': 'Bearer $token'}));
    try {
      await dio.delete('/admin/nas/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NAS deleted')));
        _loadNasList();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete NAS: ${_describeError(e)}')));
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
              : Builder(
                  builder: (ctx) {
                    final filtered = _filteredNasList();
                    if (filtered.isEmpty) return const Center(child: Text('No NAS entries found'));
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              const Text('Filter by owner:'),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButton<int?>(
                                  isExpanded: true,
                                  value: _filterOwnerId,
                                  items: [
                                    const DropdownMenuItem<int?>(value: null, child: Text('All')),
                                    const DropdownMenuItem<int?>(value: -1, child: Text('Unassigned')),
                                    ..._owners.map((o) {
                                      final m = o as Map<String, dynamic>;
                                      return DropdownMenuItem<int?>(
                                          value: (m['id'] as num).toInt(), child: Text(m['fullname'] ?? m['username'] ?? ''));
                                    }).toList(),
                                  ],
                                  onChanged: (v) {
                                    setState(() {
                                      _filterOwnerId = v;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (ctx, idx) {
                              final nas = filtered[idx] as Map<String, dynamic>;
                              final ownerName = _ownerNameForId(nas['owner_id']);
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: ListTile(
                                  title: Text(nas['nasname'] ?? ''),
                                  subtitle: Text(
                                    'Owner: $ownerName\n'
                                    'Shortname: ${nas['shortname'] ?? 'N/A'}\n'
                                    'Type: ${nas['nas_type'] ?? 'other'}\n'
                                    'Description: ${nas['description'] ?? 'N/A'}',
                                  ),
                                  isThreeLine: true,
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.router),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _showEditDialog(nas),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _confirmDelete(nas['id']),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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
