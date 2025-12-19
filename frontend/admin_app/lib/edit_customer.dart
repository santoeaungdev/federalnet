import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config.dart';
import 'auth_storage.dart';

class EditCustomerPage extends StatefulWidget {
  final int customerId;
  const EditCustomerPage({super.key, required this.customerId});

  @override
  State<EditCustomerPage> createState() => _EditCustomerPageState();
}

class _EditCustomerPageState extends State<EditCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _fullname = TextEditingController();
  final _nrc = TextEditingController();
  final _nrcNumber = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _pppoeUsername = TextEditingController();
  final _pppoePassword = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final List<String> _citizenTypes = ['N', 'E', 'P'];

  List<_NrcOption> _nrcOptions = [];
  List<_NrcOption> _filteredTownships = [];
  int? _selectedStateCode;
  _NrcOption? _selectedTownship;
  String _selectedCitizen = 'N';
  bool _loading = false;
  bool _loadingNrc = false;
  bool _loadingDetail = false;
  String? _nrcLoadError;

  List<Map<String, dynamic>> _internetPlans = [];
  int? _selectedPlanId;
  bool _loadingPlans = false;

  String _describeError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final code =
        data is Map && data['error'] is String ? data['error'] as String : null;

    if (status == 401 && code == 'invalid_token') {
      return 'Session expired. Please log in again.';
    }
    if (status == 401 && (code == 'missing_token' || code == 'bad_header')) {
      return 'Authorization missing. Please log in again.';
    }
    if (status == 400 && code == 'invalid_nrc') {
      return 'NRC number is invalid. Please recheck and try again.';
    }
    if (status == 400 && code == 'username_exists') {
      return 'Username already exists. Choose another username.';
    }
    if (status == 400 && code == 'pppoe_username_exists') {
      return 'PPPoE username already exists. Choose another PPPoE username.';
    }
    if (status == 404 && code == 'not_found') {
      return 'Customer not found. Refresh the list and try again.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Check your network and retry.';
    }
    if (e.type == DioExceptionType.badResponse && status != null) {
      return 'Server error ($status). Please try again.';
    }
    return 'Network error. Please try again.';
  }

  static const Map<int, String> _stateLabels = {
    1: 'Kachin',
    2: 'Kayah',
    3: 'Kayin',
    4: 'Chin',
    5: 'Sagaing',
    6: 'Tanintharyi',
    7: 'Bago',
    8: 'Magway',
    9: 'Mandalay',
    10: 'Mon',
    11: 'Rakhine',
    12: 'Yangon',
    13: 'Shan',
    14: 'Ayeyarwady',
    15: 'Nay Pyi Taw',
  };

  @override
  void initState() {
    super.initState();
    _loadNrcOptions();
    _loadDetail();
    _loadInternetPlans();
    
    // Auto-sync PPPoE credentials with username/password
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

  @override
  void dispose() {
    _username.removeListener(_syncPPPoEUsername);
    _password.removeListener(_syncPPPoEPassword);
    _username.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _fullname.dispose();
    _nrc.dispose();
    _nrcNumber.dispose();
    _phone.dispose();
    _email.dispose();
    _pppoeUsername.dispose();
    _pppoePassword.dispose();
    super.dispose();
  }

  List<int> get _stateCodes {
    final codes = _nrcOptions.map((e) => e.nrcCode).toSet().toList();
    codes.sort();
    return codes;
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

  Future<void> _loadNrcOptions() async {
    setState(() {
      _loadingNrc = true;
      _nrcLoadError = null;
    });

    try {
      final dio = await _authedDio();
      final resp = await dio.get('/admin/nrcs');
      final raw = resp.data as List<dynamic>;
      final items = raw
          .map((e) =>
              _NrcOption.fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
          .toList();

      setState(() {
        _nrcOptions = items;
        _selectedStateCode ??= _stateCodes.isNotEmpty ? _stateCodes.first : null;
        _filteredTownships =
            _nrcOptions.where((o) => o.nrcCode == _selectedStateCode).toList();
        _selectedTownship =
            _filteredTownships.isNotEmpty ? _filteredTownships.first : null;
      });
      if (_nrc.text.isNotEmpty) {
        _applyNrcToSelectors(_nrc.text);
      }
      _refreshNrcPreview();
    } catch (e) {
      setState(() => _nrcLoadError = 'Failed to load NRC list: $e');
    } finally {
      if (mounted) setState(() => _loadingNrc = false);
    }
  }

  Future<void> _loadDetail() async {
    setState(() => _loadingDetail = true);
    try {
      final dio = await _authedDio();
      final resp = await dio.get('/admin/customers/${widget.customerId}');
      final data = Map<String, dynamic>.from(resp.data as Map);

      _username.text = data['username']?.toString() ?? '';
      _fullname.text = data['fullname']?.toString() ?? '';
      _phone.text = data['phonenumber']?.toString() ?? '';
      _email.text = data['email']?.toString() ?? '';
      _pppoeUsername.text = data['pppoe_username']?.toString() ?? '';
      final pppoePass = data['pppoe_password']?.toString() ?? '';
      _pppoePassword.text = pppoePass;
      _password.text = pppoePass;
      _confirmPassword.text = pppoePass;

      final nrcValue = data['nrc_no']?.toString() ?? '';
      _applyNrcToSelectors(nrcValue);

      // Load internet_plan_id if available
      if (data['internet_plan_id'] != null) {
        setState(() => _selectedPlanId = data['internet_plan_id'] as int?);
      }
    } on DioException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_describeError(e))));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load customer: $e')));
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  Future<void> _loadInternetPlans() async {
    setState(() => _loadingPlans = true);

    try {
      final dio = await _authedDio();
      final resp = await dio.get('/admin/internet_plans');
      final raw = resp.data as List<dynamic>;
      setState(() {
        _internetPlans = raw
            .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
            .where((plan) => plan['status'] == 'Active')
            .toList();
      });
    } catch (e) {
      // Silently fail on network/auth errors. Internet plan field is optional
      // and customer update can proceed without loading plans (using router_tag instead).
    } finally {
      if (mounted) setState(() => _loadingPlans = false);
    }
  }

  void _applyNrcToSelectors(String nrcValue) {
    _nrc.text = nrcValue;
    if (nrcValue.isEmpty) return;
    // Parse format: code/Township(Type)123456
    final parts = nrcValue.split('/');
    if (parts.length < 2) return;
    final codeDigits = parts[0].replaceAll(RegExp(r'[^0-9]'), '');
    final rest = parts[1];
    final typeMatch = RegExp(r'\(([A-Z])\)').firstMatch(rest);
    final numberMatch = RegExp(r'([0-9]{6})').firstMatch(rest);
    final township = rest.split('(').first;

    if (codeDigits.isNotEmpty) {
      _selectedStateCode = int.tryParse(codeDigits);
    }
    if (typeMatch != null) {
      _selectedCitizen = typeMatch.group(1) ?? 'N';
    }
    if (numberMatch != null) {
      _nrcNumber.text = numberMatch.group(1) ?? '';
    }

    if (_selectedStateCode != null && _nrcOptions.isNotEmpty) {
      _filteredTownships =
          _nrcOptions.where((o) => o.nrcCode == _selectedStateCode).toList();
      _NrcOption? found;
      for (final o in _filteredTownships) {
        if (o.nameEn.toLowerCase() == township.toLowerCase()) {
          found = o;
          break;
        }
      }
      _selectedTownship = found ?? (_filteredTownships.isNotEmpty ? _filteredTownships.first : null);
    }
    _refreshNrcPreview();
  }

  void _onStateChanged(int? code) {
    setState(() {
      _selectedStateCode = code;
      _filteredTownships =
          _nrcOptions.where((o) => o.nrcCode == _selectedStateCode).toList();
      _selectedTownship =
          _filteredTownships.isNotEmpty ? _filteredTownships.first : null;
    });
    _refreshNrcPreview();
  }

  void _refreshNrcPreview() {
    _nrc.text = _composeNrc() ?? '';
  }

  String? _composeNrc() {
    if (_selectedTownship == null) return null;
    final digits = _nrcNumber.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 6) return null;
    return '${_selectedTownship!.nrcCode}/${_selectedTownship!.nameEn}(${_selectedCitizen})$digits';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    final composedNrc = _composeNrc();
    if (composedNrc == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please complete NRC details (state, township, type, 6-digit no).')));
      return;
    }

    _nrc.text = composedNrc;
    setState(() => _loading = true);
    try {
      final dio = await _authedDio();
      final resp = await dio.post('/admin/customer/update',
          data: {
            'id': widget.customerId,
            'username': _username.text,
            'password': _password.text,
            'fullname': _fullname.text,
            'nrc_no': _nrc.text,
            'phonenumber': _phone.text,
            'email': _email.text,
            'service_type': 'PPPoE',
            'pppoe_username': _username.text,
            'pppoe_password': _password.text,
            'router_tag': '',
            'internet_plan_id': _selectedPlanId,
          });

      if (resp.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Customer updated')));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${resp.statusCode}')));
      }
    } on DioException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_describeError(e))));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _loadingDetail;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Customer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_loadingDetail) const LinearProgressIndicator(),
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _confirmPassword,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v != _password.text) return 'Passwords do not match';
                  return null;
                },
              ),
              TextFormField(
                controller: _fullname,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 12),
              if (_loadingNrc) const LinearProgressIndicator(),
              if (_nrcLoadError != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _nrcLoadError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _loadNrcOptions,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry loading NRC list'),
                    ),
                  ],
                ),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      value: _selectedStateCode,
                      decoration: const InputDecoration(labelText: 'nrc_code'),
                      items: _stateCodes
                          .map((code) => DropdownMenuItem(
                                value: code,
                                child: Text('$code - ${_stateLabels[code] ?? 'Code $code'}'),
                              ))
                          .toList(),
                      onChanged: _loadingNrc ? null : _onStateChanged,
                      validator: (v) => v == null ? 'Select state/region' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<_NrcOption>(
                      value: _selectedTownship,
                      decoration: const InputDecoration(labelText: 'name_en'),
                      items: _filteredTownships
                          .map((o) => DropdownMenuItem(
                                value: o,
                                child: Text('${o.nrcCode}/${o.nameEn} (${o.nameMm})'),
                              ))
                          .toList(),
                      onChanged: _loadingNrc
                          ? null
                          : (opt) {
                              setState(() => _selectedTownship = opt);
                              _refreshNrcPreview();
                            },
                      validator: (v) => v == null ? 'Select township' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCitizen,
                      decoration: const InputDecoration(labelText: 'numbertype'),
                      items: _citizenTypes
                          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedCitizen = val ?? 'N');
                        _refreshNrcPreview();
                      },
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _nrcNumber,
                      decoration: const InputDecoration(labelText: '000000'),
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => _refreshNrcPreview(),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                        if (digits.length != 6) return 'Enter 6 digits';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Example: 5/WaThaNa(N)000111'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nrc,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'NRC (formatted)'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 16),
              if (_loadingPlans)
                const LinearProgressIndicator()
              else if (_internetPlans.isNotEmpty)
                DropdownButtonFormField<int>(
                  value: _selectedPlanId,
                  decoration: const InputDecoration(
                    labelText: 'Internet Plan (optional)',
                    helperText: 'Select a plan to auto-assign RADIUS group',
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('-- No plan selected --'),
                    ),
                    ..._internetPlans.map((plan) {
                      final id = plan['id'] as int;
                      final name = plan['name'] ?? '';
                      final speed = '${plan['download_mbps']}/${plan['upload_mbps']} Mbps';
                      final price = '${plan['price']} ${plan['currency']}';
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text('$name - $speed - $price'),
                      );
                    }).toList(),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedPlanId = val);
                  },
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pppoeUsername,
                decoration: const InputDecoration(
                  labelText: 'PPPoE Username (auto-synced)',
                ),
                readOnly: true,
              ),
              TextFormField(
                controller: _pppoePassword,
                decoration: const InputDecoration(
                  labelText: 'PPPoE Password (auto-synced)',
                ),
                obscureText: true,
                readOnly: true,
              ),
              const SizedBox(height: 16),
              busy
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(onPressed: _submit, child: const Text('Update')),
            ],
          ),
        ),
      ),
    );
  }
}

class _NrcOption {
  final int id;
  final int nrcCode;
  final String nameEn;
  final String nameMm;

  _NrcOption({
    required this.id,
    required this.nrcCode,
    required this.nameEn,
    required this.nameMm,
  });

  factory _NrcOption.fromJson(Map<String, dynamic> json) {
    return _NrcOption(
      id: json['id'] as int,
      nrcCode: json['nrc_code'] as int,
      nameEn: json['name_en'] as String,
      nameMm: json['name_mm'] as String,
    );
  }
}
