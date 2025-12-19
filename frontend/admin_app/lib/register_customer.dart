import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';

class RegisterCustomerPage extends StatefulWidget {
  const RegisterCustomerPage({super.key});

  @override
  State<RegisterCustomerPage> createState() => _RegisterCustomerPageState();
}

class _RegisterCustomerPageState extends State<RegisterCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _fullname = TextEditingController();
  final _nrc = TextEditingController();
  final _nrcNumber = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final List<String> _citizenTypes = ['N', 'E', 'P'];

  List<_NrcOption> _nrcOptions = [];
  List<_NrcOption> _filteredTownships = [];
  int? _selectedStateCode;
  _NrcOption? _selectedTownship;
  String _selectedCitizen = 'N';
  bool _loading = false;
  bool _loadingNrc = false;
  String? _nrcLoadError;

  List<Map<String, dynamic>> _internetPlans = [];
  int? _selectedPlanId;
  bool _loadingPlans = false;

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
    _loadInternetPlans();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _fullname.dispose();
    _nrc.dispose();
    _nrcNumber.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  List<int> get _stateCodes {
    final codes = _nrcOptions.map((e) => e.nrcCode).toSet().toList();
    codes.sort();
    return codes;
  }

  Future<void> _loadNrcOptions() async {
    setState(() {
      _loadingNrc = true;
      _nrcLoadError = null;
    });

    final token = await _storage.read(key: 'jwt');
    final dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    ));

    try {
      final resp = await dio.get('/admin/nrcs');
      final raw = resp.data as List<dynamic>;
      final items = raw
          .map((e) =>
            _NrcOption.fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
          .toList();

      setState(() {
        _nrcOptions = items;
        _selectedStateCode ??= _stateCodes.isNotEmpty ? _stateCodes.first : null;
        _filteredTownships = _nrcOptions
            .where((o) => o.nrcCode == _selectedStateCode)
            .toList();
        _selectedTownship = _filteredTownships.isNotEmpty ? _filteredTownships.first : null;
      });
      _refreshNrcPreview();
    } catch (e) {
      setState(() => _nrcLoadError = 'Failed to load NRC list: $e');
    } finally {
      if (mounted) setState(() => _loadingNrc = false);
    }
  }

  void _onStateChanged(int? code) {
    setState(() {
      _selectedStateCode = code;
      _filteredTownships = _nrcOptions
          .where((o) => o.nrcCode == _selectedStateCode)
          .toList();
      _selectedTownship = _filteredTownships.isNotEmpty ? _filteredTownships.first : null;
    });
    _refreshNrcPreview();
  }

  void _refreshNrcPreview() {
    _nrc.text = _composeNrc() ?? '';
  }

  Future<void> _loadInternetPlans() async {
    setState(() => _loadingPlans = true);

    final token = await _storage.read(key: 'jwt');
    final dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    ));

    try {
      final resp = await dio.get('/admin/internet_plans');
      final raw = resp.data as List<dynamic>;
      setState(() {
        _internetPlans = raw
            .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
            .where((plan) => plan['status'] == 'Active')
            .toList();
      });
    } catch (e) {
      // Silently fail on network/auth errors. Internet plan selection is optional
      // and customer registration can proceed without it (using router_tag instead).
    } finally {
      if (mounted) setState(() => _loadingPlans = false);
    }
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please complete NRC details (state, township, type, 6-digit no).')));
      return;
    }

    _nrc.text = composedNrc;
    setState(() => _loading = true);
    final token = await _storage.read(key: 'jwt');
    final dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ));
    try {
      final headers = <String, String>{};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      final resp = await dio.post('/admin/customer/register',
          data: {
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
          },
          options: Options(headers: headers));

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Customer created')));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${resp.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Customer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(onPressed: _submit, child: const Text('Create')),
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
