// Central API configuration for customer_app.
// Override via --dart-define=API_BASE_URL=... when running/building.

const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://143.110.185.159:8080/api',
);
