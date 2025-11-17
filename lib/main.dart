import 'dart:io';
import 'dart:ui';
import 'package:clairediary/ui/routes/routes.dart';
import 'package:clairediary/Automations/claireminder.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/services/notification.dart';
import 'package:clairediary/ui/chats/chatrooms.dart';
import 'package:clairediary/ui/create_session/create_session_controller.dart';
import 'package:clairediary/ui/create_session/create_session_page.dart';
import 'package:clairediary/ui/ego-profile/profile.dart';
import 'package:clairediary/ui/featured/notified_session_details.dart';
import 'package:clairediary/ui/games/games_home.dart';
import 'package:clairediary/ui/splash_screen/splash.dart';
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
import 'package:workmanager/workmanager.dart';
import 'Admob/ad_state.dart';
import 'data/core/config.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
const simplePeriodic1HourTask =
    "be.tramckrijte.workmanagerExample.simplePeriodic1HourTask";
void callbackDispatcher() {
  DartPluginRegistrant.ensureInitialized();
  Workmanager().executeTask((task, inputData) {
    switch (task) {
      case 'claireminder': Claireminder.randomizeReminderNotes();
      break;
      case Workmanager.iOSBackgroundTask: Claireminder.randomizeReminderNotes();
      stderr.writeln("The iOS background fetch was triggered");
      break;
    }
    return Future.value(true);
  });
}

/// Receive message when the app is closed and in background.
Future<void> backgroundHandler(RemoteMessage message) async{
print(message.data.toString());
print(message.notification?.title);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initFuture = MobileAds.instance.initialize();
  final adState = AdState(initFuture);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.instance.getToken();
  FirebaseMessaging.onBackgroundMessage(backgroundHandler);
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
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
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

// This widget is the root of your application.
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  User? currentUser = FirebaseAuth.instance.currentUser;

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
        channel.id,
        channel.name,
        channelDescription: 'Notifications for Dear Claire app',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: const Color(0xFFe91e63),
        ledOnMs: 1000,
        ledOffMs: 500,
        showWhen: true,
        channelShowBadge: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: 1, // you can manage this dynamically if needed
        interruptionLevel: InterruptionLevel.active, // iOS 15+ important
        // sound can be customized with: sound: 'custom_sound.aiff',
      ),
    );
  }



  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    triggerNotifications();
    clairNotification.randomizeNewAppSessionToast();
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }




  void triggerNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Create Android notification channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request foreground notification permissions
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize notifications
    final initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload != null) {
          print('Notification tapped: $payload');
          switch (payload) {
            case 'room':
              navService.pushNamed('/diaryRooms', args: payload);
              break;
            case 'wallet':
              navService.pushNamed('/egoPage', args: payload);
              break;
            case 'claireminder':
            case 'createSession':
              navService.pushNamed('/createSession', args: payload);
              break;
            case 'game':
              navService.pushNamed('/games', args: payload);
              break;
            default:
              navService.pushNamed('/notifiedSessionDetails', args: payload);
          }
        } else {
          navService.pushNamed('/egoPage', args: payload.toString());
        }
      },
    );

    // Request iOS notification permissions
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Handle notifications when app is closed
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      final route = message?.data["route"];
      if (route != null) {
        navService.pushNamed('/' + route, args: route);
      }
    });

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final route = message.data["route"];
      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          _notificationDetails(),
          payload: route,
        );
      }
    });

    // When app is in background and user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final route = message.data["route"];
      if (route != null) {
        navService.pushNamed('/' + route, args: route);
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
            "diaryRooms": (_) => ChatRoomsPage(title: 'Dear Claire'),
            "egoPage": (_) => EgoProfilePage(title: 'Dear Claire'),

          },
          //navigatorKey: navigatorKey,
          onGenerateRoute: (RouteSettings settings) {
            switch (settings.name) {
              case '/notifiedSessionDetails':
                return MaterialPageRoute(builder: (_) => NotifiedSessionDetails(sessionId: settings.arguments.toString(),));
              case '/egoPage':
                return MaterialPageRoute(builder: (_) => EgoProfilePage(title: 'Dear Claire'));
              case '/diaryRooms':
                return MaterialPageRoute(builder: (_) => ChatRoomsPage(title: 'Dear Claire'));
              case '/createSession':
                return MaterialPageRoute(builder: (_) => CreateSessionPage());
              case '/games':
                return MaterialPageRoute(builder: (_) => GamesHome());
            }
            return AppRouter.generateRoute(settings);
          },
        ),
      ),
    );
  }
}