enum Flavor {
  dev,
  prod,
}

class FlavorConfig {
  static Flavor? _flavor;

  static void initialize(Flavor flavor) {
    _flavor = flavor;
  }

  static Flavor get flavor {
    if (_flavor == null) {
      throw Exception('FlavorConfig has not been initialized. Call FlavorConfig.initialize() first.');
    }
    return _flavor!;
  }

  static bool get isDev => flavor == Flavor.dev;
  static bool get isProd => flavor == Flavor.prod;

  static String get name => flavor.toString().split('.').last;

  static String get appTitle {
    switch (flavor) {
      case Flavor.dev:
        return 'Sleep Dev';
      case Flavor.prod:
        return 'Sleep';
    }
  }

  static String get bundleId {
    switch (flavor) {
      case Flavor.dev:
        return 'com.arai.sleep.dev';
      case Flavor.prod:
        return 'com.arai.sleep';
    }
  }
}