import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';



class AdState {
  Future<InitializationStatus> initialization;

  AdState(this.initialization);


  // Create interstitial ad unit whenever a session is created.
  String get newSessionInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/3729355238";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/7377790353";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  // Create interstitial ad unit whenever clairevatar is changed.
  String get newClairevatarInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/4264541851";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/9032269917";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  // Create interstitial ad unit whenever ego name is changed.
  String get newEgoNameInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/9680520067";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/7910759937";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  // Create interstitial ad unit whenever a mantra is created.
  String get newMantraInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/2338869057";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/5936716173";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  // Create interstitial ad unit whenever there is switch to alter ego mode.
  String get switchAlterEgoInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/6086542379";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/3502124527";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  // Create interstitial ad unit whenever there is switch to ego mode.
  String get switchEgoInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/2704048173";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/3076363512";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  // Create Ego Mode top of comments banner ad unit.
  String get egoModeTopCommentBannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/8935194851";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/5702526856";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }



  // Create Ego Mode bottom of comments banner ad unit.
  String get egoModeBottomCommentBannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/8003588268";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/8328690192";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  // Create Custom Post Detail top banner ad unit.
  String get customPostDetailTopBannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/4802053317";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/9671236615";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }



  // Create Custom Post Detail bottom banner ad unit.
  String get customPostDetailBottomBannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/9662378196";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/8474253752";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }



  // Create Alter Ego Mode top of comments banner ad unit.
  String get alterEgoModeTopCommentBannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/7208052352";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/5597804828";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  // Create Alter Ego Mode bottom of comments banner ad unit.
  String get alterEgoModeBottomCommentBannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/3108153109";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/5098277225";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }



  // Create Chatroom top of comments banner ad unit.
  String get insideChatroomTopBannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/9642644003";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/1739231110";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }



  // Create Chatroom bottom of comments banner ad unit.
  String get insideChatroomBottomBannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/5759788055";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/7432742624";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }


  // Create Search Page middle banner ad unit.
  String get searchPageMiddleBannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/8518647487";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/9617721138";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }


  // Create Search Page bottom banner ad unit.
  String get searchPageBottomBannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/4579402470";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/1575579580";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }



}