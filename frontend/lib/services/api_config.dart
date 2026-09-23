class ApiConfig {
  static const baseUrl = String.fromEnvironment('API_BASE_URL');
  static bool get enabled => baseUrl.trim().isNotEmpty;
}
