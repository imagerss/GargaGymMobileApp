class AppConfig {
  const AppConfig({
    this.apiBaseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000/api',
    ),
    this.deviceName = const String.fromEnvironment(
      'DEVICE_NAME',
      defaultValue: 'gargagym-mobile',
    ),
  });

  final String apiBaseUrl;
  final String deviceName;
}
