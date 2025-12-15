// Central API configuration for admin_app.
// Prefer overriding via --dart-define=API_BASE_URL=... when running.

const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://143.110.185.159:8080/api',
);
