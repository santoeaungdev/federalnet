// ignore_for_file: use_build_context_synchronously

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import 'config.dart';
import 'auth_storage.dart';
import 'customer_list.dart';

class EditCustomerPage extends StatefulWidget {
  final int customerId;

  const EditCustomerPage({super.key, required this.customerId});

  @override
  _EditCustomerPageState createState() => _EditCustomerPageState();
}

class _EditCustomerPageState extends State<EditCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();

  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  final TextEditingController _pppoeUsername = TextEditingController();
  final TextEditingController _pppoePassword = TextEditingController();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _remark = TextEditingController();
  final TextEditingController _packageName = TextEditingController();
  final TextEditingController _packagePrice = TextEditingController();
  final TextEditingController _serviceType = TextEditingController();
  final TextEditingController _township = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _status = TextEditingController();
  final TextEditingController _installDate = TextEditingController();
  final TextEditingController _endDate = TextEditingController();

  bool _loading = false;
  bool _loadingDetail = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();

    // Keep PPPoE credentials auto-synced with username/password
    _username.addListener(_syncPPPoEUsername);
    _password.addListener(_syncPPPoEPassword);
  }

  void _syncPPPoEUsername() {
    if (_pppoeUsername.text != _username.text) {
      _pppoeUsername.text = _username.text;
    }
  }

  void _syncPPPoEPassword() {
    if (_pppoePassword.text != _password.text) {
      _pppoePassword.text = _password.text;
    }
  }

  Future<Dio> _authedDio() async {
    var token = await _storage.read(key: 'jwt');
    token ??= await AuthStorage.readToken();
    return Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    ));
  }

  Future<void> _loadDetail() async {
    setState(() => _loadingDetail = true);
    try {
      final dio = await _authedDio();
      final resp = await dio.get('/admin/customers/${widget.customerId}');
      final data = Map<String, dynamic>.from(resp.data as Map);

      _username.text = data['username']?.toString() ?? '';
      _name.text = data['name']?.toString() ?? '';
      _phone.text = data['phonenumber']?.toString() ?? '';
      _address.text = data['address']?.toString() ?? '';
      _remark.text = data['remark']?.toString() ?? '';
      _packageName.text = data['package_name']?.toString() ?? '';
      _packagePrice.text = data['package_price']?.toString() ?? '';
      _serviceType.text = data['service_type']?.toString() ?? '';
      _township.text = data['township']?.toString() ?? '';
      _city.text = data['city']?.toString() ?? '';
      _status.text = data['status']?.toString() ?? '';
      _installDate.text = data['install_date']?.toString() ?? '';
      _endDate.text = data['end_date']?.toString() ?? '';
      
      // Load password from pppoe_password
      final pppoePass = data['pppoe_password']?.toString() ?? '';
      _password.text = pppoePass;
      
      // PPPoE fields will auto-sync via listeners
      _pppoeUsername.text = _username.text;
      _pppoePassword.text = _password.text;
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load customer: ${e.response?.statusCode ?? e.type}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load customer: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  @override
  void dispose() {
    _username.removeListener(_syncPPPoEUsername);
    _password.removeListener(_syncPPPoEPassword);
    _username.dispose();
    _password.dispose();
    _pppoeUsername.dispose();
    _pppoePassword.dispose();
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _remark.dispose();
    _packageName.dispose();
    _packagePrice.dispose();
    _serviceType.dispose();
    _township.dispose();
    _city.dispose();
    _status.dispose();
    _installDate.dispose();
    _endDate.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _updateCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final dio = await _authedDio();
      final resp = await dio.post('/admin/customer/update', data: {
        'id': widget.customerId,
        'username': _username.text,
        'password': _password.text,
        'pppoe_username': _username.text,
        'pppoe_password': _password.text,
        'name': _name.text,
        'phonenumber': _phone.text,
        'address': _address.text,
        'remark': _remark.text,
        'package_name': _packageName.text,
        'package_price': double.tryParse(_packagePrice.text) ?? 0.0,
        'service_type': _serviceType.text,
        'township': _township.text,
        'city': _city.text,
        'status': _status.text,
        'install_date': _installDate.text,
        'end_date': _endDate.text,
      });

      if (resp.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer updated successfully')),
        );
        Navigator.of(context).pop(true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${resp.statusCode}')),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.response?.statusCode ?? e.type}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _loadingDetail;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Customer'),
      ),
      body: _loadingDetail
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Existing fields
                    _buildTextField(_username, 'Username'),
                    _buildTextField(_password, 'Password', obscureText: true),

                    // PPPoE fields (auto-generated; disabled)
                    _buildTextField(
                      _pppoeUsername,
                      'PPPoE Username',
                      enabled: false,
                    ),
                    _buildTextField(
                      _pppoePassword,
                      'PPPoE Password',
                      obscureText: true,
                      enabled: false,
                    ),

                    _buildTextField(_name, 'Name', required: false),
                    _buildTextField(_phone, 'Phone', required: false),
                    _buildTextField(_address, 'Address', required: false),
                    _buildTextField(_remark, 'Remark', required: false),
                    _buildTextField(_packageName, 'Package Name', required: false),
                    _buildTextField(_packagePrice, 'Package Price', required: false),
                    _buildTextField(_serviceType, 'Service Type', required: false),
                    _buildTextField(_township, 'Township', required: false),
                    _buildTextField(_city, 'City', required: false),
                    _buildTextField(_status, 'Status', required: false),
                    _buildDateField(_installDate, 'Install Date', required: false),
                    _buildDateField(_endDate, 'End Date', required: false),
                    const SizedBox(height: 20),
                    busy
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _updateCustomer,
                            child: const Text('Update Customer'),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false, bool enabled = true, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        obscureText: obscureText,
        enabled: enabled,
        validator: required
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter $label';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String label,
      {bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context, controller),
          ),
        ),
        readOnly: true,
        validator: required
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select $label';
                }
                return null;
              }
            : null,
      ),
    );
  }
}
