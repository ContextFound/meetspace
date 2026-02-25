/// API base URL. Change for production or use compile-time env.
const String apiBaseUrl = String.fromEnvironment(
  'MEETSPACE_API_URL',
  defaultValue: 'http://localhost:8000',
);
