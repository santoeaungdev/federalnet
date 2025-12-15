import 'package:flutter/material.dart';
import 'login_page.dart';

void main() => runApp(const CustomerApp());

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FederalNet Customer',
      home: const LoginPage(),
    );
  }
}
