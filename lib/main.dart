import 'dart:async';
import 'dart:ui'; // DartPluginRegistrant is now in dart:ui
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/services/notification.dart';
import 'package:clairediary/ui/alter_ego/alter_ego_homepage.dart';
import 'package:clairediary/ui/alter_ego/chatrooms.dart';
import 'package:clairediary/ui/chats/chatrooms.dart';
import 'package:clairediary/ui/create_session/create_session_controller.dart';
import 'package:clairediary/ui/create_session/create_session_page.dart';
import 'package:clairediary/ui/ego-profile/profile.dart';
import 'package:clairediary/ui/featured/notified_session_details.dart';
import 'package:clairediary/ui/routes/routes.dart';
import 'package:clairediary/ui/splash_screen/splash.dart';
import 'package:clairediary/ui/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'Admob/ad_state.dart';
import 'Automations/auto_diary.dart';
import 'data/core/config.dart';
import 'firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode ? const AppleDebugProvider() : const AppleAppAttestProvider(),
  );

  await initializeService();
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
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  FirebaseMessaging.onBackgroundMessage(backgroundHandler);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Amsterdam'));
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

Future<void> _updateFcmTokenOnAppStart() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    print("No user logged in, skipping FCM token update on app start.");
    return;
  }
  try {
    String? newFcmToken = await FirebaseMessaging.instance.getToken();
    if (newFcmToken == null) {
      print("Could not get FCM token. Device may not support it.");
      return;
    }
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
    final userDoc = await userDocRef.get();
    if (userDoc.exists) {
      final oldFcmToken = userDoc.data()?['fcmId'] as String?;
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
  }
}

Future<void> backgroundHandler(RemoteMessage message) async {
  print(message.data.toString());
  print(message.notification?.title);
}


Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  const notificationChannelId = 'auto_diary_channel';
  const notificationId = 888;
  final channel = AndroidNotificationChannel(
    notificationChannelId,
    'Auto Diary Service',
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
      initialNotificationTitle: 'AutoDiary',
      initialNotificationContent: 'Claire is active in the background.',
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
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // This Timer needs to be accessible by all handlers.
  Timer? recordingTimer;

  // A separate Timer for the daily ritual to avoid conflicts.
  Timer? dailyRitualTimer;

  // --- Event Listeners ---

  service.on('stopService').listen((event) {
    // Cancel ALL timers when the service is stopped.
    recordingTimer?.cancel();
    dailyRitualTimer?.cancel();
    service.stopSelf();
    print("BACKGROUND_SERVICE: Service stopped, all timers cancelled.");
  });

  // This handler is UNCHANGED.
  service.on('instantRecording').listen((event) async {
    print('BACKGROUND_SERVICE: Received instantRecording event.');
    recordingTimer?.cancel();
    await AutoDiary.startRecording();
    recordingTimer = Timer(const Duration(minutes: 1), () async {
      print('BACKGROUND_SERVICE: 1-minute timer elapsed for instant session. Stopping and notifying.');
      await AutoDiary.stopRecordingAndNotify();
    });
  });

  // This handler is UNCHANGED.
  service.on('scheduleRecording').listen((event) async {
    if (event == null || event['time'] == null) return;
    recordingTimer?.cancel();
    final scheduledTime = DateTime.parse(event['time']);
    final now = DateTime.now();
    final delay = scheduledTime.difference(now);

    if (delay.isNegative) {
      print('BACKGROUND_SERVICE: One-time schedule is in the past. Ignoring.');
      return;
    }

    print('BACKGROUND_SERVICE: Received one-time schedule. Will sleep for $delay then start recording.');
    await Future.delayed(delay);

    print('BACKGROUND_SERVICE: Sleep complete. Starting one-time 12-minute recording.');
    await AutoDiary.startRecording();
    recordingTimer = Timer(const Duration(minutes: 1), () async {
      print('BACKGROUND_SERVICE: 1-minute timer elapsed for one-time session. Stopping and notifying.');
      await AutoDiary.stopRecordingAndNotify();
    });
  });

  // --- NEW: Handler for the Daily Ritual ---
  service.on('scheduleDailyRitual').listen((event) {
    if (event == null || event['hour'] == null || event['minute'] == null) return;

    // Cancel any previous daily ritual to start a new one.
    dailyRitualTimer?.cancel();
    print("BACKGROUND_SERVICE: New daily ritual received. Cancelling previous one.");

    final int hour = event['hour'];
    final int minute = event['minute'];

    // This function will calculate the next delay and schedule itself.
    void scheduleNextRitual() {
      final now = DateTime.now();
      var nextRunTime = DateTime(now.year, now.month, now.day, hour, minute);

      // If the time today has already passed, schedule for tomorrow.
      if (nextRunTime.isBefore(now)) {
        nextRunTime = nextRunTime.add(const Duration(days: 1));
      }

      final delay = nextRunTime.difference(now);
      print('BACKGROUND_SERVICE (Ritual): Next session is in $delay. Sleeping...');

      // Use the dedicated dailyRitualTimer.
      dailyRitualTimer = Timer(delay, () async {
        print('BACKGROUND_SERVICE (Ritual): Waking up! Starting daily 12-minute session.');
        await AutoDiary.startRecording();

        // This timer is for the 12-minute DURATION of the recording.
        Timer(const Duration(minutes: 1), () async {
          print('BACKGROUND_SERVICE (Ritual): 1-minute session finished.');
          await AutoDiary.stopAndSaveRecording(); // Don't notify to continue, it's a fixed ritual.

          // IMPORTANT: After saving, schedule the *next* ritual for 24 hours later.
          print('BACKGROUND_SERVICE (Ritual): Rescheduling for the next day.');
          scheduleNextRitual();
        });
      });
    }

    // Start the first ritual schedule.
    scheduleNextRitual();
  });
  // NEW: Add a handler to cancel the daily ritual
  service.on('cancelDailyRitual').listen((event) {
    dailyRitualTimer?.cancel();
    print("BACKGROUND_SERVICE: Daily ritual has been cancelled by the user.");
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
          navigatorKey: NavigationService.navigationKey,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.system,
          home: SplashPage(
            initialRemoteMessage: widget.initialRemoteMessage,
            initialLocalNotification: widget.initialLocalNotification,
          ),
          routes: {
            "create_session": (_) => CreateSessionPage(),
            "diaryRooms": (_) => ChatRoomsPage(title: 'Dear Claire'),
            "egoPage": (_) => EgoProfilePage(title: 'Dear Claire'),
            "alterEgoHomepage": (_) => AlterEgoHomePage(),
            "alterEgoDiaryRooms": (_) => ChatRooms(),
          },
          onGenerateRoute: (RouteSettings settings) {
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
