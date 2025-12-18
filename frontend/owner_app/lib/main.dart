import 'package:flutter/material.dart';
import 'login_page.dart';

void main() => runApp(const OwnerApp());

class OwnerApp extends StatelessWidget {
  const OwnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FederalNet Owner',
      home: LoginPage(role: 'owner'),
    );
  }
}
