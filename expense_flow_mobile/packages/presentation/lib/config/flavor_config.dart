enum Flavor { prod, demo }

class FlavorConfig {
  static Flavor? appFlavor;

  static String get name {
    if (appFlavor == null) {
      throw Exception(
          'Flavor not initialized. App must be started with either prod or demo flavor.');
    }
    return appFlavor!.name;
  }

  static String get title {
    switch (appFlavor) {
      case Flavor.prod:
        return 'Expense Flow';
      case Flavor.demo:
        return 'Expense Flow Demo';
      case null:
        throw Exception(
            'Flavor not initialized. App must be started with either prod or demo flavor.');
    }
  }

  static bool get isProd {
    if (appFlavor == null) {
      throw Exception(
          'Flavor not initialized. App must be started with either prod or demo flavor.');
    }
    return appFlavor == Flavor.prod;
  }

  static bool get isDemo {
    if (appFlavor == null) {
      throw Exception(
          'Flavor not initialized. App must be started with either prod or demo flavor.');
    }
    return appFlavor == Flavor.demo;
  }
}
