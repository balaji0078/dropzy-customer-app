/// App-wide constants for the Dropzy customer app.
class AppConfig {
  AppConfig._();

  /// Same Go backend the admin panel + official app talk to (EC2 Mumbai).
  /// Override: flutter run --dart-define=API_URL=https://api.dropzy.in/api/v1
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://16.112.168.63:8080/api/v1',
  );

  /// `--dart-define=CORE_API=true` switches the whole app to the PRD v2.0
  /// core contract (CLIENT_CONTRACTS.md §1–§2): only core endpoints are
  /// called, money/payment state comes only from the server and tokens live
  /// in secure storage. When false (default) the legacy demo app runs
  /// unchanged so existing builds keep working.
  static const bool coreApi = bool.fromEnvironment('CORE_API');

  /// `--dart-define=DEMO_MODE=true` re-enables demo-only affordances (demo
  /// OTP hint / dev OTP echo). Never shows simulate/advance controls when
  /// [coreApi] is true.
  static const bool demoMode = bool.fromEnvironment('DEMO_MODE');

  /// Scheme + host + port of [apiBaseUrl], e.g. `http://10.0.2.2:8080`.
  /// Server paths such as `checkoutPath` and evidence `downloadUrl` are joined
  /// with this origin.
  static String get apiOrigin => Uri.parse(apiBaseUrl).origin;

  /// Deep link the hosted checkout returns to (CLIENT_CONTRACTS.md C8).
  static const String paymentReturnUrl = 'dropzy://payments/return';

  static const String appName = 'Dropzy';
  static const String tagline = 'Send parcels across cities';

  /// Demo OTP accepted by the reference build ("Try 1234 for the demo").
  static const String demoOtp = '1234';

  // Persisted keys
  static const String kAccessToken = 'accessToken';
  static const String kRefreshToken = 'refreshToken';
  static const String kMobile = 'mobile';
  static const String kDeviceId = 'deviceId';
}
