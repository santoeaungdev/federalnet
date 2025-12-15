import 'package:flutter/material.dart';
import 'login_page.dart';

void main() => runApp(const AdminApp());

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FederalNet Admin',
      home: LoginPage(role: 'admin'),
    );
  }
}
