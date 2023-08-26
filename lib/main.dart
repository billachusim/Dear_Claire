import 'dart:io';
import 'dart:ui';
import 'package:dear_claire/Automations/claireminder.dart';
import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/services/notification.dart';
import 'package:dear_claire/ui/chats/chatrooms.dart';
import 'package:dear_claire/ui/create_session/create_session_controller.dart';
import 'package:dear_claire/ui/create_session/create_session_page.dart';
import 'package:dear_claire/ui/ego-profile/profile.dart';
import 'package:dear_claire/ui/featured/notified_session_details.dart';
import 'package:dear_claire/ui/games/games_home.dart';
import 'package:dear_claire/ui/routes/routes.dart';
import 'package:dear_claire/ui/splash_screen/splash.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
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

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: AndroidInitializationSettings("@drawable/claire_icon"),
      iOS: IOSInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false,
          onDidReceiveLocalNotification: (id, title, body, payload) async {
            print('onDidReceiveLocalNotification: $id, $title, $body, $payload');
            showDialog(
              context: context,
              builder: (BuildContext context) => CupertinoAlertDialog(
                title: Text(title!),
                content: Text(body!),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: Text('Ok'),
                    onPressed: () async {
                      Navigator.of(context, rootNavigator: true).pop();
                      if (payload != null){
                      print(payload);
                      if(payload == 'room') {
                      navService.pushNamed('/diaryRooms', args: payload);
                      }
                      else if(payload == 'wallet') {
                      navService.pushNamed('/egoPage', args: payload);
                      }
                      else if(payload == 'claireminder') {
                      navService.pushNamed('/createSession', args: payload);
                      }
                      else if(payload == 'game') {
                        navService.pushNamed('/games', args: payload);
                      }
                      else if(payload == 'createSession') {
                      navService.pushNamed('/createSession', args: payload);
                      }
                      else if(payload == null) {
                      navService.pushNamed('/createSession', args: payload);
                      }
                      else                    navService.pushNamed('/notifiedSessionDetails', args: payload);

                      }
                      else navService.pushNamed('/egoPage', args: payload!);
                    },
                  )
                ],
              ),
            );
          }
      ),
    );


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


    await flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings("@drawable/claire_icon"),
        iOS: IOSInitializationSettings(
            onDidReceiveLocalNotification: (id, title, body, payload) async {
              print('onDidReceiveLocalNotification: $id, $title, $body, $payload');
              showDialog(
                context: context,
                builder: (BuildContext context) => CupertinoAlertDialog(
                  title: Text(title!),
                  content: Text(body!),
                  actions: [
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      child: Text('Ok'),
                      onPressed: () async {
                        Navigator.of(context, rootNavigator: true).pop();
                        if (payload != null){
                          print(payload);
                          if(payload == 'room') {
                            navService.pushNamed('/diaryRooms', args: payload);
                          }
                          else if(payload == 'wallet') {
                            navService.pushNamed('/egoPage', args: payload);
                          }
                          else if(payload == 'claireminder') {
                            navService.pushNamed('/createSession', args: payload);
                          }
                          else if(payload == 'game') {
                            navService.pushNamed('/games', args: payload);
                          }
                          else if(payload == 'createSession') {
                            navService.pushNamed('/createSession', args: payload);
                          }
                          else if(payload == null) {
                            navService.pushNamed('/createSession', args: payload);
                          }
                          else
                            navService.pushNamed('/notifiedSessionDetails', args: payload);

                        }
                        else navService.pushNamed('/egoPage', args: payload!);
                      },
                    )
                  ],
                ),
              );
            }),
      ),
    );


    flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: (String? payload) async {
      if (payload != null){
        print(payload);
        if(payload == 'room') {
          navService.pushNamed('/diaryRooms', args: payload);
        }
        else if(payload == 'wallet') {
          navService.pushNamed('/egoPage', args: payload);
        }
        else if(payload == 'claireminder') {
          navService.pushNamed('/createSession', args: payload);
        }
        else if(payload == 'game') {
          navService.pushNamed('/games', args: payload);
        }
        else if(payload == 'createSession') {
          navService.pushNamed('/createSession', args: payload);
        }
        else if(payload == null) {
          navService.pushNamed('/createSession', args: payload);
        }
        else        navService.pushNamed('/notifiedSessionDetails', args: payload);

      }
      else navService.pushNamed('/egoPage', args: payload!);
    });



    ///Get the message user is going to tap when app is closed
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      RemoteNotification? notification = message?.notification;
      String route = message?.data["route"];
      if (notification != null) {
        if(route == 'room') {
          navService.pushNamed('/diaryRooms', args: route);
        }
        else if(route == 'wallet') {
          navService.pushNamed('/egoPage', args: route);
        }
        else if(route == 'claireminder') {
          navService.pushNamed('/createSession', args: route);
        }
        else if(route == 'game') {
          navService.pushNamed('/games', args: route);
        }
        else if(route == 'createSession') {
          navService.pushNamed('/createSession', args: route);
        }
        else if(route == null) {
          navService.pushNamed('/createSession', args: route);
        }
        else        navService.pushNamed('/notifiedSessionDetails', args: route);

      }
      else navService.pushNamed('/egoPage', args: route);
    });




    /// Foreground work for notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      String route = message.data["route"];
      flutterLocalNotificationsPlugin.show(notification.hashCode,
          notification?.title, notification?.body, _notificationDetails(), payload: route);
    });




    /// When app is open in background and user taps on it.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger.d('You tapped on a new notification');
      RemoteNotification? notification = message.notification;
      final route = message.data["route"];
      if (notification != null) {

        logger.d(notification.toString());
        print(route);

        if(route == 'room') {
          navService.pushNamed('/diaryRooms', args: route);
        }
        else if(route == 'wallet') {
          navService.pushNamed('/egoPage', args: route);
        }
        else if(route == 'claireminder') {
          navService.pushNamed('/createSession', args: route);
        }
        else if(route == 'game') {
          navService.pushNamed('/games', args: route);
        }
        else if(route == 'createSession') {
          navService.pushNamed('/createSession', args: route);
        }
        else if(route == null) {
          navService.pushNamed('/createSession', args: route);
        }
        else if(route != null) {
          navService.pushNamed('/notifiedSessionDetails', args: route);
        }
      }
      else navService.pushNamed('/egoPage', args: route);

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