import 'dart:ui';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/services/notification.dart';
import 'package:clairediary/ui/chats/chatrooms.dart';
import 'package:clairediary/ui/create_session/create_session_controller.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:clairediary/ui/create_session/create_session_page.dart';
import 'package:clairediary/ui/ego-profile/profile.dart';
import 'package:clairediary/ui/featured/notified_session_details.dart';
import 'package:clairediary/ui/games/games_home.dart';
import 'package:clairediary/ui/routes/routes.dart';
import 'package:clairediary/ui/splash_screen/splash.dart';
import 'package:clairediary/ui/theme.dart';
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
import 'Automations/auto_diary_service.dart';
import 'data/core/config.dart';
import 'firebase_options.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Receive message when the app is in background/terminated.
Future<void> backgroundHandler(RemoteMessage message) async {
  print("Handling a background message: \${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // --- INITIALIZATIONS ---
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final initFuture = MobileAds.instance.initialize();
  final adState = AdState(initFuture);

  // --- GET INITIAL NOTIFICATION INFO ---
  final RemoteMessage? initialRemoteMessage =
  await FirebaseMessaging.instance.getInitialMessage();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final NotificationAppLaunchDetails? initialLocalNotification =
  await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  // --- CRASHLYTICS & FIREBASE MESSAGING SETUP ---
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  FirebaseMessaging.onBackgroundMessage(backgroundHandler);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // --- TIMEZONE & AUTO-DIARY SERVICE SETUP ---
  tz_data.initializeTimeZones();
  final AutoDiaryService autoDiaryService = AutoDiaryService();
  await autoDiaryService.init(); // This creates the 'auto_diary_channel'

  // --- APP START ---
  Config.appFlavor = Flavor.DEVELOPMENT;
  await Hive.initFlutter();
  runApp(
    Provider.value(
      value: adState,
      builder: (context, child) => MyApp(
        initialRemoteMessage: initialRemoteMessage,
        initialLocalNotification: initialLocalNotification,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final RemoteMessage? initialRemoteMessage;
  final NotificationAppLaunchDetails? initialLocalNotification;

  const MyApp({
    Key? key,
    this.initialRemoteMessage,
    this.initialLocalNotification,
  }) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  User? currentUser = FirebaseAuth.instance.currentUser;
  final c = Get.put(CreateSessionController());
  final ClairNotification clairNotification = ClairNotification();


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    clairNotification.init();
    clairNotification.randomizeNewAppSessionToast();
    // _handleInitialNotification is now handled by the SplashPage
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
        builder: (BuildContext context, child) => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Dear Claire',
          navigatorKey: NavigationService.navigationKey, // Use your global key
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.system,
          home: SplashPage(
            initialRemoteMessage: widget.initialRemoteMessage,
            initialLocalNotification: widget.initialLocalNotification,
          ),
          routes: {
            "createSession": (_) => CreateSessionPage(),
            "diaryRooms": (_) => ChatRoomsPage(title: 'Dear Claire'),
            "egoPage": (_) => EgoProfilePage(title: 'Dear Claire'),
          },
          onGenerateRoute: (RouteSettings settings) {
            switch (settings.name) {
              case '/notifiedSessionDetails':
                return MaterialPageRoute(
                    builder: (_) => NotifiedSessionDetails(
                        sessionId: settings.arguments.toString()));
              case '/egoPage':
                return MaterialPageRoute(
                    builder: (_) => EgoProfilePage(title: 'Dear Claire'));
              case '/diaryRooms':
                return MaterialPageRoute(
                    builder: (_) => ChatRoomsPage(title: 'Dear Claire'));
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
