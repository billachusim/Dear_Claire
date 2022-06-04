// @dart=2.9
import 'dart:math';

import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/services/notification.dart';
import 'package:dear_claire/ui/create_session/create_session_controller.dart';
import 'package:dear_claire/ui/routes/routes.dart';
import 'package:dear_claire/ui/splash_screen/splash.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'Admob/ad_state.dart';
import 'data/core/config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initFuture = MobileAds.instance.initialize();
  final adState = AdState(initFuture);

  await Firebase.initializeApp();
  await clairNotification.initializeNotification();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  Config.appFlavor = Flavor.DEVELOPMENT;
  await Hive.initFlutter();
  runApp(
      Provider.value(
        value: adState,
        builder: (context, child) => MyApp(),
      ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

// This widget is the root of your application.
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  //initialize controller for create session interactions
  final c = Get.put(CreateSessionController());

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    randomizeNewAppSessionToast();
    randomizeSecondAppSessionToast();
    clairNotification.triggerReminder();
  }


  randomizeNewAppSessionToast() async {
    Random random = new Random();
    int randomNumber = random.nextInt(Constant.TOAST_NUMBERS.length);
    var message = randomNumber == 1 ? "It's Claire O'clock!" :
    randomNumber == 2 ? "I'm glad you are here" :
    randomNumber == 3 ? "You have come to a safe place." :
    randomNumber == 4 ? "Grow your ego." :
    randomNumber == 5 ? "Positive vibes only." :
    randomNumber == 5 ? "Let's have a heart to heart." :
    randomNumber == 6 ? "Go ahead, advise anonymously." :
    randomNumber == 7 ? "Welcome to Featured Sessions" :
    randomNumber == 8 ? "Different people, different situations." :
    randomNumber == 9 ? "You'll never be not truly loved." :
    randomNumber == 10 ? "A problem shared is..." :
    randomNumber == 11 ? "You are completely anonymous." :
    randomNumber == 12 ? "Advise people positively." :
    randomNumber == 13 ? "Tap the spinning flower anytime." :
    randomNumber == 14 ? "It's you and me time." :
    randomNumber == 15 ? "Bored? Check out Diary Rooms." :
    randomNumber == 16 ? "Browse Love and other categories." :
    randomNumber == 17 ? "Be ready to be nice." :
    randomNumber == 18 ? "Ask Claire anything." :
    randomNumber == 19 ? "Don't forget to show love." :

    "It's Claire O'Clock!";
    await  Future.delayed(Duration(seconds: 6), () {
      Fluttertoast.showToast(
        toastLength: Toast.LENGTH_LONG,
        msg: message.toString(),
        textColor: Colors.white,
        backgroundColor: Pallet.colorSplashScreen,
      );    });
  }


  randomizeSecondAppSessionToast() async {
    Random random = new Random();
    int randomNumber = random.nextInt(Constant.TOAST_NUMBERS.length);
    var message = randomNumber == 1 ? "Go on, Darling, talk to me..." :
    randomNumber == 2 ? "I'm glad you are here" :
    randomNumber == 3 ? "You have come to a safe place." :
    randomNumber == 4 ? "Everything can be between us." :
    randomNumber == 5 ? "I'll always be here for you." :
    randomNumber == 5 ? "Let's have a heart to heart." :
    randomNumber == 6 ? "Go ahead, type or record anything." :
    randomNumber == 7 ? "Tell me what's happening, darling?" :
    randomNumber == 8 ? "Where are you and what's going on?" :
    randomNumber == 9 ? "You'll never be not truly loved." :
    randomNumber == 10 ? "A problem shared is..." :
    randomNumber == 11 ? "You are completely anonymous." :
    randomNumber == 12 ? "Write or record anything." :
    randomNumber == 13 ? "Tap the spinning flower after." :
    randomNumber == 14 ? "It's you and me time." :
    randomNumber == 15 ? "Start with Dear Claire" :
    randomNumber == 16 ? "Tap record and say Dear Claire" :
    randomNumber == 17 ? "I'm ready to listen." :
    randomNumber == 18 ? "I'm ready to read, listen and reply." :
    randomNumber == 19 ? "If you don't tell me, I won't know." :

    "Go on, Darling, talk to me...";
    await  Future.delayed(Duration(seconds: 100), () {
      Fluttertoast.showToast(
        toastLength: Toast.LENGTH_LONG,
        msg: message.toString(),
        textColor: Colors.white,
        backgroundColor: Pallet.colorSplashScreen,
      );    });
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [Provider(create: (_) => FirebaseServices())],
      child: ScreenUtilInit(
        designSize: Size(360, 640),
        builder: () => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Dear Claire',
          theme: ThemeData(
            primarySwatch: Colors.pink,
          ),
          home: SplashPage(),
          //AuthSelectionPage(), FirestoreTest(),
          onGenerateRoute: AppRouter.generateRoute,
        ),
      ),
    );
  }
}