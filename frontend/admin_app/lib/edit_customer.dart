// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:admin_app/api/api.dart';
import 'package:admin_app/pages/home.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class EditCustomer extends StatefulWidget {
  final dynamic customer; // Received customer data

  const EditCustomer({super.key, required this.customer});

  @override
  _EditCustomerState createState() => _EditCustomerState();
}

class _EditCustomerState extends State<EditCustomer> {
  final _formKey = GlobalKey<FormState>();

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

  @override
  void initState() {
    super.initState();

    // Initialize controllers with received customer data
    _username.text = widget.customer['username'] ?? '';
    _password.text = widget.customer['password'] ?? '';

    _pppoeUsername.text = widget.customer['pppoe_username'] ?? '';
    _pppoePassword.text = widget.customer['pppoe_password'] ?? '';

    _name.text = widget.customer['name'] ?? '';
    _phone.text = widget.customer['phone'] ?? '';
    _address.text = widget.customer['address'] ?? '';
    _remark.text = widget.customer['remark'] ?? '';
    _packageName.text = widget.customer['package_name'] ?? '';
    _packagePrice.text = widget.customer['package_price'].toString();
    _serviceType.text = widget.customer['service_type'] ?? '';
    _township.text = widget.customer['township'] ?? '';
    _city.text = widget.customer['city'] ?? '';
    _status.text = widget.customer['status'] ?? '';
    _installDate.text = widget.customer['install_date'] ?? '';
    _endDate.text = widget.customer['end_date'] ?? '';

    // Keep PPPoE credentials auto-synced with username/password
    _pppoeUsername.text = _username.text;
    _pppoePassword.text = _password.text;

    _username.addListener(() {
      if (_pppoeUsername.text != _username.text) {
        _pppoeUsername.text = _username.text;
      }
    });

    _password.addListener(() {
      if (_pppoePassword.text != _password.text) {
        _pppoePassword.text = _password.text;
      }
    });
  }

  @override
  void dispose() {
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
    if (_formKey.currentState!.validate()) {
      final response = await http.post(
        Uri.parse('${API.baseUrl}/admin/customer/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': widget.customer['id'],
          'username': _username.text,
          'password': _password.text,
          'pppoe_username': _username.text,
          'pppoe_password': _password.text,
          'name': _name.text,
          'phone': _phone.text,
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
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AwesomeSnackbarContent(
              title: 'Success!',
              message: 'Customer updated successfully',
              contentType: ContentType.success,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        );
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const HomePage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AwesomeSnackbarContent(
              title: 'Error!',
              message: 'Failed to update customer: ${response.body}',
              contentType: ContentType.failure,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Customer'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
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

              _buildTextField(_name, 'Name'),
              _buildTextField(_phone, 'Phone'),
              _buildTextField(_address, 'Address'),
              _buildTextField(_remark, 'Remark'),
              _buildTextField(_packageName, 'Package Name'),
              _buildTextField(_packagePrice, 'Package Price'),
              _buildTextField(_serviceType, 'Service Type'),
              _buildTextField(_township, 'Township'),
              _buildTextField(_city, 'City'),
              _buildTextField(_status, 'Status'),
              _buildDateField(_installDate, 'Install Date'),
              _buildDateField(_endDate, 'End Date'),
              const SizedBox(height: 20),
              ElevatedButton(
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
      {bool obscureText = false, bool enabled = true}) {
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String label) {
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }
}
