// @dart=2.9
import 'dart:math';

import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/services/notification.dart';
import 'package:dear_claire/ui/create_session/create_session_controller.dart';
import 'package:dear_claire/ui/create_session/create_session_page.dart';
import 'package:dear_claire/ui/routes/routes.dart';
import 'package:dear_claire/ui/splash_screen/splash.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  User currentUser = FirebaseAuth.instance.currentUser;

  //initialize controller for create session interactions
  final c = Get.put(CreateSessionController());

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      'This channel is used for important notifications.', // description
      importance: Importance.high,
      playSound: true);

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    triggerAndroidNotifications();
    randomizeNewAppSessionToast();
    clairNotification.randomizeReminderNotes();
  }


  void triggerAndroidNotifications() async {
    String _usersID = currentUser?.uid.toString();

    /// Foreground work for android
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification.android;
      if (android != null)
      {
        flutterLocalNotificationsPlugin.show(notification.hashCode,
            notification.title, notification.body, _notificationDetails());
      }
    });

    /// When android app is open in background and user taps on it.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger.d('You tapped on a new notification');
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification?.android;
      final routeForMessage = message.data["route"];
      if (notification != null && android != null) {

        logger.d(notification.toString());
        print(routeForMessage);

        navigatorKey.currentState.pushNamed(routeForMessage);

      }
    });
  }

  NotificationDetails _notificationDetails() {
    return NotificationDetails(
        android: AndroidNotificationDetails(
            channel.id, channel.name, channel.description,
            color: Pallet.colorPrimary,
            playSound: true,
            icon: '@drawable/claire_icon',
            enableLights: true,
            enableVibration: true,
            showWhen: true,
            channelShowBadge: true),
        iOS: IOSNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true));
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
          routes: {
            "createSessionPage": (_) => CreateSessionPage(),
          },
          navigatorKey: navigatorKey,
          onGenerateRoute: AppRouter.generateRoute,
        ),
      ),
    );
  }
}