
import 'package:clairediary/data/core/network_config.dart';

enum Flavor {
  DEVELOPMENT,
  RELEASE,
}

class Config {
  static Flavor? appFlavor;

  static String get BASEURL {
    switch (appFlavor) {
      case Flavor.RELEASE:
        return NetworkConfig.BASE_URL;
      case Flavor.DEVELOPMENT:
      default:
        return '';
    }
  }
}