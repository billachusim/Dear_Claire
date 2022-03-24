// @dart=2.9
import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/services/notification.dart';
import 'package:dear_claire/ui/create_session/create_session_controller.dart';
import 'package:dear_claire/ui/routes/routes.dart';
import 'package:dear_claire/ui/splash_screen/splash.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    //FirebaseCrashlytics.instance.crash();
    super.initState();
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
          //AuthSelectionPage(), FirstoreTest(),
          onGenerateRoute: AppRouter.generateRoute,
        ),
      ),
    );
  }
}