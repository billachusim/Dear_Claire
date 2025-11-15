
import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/services/notification.dart';
import 'package:dear_claire/ui/create_session/create_session_controller.dart';
import 'package:dear_claire/ui/routes/routes.dart';
import 'package:dear_claire/ui/splash_screen/splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
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
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => FirebaseServices()),
        ChangeNotifierProvider(create: (_) => CreateSessionController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Dear Claire',
        theme: ThemeData(
          primarySwatch: Colors.pink,
        ),
        home: const SplashPage(),
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
