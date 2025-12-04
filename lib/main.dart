import 'dart:async';
import 'dart:ui';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/services/notification.dart';
import 'package:clairediary/ui/alter_ego/alter_ego_homepage.dart';
import 'package:clairediary/ui/alter_ego/chatrooms.dart';
import 'package:clairediary/ui/chats/chatrooms.dart';
import 'package:clairediary/ui/create_session/create_session_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:flutter_background_service/flutter_background_service.dart';
import 'Admob/ad_state.dart';
import 'Automations/auto_diary.dart';
import 'data/core/config.dart';
import 'firebase_options.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure and start the service from main()
  await initializeService();

  // --- STANDARD INITIALIZATIONS ---
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _updateFcmTokenOnAppStart();
  final initFuture = MobileAds.instance.initialize();
  final adState = AdState(initFuture);
  await initFuture;

  MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(testDeviceIds: ['51F4CA28BB7EDD1F5E61C5F0F8EFFF00']),
  );

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

  // --- TIMEZONE & HIVE SETUP ---
  tz_data.initializeTimeZones();
  Config.appFlavor = Flavor.DEVELOPMENT;
  await Hive.initFlutter();

  // --- APP START ---
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



/// Checks for a logged-in user and updates their FCM token in Firestore if needed.
/// This ensures existing users get a token and all users have the latest one.
Future<void> _updateFcmTokenOnAppStart() async {
  // Wait until Firebase is initialized.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  User? currentUser = FirebaseAuth.instance.currentUser;

  // Only proceed if a user is actually logged in.
  if (currentUser == null) {
    print("No user logged in, skipping FCM token update on app start.");
    return;
  }

  try {
    // 1. Get the latest token from the device.
    String? newFcmToken = await FirebaseMessaging.instance.getToken();
    if (newFcmToken == null) {
      print("Could not get FCM token. Device may not support it.");
      return;
    }

    // 2. Get the user's current document from Firestore.
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
    final userDoc = await userDocRef.get();

    if (userDoc.exists) {
      final oldFcmToken = userDoc.data()?['fcmId'] as String?;

      // 3. Compare the new token with the old one. If different or missing, update it.
      if (oldFcmToken == null || oldFcmToken.isEmpty || oldFcmToken != newFcmToken) {
        print("FCM token is new or outdated. Updating in Firestore...");
        await userDocRef.update({'fcmId': newFcmToken});
        print("FCM token successfully updated for user ${currentUser.uid}.");
      } else {
        print("FCM token is already up-to-date.");
      }
    }
  } catch (e) {
    print("Error updating FCM token on app start: $e");
    // This process should not block the app from starting.
  }
}





/// Receive message when the app is closed and in background.
Future<void> backgroundHandler(RemoteMessage message) async{
  print(message.data.toString());
  print(message.notification?.title);
}


Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const notificationChannelId = 'auto_diary_channel';
  const notificationId = 888;
  final channel = AndroidNotificationChannel(
    notificationChannelId, 'Auto Diary Service',
    description: 'This channel is used for the Auto Diary background service.',
    importance: Importance.low,
  );
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'Auto Diary',
      initialNotificationContent: 'Ready and waiting.',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: (ServiceInstance service) async {
        return true;
      },
    ),
  );

  service.startService();
}








@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // This timer will control the recording duration.
  Timer? recordingTimer;

  // Listen for the 'stopService' event to clean up resources.
  service.on('stopService').listen((event) {
    recordingTimer?.cancel(); // Cancel any active timer.
    AutoDiary.stopRecording(); // Ensure any active recording is stopped and processed.
    service.stopSelf(); // Stop the background service itself.
  });

  // Listen for the 'startRecording' event from your UI.
  service.on('startRecording').listen((event) async {
    print('BACKGROUND_SERVICE: Received startRecording event.');

    // Start the recording immediately.
    await AutoDiary.startRecording();

    // Cancel any previous timer to avoid overlapping recordings.
    recordingTimer?.cancel();

    // Schedule the stop command to run after 15 seconds.
    recordingTimer = Timer(const Duration(seconds: 15), () async {
      print('BACKGROUND_SERVICE: 15-second timer elapsed. Stopping recording.');
      await AutoDiary.stopRecording();
    });
  });
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
    clairNotification.randomizeReminderNotes();
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
            "alterEgoHomepage": (_) => AlterEgoHomePage(),
            "alterEgoDiaryRooms": (_) => ChatRooms(),
          },
          onGenerateRoute: (RouteSettings settings) {
            // The AppRouter class already handles all named routes.
            // We only need to handle special cases here.
            switch (settings.name) {
              case '/notifiedSessionDetails':
                return MaterialPageRoute(
                    builder: (_) => NotifiedSessionDetails(
                        sessionId: settings.arguments.toString()));
              default:
                return AppRouter.generateRoute(settings);
            }
          },

        ),
      ),
    );
  }
}
