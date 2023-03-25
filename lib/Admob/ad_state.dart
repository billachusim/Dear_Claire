import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';



class AdState {
  Future<InitializationStatus> initialization;

  AdState(this.initialization);



  // Create interstitial ad unit whenever a user logs in.
  String get loginInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/7375897682";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/9223046415";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  // Create interstitial ad unit whenever a user signs up.
  String get signUpInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/6980026455";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/1979266624";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }


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

  // Create Category Sessions top banner ad unit.
  String get categorySessionTopBannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/7327058503";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/9379610422";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  // Create Tictactoe top banner ad unit.
  String get tictactoeTopBannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/4239180954";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/3116018582";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  // Create Mood Sessions top banner ad unit.
  String get moodSessionTopBannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/6013976836";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/7874957062";
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
      return "ca-app-pub-2404156870680632/3238400649";
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



  // Create Inside Inside Chatroom top of comments banner ad unit.
  String get insideInsideChatroomTopBannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/8362815330";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/1534231843";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }



  // Create Chatroom bottom of comments banner ad unit.
  String get insideInsideChatroomBottomBannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/9484325310";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/4504010119";
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

  // Create Search Page middle banner ad unit.
  String get searchPageMiddleBannerAdUnitId2 {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/1791012053";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/4503099019";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }


  // Create Search Page bottom banner ad unit.
  String get searchPageBottomBannerAdUnitId2 {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/9286358697";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/7590133648";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }


  // Create Visited User top of sessions banner ad unit.
  String get visitedUserTopOfSessionBannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/7804329017";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/9364026532";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }



  // Create Visited User bottom of sessions banner ad unit.
  String get visitedUserBottomOfSessionsBannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/1841555895";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/6546291501";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }



  // Create visited user top of activities banner ad unit.
  String get visitedUserTopOfActivitiesBannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/9028984611";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/7015412402";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }



  // Create visited user bottom of activities banner ad unit.
  String get visitedUserBottomOfActivitiesBannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/1150494592";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/4256800395";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }



  // Create ego page top of activities banner ad unit.
  String get egoPageTopOfActivitiesBannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/9028984611";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/7015412402";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }



  // Create ego page bottom of activities banner ad unit.
  String get egoPageBottomOfActivitiesBannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-2404156870680632/1150494592";
    } else if (Platform.isIOS) {
      return "ca-app-pub-2404156870680632/4256800395";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }



}