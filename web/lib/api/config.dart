/// API base URL. Change for production or use compile-time env.
const String apiBaseUrl = String.fromEnvironment(
  'MEETSPACE_API_URL',
  defaultValue: 'http://127.0.0.1:8000',
);
