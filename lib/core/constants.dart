/// App-wide constants for the Dropzy customer app.
class AppConfig {
  AppConfig._();

  /// Same Go backend the admin panel + official app talk to (EC2 Mumbai).
  /// Override: flutter run --dart-define=API_URL=https://api.dropzy.in/api/v1
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://18.60.129.43:8080/api/v1',
  );

  static const String appName = 'Dropzy';
  static const String tagline = 'Send parcels across cities';

  /// Demo OTP accepted by the reference build ("Try 1234 for the demo").
  static const String demoOtp = '1234';

  // Persisted keys
  static const String kAccessToken = 'accessToken';
  static const String kRefreshToken = 'refreshToken';
  static const String kMobile = 'mobile';
}
