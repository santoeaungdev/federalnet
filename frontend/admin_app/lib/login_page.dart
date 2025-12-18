import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'register_customer.dart';
import 'config.dart';
import 'customer_list.dart';

class LoginPage extends StatefulWidget {
  final String role; // 'admin' or 'owner'
  const LoginPage({super.key, required this.role});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _loading = false;

  String _describeError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final code =
        data is Map && data['error'] is String ? data['error'] as String : null;

    if (status == 401 && code == 'invalid_credentials') {
      return 'Invalid username or password. Please try again.';
    }
    if (status == 401 && code == 'inactive_admin') {
      return 'This account is inactive. Contact support for access.';
    }
    if (status == 401 && code == 'invalid_token') {
      return 'Session expired. Please log in again.';
    }
    if (status == 400 && code != null) {
      return 'Request error: $code';
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ));
    try {
      final resp = await dio.post('/admin/login', data: {
        'username': _usernameCtl.text,
        'password': _passwordCtl.text,
      });
      if (resp.statusCode == 200) {
        final adminData = resp.data['admin'];
        final userType =
            adminData is Map<String, dynamic> ? adminData['user_type'] : null;
        final role = userType?.toString().toLowerCase();
        const allowedRoles = {'admin', 'operator', 'superadmin'};
        if (role == null || !allowedRoles.contains(role)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This account is not allowed in Admin app.')),
          );
          return;
        }
        final token = resp.data['token'] ?? resp.data['access_token'];
        if (token != null) await _storage.write(key: 'jwt', value: token);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => const _HomeScreen(),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${resp.statusCode}')));
      }
    } on DioException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_describeError(e))));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Login error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.role.toUpperCase()} Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameCtl,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text('Login'),
                    ),
              const SizedBox(height: 16),
              const Text(
                'developed by santoeaung',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Logged in — placeholder dashboard'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const RegisterCustomerPage(),
                ));
              },
              child: const Text('Register Customer'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const CustomerListPage(),
                ));
              },
              child: const Text('View Customers'),
            ),
          ],
        ),
      ),
    );
  }
}
