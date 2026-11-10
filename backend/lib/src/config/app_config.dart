class AppConfig {
  final Map<String, String> environment;
  AppConfig(this.environment);
  Set<String> get corsOrigins =>
      (environment['CORS_ORIGINS'] ?? 'http://localhost:8080')
          .split(',')
          .map((s) => s.trim())
          .toSet();
}
