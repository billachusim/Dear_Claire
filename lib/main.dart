// @dart=2.9
import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/services/notification.dart';
import 'package:dear_claire/ui/chats/chatrooms.dart';
import 'package:dear_claire/ui/create_session/create_session_controller.dart';
import 'package:dear_claire/ui/create_session/create_session_page.dart';
import 'package:dear_claire/ui/ego/ego.dart';
import 'package:dear_claire/ui/featured/notified_session_details.dart';
import 'package:dear_claire/ui/routes/routes.dart';
import 'package:dear_claire/ui/splash_screen/splash.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'Admob/ad_state.dart';
import 'data/core/config.dart';
import 'firebase_options.dart';

/// Receive message when the app is closed and in background.
Future<void> backgroundHandler(RemoteMessage message) async{
print(message.data.toString());
print(message.notification.title);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initFuture = MobileAds.instance.initialize();
  final adState = AdState(initFuture);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(backgroundHandler);
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

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  User currentUser = FirebaseAuth.instance.currentUser;

  //initialize controller for create session interactions
  final c = Get.put(CreateSessionController());

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'socialfaculty', // id
      'Social Faculty Channel', // title
      importance: Importance.max,
      playSound: true);


  NotificationDetails _notificationDetails() {
    return NotificationDetails(
        android: AndroidNotificationDetails(
            channel.id, channel.name,
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


  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    triggerAndroidNotifications();
    triggerIosNotifications();
    clairNotification.randomizeNewAppSessionToast();
    clairNotification.randomizeReminderNotes();
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }





  void triggerAndroidNotifications() async {

    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: AndroidInitializationSettings("@drawable/claire_icon"),
      iOS: IOSInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false,
      ),
    );

    flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: (String payload) async {
      print(payload);
      if(payload == 'room'){
        navService.pushNamed('/diaryRooms', args: payload);
      }
      else
        navService.pushNamed('/notifiedSessionDetails', args: payload);


    });

    ///Get the message user is going to tap when app is closed
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      String route = message.data["route"];
      if (route == 'room') {
        navService.pushNamed('/diaryRooms', args: route);
      }
      else
        navService.pushNamed('/notifiedSessionDetails', args: route);
    });

    /// Foreground work for android
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification.android;
      String route = message.data["route"];
      if (android != null)
      {
        flutterLocalNotificationsPlugin.show(notification.hashCode,
            notification.title, notification.body, _notificationDetails(), payload: route);
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

        if (routeForMessage == 'room') {
          navService.pushNamed('/diaryRooms', args: routeForMessage);
        }
        else
          navService.pushNamed('/notifiedSessionDetails', args: routeForMessage);
      }
    });
  }



  void triggerIosNotifications() async {

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    final InitializationSettings initializationSettings =
    InitializationSettings(
      iOS: IOSInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false,
      ),
      android: AndroidInitializationSettings("@drawable/claire_icon"),
    );


    flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: (String payload) async {
      print(payload);
      if(payload == 'room'){
        navService.pushNamed('/diaryRooms', args: payload);
      }
      else
        navService.pushNamed('/notifiedSessionDetails', args: payload);


    });

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }



    ///Get the message user is going to tap when app is closed
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      String route = message.data["route"];
      if (route == 'room') {
        navService.pushNamed('/diaryRooms', args: route);
      }
      else
        navService.pushNamed('/notifiedSessionDetails', args: route);
    });


    /// Foreground work for iOS
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification;
      AppleNotification apple = message.notification.apple;
      String route = message.data["route"];
      if (apple != null)
      {
        flutterLocalNotificationsPlugin.show(notification.hashCode,
            notification.title, notification.body, _notificationDetails(), payload: route);
      }
    });


    /// When iOS app is open in background and user taps on it.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger.d('You tapped on a new notification!');
      RemoteNotification notification = message.notification;
      AppleNotification apple = message.notification?.apple;
      final routeForMessage = message.data["route"];
      if (notification != null && apple != null) {

        logger.d(notification.toString());
        print(routeForMessage);

        if (routeForMessage == 'room') {
          navService.pushNamed('/diaryRooms', args: routeForMessage);
        }
        else
          navService.pushNamed('/notifiedSessionDetails', args: routeForMessage);
      }
    });
  }





  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [Provider(create: (_) => FirebaseServices())],
      child: ScreenUtilInit(
        designSize: Size(360, 640),
        builder: (BuildContext context, child) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Dear Claire',
          navigatorKey: NavigationService.navigationKey,
          theme: ThemeData(
            primarySwatch: Colors.pink,
          ),
          home: SplashPage(),
          routes: {
            "createSession": (_) => CreateSessionPage(),
            "diaryRooms": (_) => ChatRoomsPage(),
          },
          //navigatorKey: navigatorKey,
          onGenerateRoute: (RouteSettings settings) {
            switch (settings.name) {
              case '/notifiedSessionDetails':
                return MaterialPageRoute(builder: (_) => NotifiedSessionDetails(sessionId: settings.arguments,));
              case '/egoPage':
                return MaterialPageRoute(builder: (_) => EgoPage());
              case '/diaryRooms':
                return MaterialPageRoute(builder: (_) => ChatRoomsPage());
            }
            return AppRouter.generateRoute(settings);
          },
        ),
      ),
    );
  }
}