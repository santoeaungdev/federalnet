import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';

class InternetPlansListPage extends StatefulWidget {
  const InternetPlansListPage({super.key});

  @override
  State<InternetPlansListPage> createState() => _InternetPlansListPageState();
}

class _InternetPlansListPageState extends State<InternetPlansListPage> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> _plansList = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlansList();
  }

  Future<void> _loadPlansList() async {
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
      final resp = await dio.get('/admin/internet_plans');
      setState(() {
        _plansList = resp.data as List<dynamic>;
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
    final nameCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'Personal');
    final priceCtrl = TextEditingController();
    final currencyCtrl = TextEditingController(text: 'MMK');
    final validityUnitCtrl = TextEditingController(text: 'months');
    final validityValueCtrl = TextEditingController(text: '1');
    final downloadCtrl = TextEditingController(text: '10');
    final uploadCtrl = TextEditingController(text: '10');
    final radiusGroupCtrl = TextEditingController();
    final statusCtrl = TextEditingController(text: 'Active');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Internet Plan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Plan Name',
                  hintText: 'Home 10Mbps',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: categoryCtrl.text,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'Personal', child: Text('Personal')),
                  DropdownMenuItem(value: 'Business', child: Text('Business')),
                ],
                onChanged: (val) {
                  if (val != null) categoryCtrl.text = val;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  hintText: '25000',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: currencyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  hintText: 'MMK',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: validityUnitCtrl.text,
                decoration: const InputDecoration(labelText: 'Validity Unit'),
                items: const [
                  DropdownMenuItem(value: 'minutes', child: Text('Minutes')),
                  DropdownMenuItem(value: 'hours', child: Text('Hours')),
                  DropdownMenuItem(value: 'days', child: Text('Days')),
                  DropdownMenuItem(value: 'months', child: Text('Months')),
                ],
                onChanged: (val) {
                  if (val != null) validityUnitCtrl.text = val;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: validityValueCtrl,
                decoration: const InputDecoration(
                  labelText: 'Validity Value',
                  hintText: '1',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: downloadCtrl,
                decoration: const InputDecoration(
                  labelText: 'Download Speed (Mbps)',
                  hintText: '10',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: uploadCtrl,
                decoration: const InputDecoration(
                  labelText: 'Upload Speed (Mbps)',
                  hintText: '10',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: radiusGroupCtrl,
                decoration: const InputDecoration(
                  labelText: 'RADIUS Group Name',
                  hintText: 'HOME_10M',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: statusCtrl.text,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                ],
                onChanged: (val) {
                  if (val != null) statusCtrl.text = val;
                },
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
              final name = nameCtrl.text.trim();
              final radiusGroup = radiusGroupCtrl.text.trim();
              if (name.isEmpty || radiusGroup.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Plan Name and RADIUS Group are required')),
                );
                return;
              }

              Navigator.of(ctx).pop();
              await _createPlan({
                'name': name,
                'category': categoryCtrl.text,
                'price': priceCtrl.text.isEmpty ? '0' : priceCtrl.text,
                'currency': currencyCtrl.text,
                'validity_unit': validityUnitCtrl.text,
                'validity_value':
                    int.tryParse(validityValueCtrl.text) ?? 1,
                'download_mbps': int.tryParse(downloadCtrl.text) ?? 10,
                'upload_mbps': int.tryParse(uploadCtrl.text) ?? 10,
                'radius_groupname': radiusGroup,
                'status': statusCtrl.text,
              });
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createPlan(Map<String, dynamic> data) async {
    final token = await _storage.read(key: 'jwt');
    final dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      headers: {'Authorization': 'Bearer $token'},
    ));

    try {
      await dio.post('/admin/internet_plans', data: data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Internet plan created successfully')),
        );
        _loadPlansList();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to create plan: ${_describeError(e)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Internet Plans'),
        backgroundColor: Colors.green,
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
                        onPressed: _loadPlansList,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _plansList.isEmpty
                  ? const Center(child: Text('No internet plans found'))
                  : ListView.builder(
                      itemCount: _plansList.length,
                      itemBuilder: (ctx, idx) {
                        final plan = _plansList[idx] as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(plan['name'] ?? ''),
                            subtitle: Text(
                              'Category: ${plan['category']}\n'
                              'Price: ${plan['price']} ${plan['currency']}\n'
                              'Speed: ${plan['download_mbps']}/${plan['upload_mbps']} Mbps\n'
                              'Validity: ${plan['validity_value']} ${plan['validity_unit']}\n'
                              'RADIUS Group: ${plan['radius_groupname']}\n'
                              'Status: ${plan['status']}',
                            ),
                            isThreeLine: true,
                            leading: CircleAvatar(
                              backgroundColor: plan['category'] == 'Business'
                                  ? Colors.orange
                                  : Colors.blue,
                              child: const Icon(Icons.wifi, color: Colors.white),
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
