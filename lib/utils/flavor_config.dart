/// Flavor configuration for different build environments
class FlavorConfig {
  static const String _currentFlavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  /// Check if the app is running in development mode
  static bool get isDev => _currentFlavor == 'dev';

  /// Check if the app is running in production mode
  static bool get isProd => _currentFlavor == 'prod';

  /// Get the current flavor name
  static String get flavorName => _currentFlavor;

  /// Check if debug features should be enabled
  static bool get isDebugMode => isDev;
}