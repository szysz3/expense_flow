enum Flavor { prod, demo }

class FlavorConfig {
  static Flavor? appFlavor;

  static Flavor get _flavor {
    if (appFlavor == null) {
      throw Exception(
          'Flavor not initialized. App must be started with either prod or demo flavor.');
    }
    return appFlavor!;
  }

  static String get name => _flavor.name;

  static String get title {
    switch (_flavor) {
      case Flavor.prod:
        return 'Expense Flow';
      case Flavor.demo:
        return 'Expense Flow Demo';
    }
  }

  static bool get isProd => _flavor == Flavor.prod;

  static bool get isDemo => _flavor == Flavor.demo;
}
