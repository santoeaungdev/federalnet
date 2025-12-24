/*
Owner App

Role: Owner-facing Flutter application.

Workflow & requirements:
 - Presents owner login, then owner-specific screens (wallet top-up, bind/unbind NAS, register customers).
 - Stores JWT in secure storage; includes fallback to shared_preferences if secure store unavailable.
 - Calls backend `/api/admin/*` owner-scoped endpoints; backend must enforce owner id from JWT claims.
 - Requires backend `DATABASE_URL` and `JWT_SECRET` to be configured and migrations applied.
*/

import 'package:flutter/material.dart';
import 'login_page.dart';

void main() => runApp(const OwnerApp());

class OwnerApp extends StatelessWidget {
  const OwnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'FederalNet Owner',
      home: LoginPage(role: 'owner'),
    );
  }
}
