class AppConfig {
  static const String baseUrl = 'http://66.154.127.192:5000';
  static String? authToken;
  static String? userFullName;

  static Map<String, String> get authHeaders {
    if (authToken == null) return {};
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };
  }
}