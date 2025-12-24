// Customer App
//
// Role: Customer-facing Flutter application.
//
// Workflow & requirements:
//  - Customer login -> view balance, purchase plans using wallet, see active plan and usage.
//  - Uses JWT auth stored securely on device; interacts with `/api/customer/*` and wallet purchase endpoints.
//  - Backend must expose purchase endpoints and have owner/customer wallets configured for purchases.

import 'package:flutter/material.dart';
import 'login_page.dart';

void main() => runApp(const CustomerApp());

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'FederalNet Customer',
      home: LoginPage(),
    );
  }
}
