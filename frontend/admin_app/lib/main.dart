/*
Admin App

Role: Administrative Flutter application for SuperAdmin/Admin tasks.

Workflow & requirements:
 - Admin login -> manage customers, NAS, internet plans, owners, operators, and run income computations.
 - Uses JWT-based auth; store tokens securely using flutter_secure_storage.
 - Backend must have migrations applied (see `docs/federalnet.sql`) and appropriate admin user seeded.
*/

import 'package:flutter/material.dart';
import 'login_page.dart';

void main() => runApp(const AdminApp());

class AdminApp extends StatelessWidget {
  const AdminApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'FederalNet Admin',
      home: LoginPage(role: 'admin'),
    );
  }
}
