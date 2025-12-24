import 'dart:convert';
import 'auth_storage.dart';

Future<Map<String, dynamic>?> parseJwtPayload() async {
  final token = await AuthStorage.readToken();
  if (token == null) return null;
  final parts = token.split('.');
  if (parts.length < 2) return null;
  final payload = parts[1];
  final normalized = base64Url.normalize(payload);
  final decoded = utf8.decode(base64Url.decode(normalized));
  return json.decode(decoded) as Map<String, dynamic>;
}

Future<String?> getRole() async {
  final p = await parseJwtPayload();
  if (p == null) return null;
  final r = p['role'];
  if (r is String) return r.toLowerCase();
  return null;
}

Future<int?> getSub() async {
  final p = await parseJwtPayload();
  if (p == null) return null;
  final sub = p['sub'];
  if (sub is int) return sub;
  if (sub is String) return int.tryParse(sub);
  return null;
}
