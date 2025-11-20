import 'dart:math' as math;

import 'package:clairediary/ui/routes/routes.dart';
import 'package:clairediary/utils/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../Automations/auto_diary_recorder_page.dart';
import '../featured/notified_session_details.dart';

class SplashPage extends StatefulWidget {
  final RemoteMessage? initialRemoteMessage;
  final NotificationAppLaunchDetails? initialLocalNotification;

  const SplashPage({
    Key? key,
    this.initialRemoteMessage,
    this.initialLocalNotification,
  }) : super(key: key);

  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 1))
          ..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialNotification();
    });
  }

  void _handleInitialNotification() {
    if (widget.initialRemoteMessage != null) {
      final route = widget.initialRemoteMessage!.data["route"];
      if (route != null) {
        // Use pushReplacement to prevent the splash screen from being on the back stack.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => NotifiedSessionDetails(
              sessionId: route,
            ),
          ),
        );
        return; // We handled a notification, so we're done.
      }
    } else if (widget.initialLocalNotification != null) {
      final payload =
          widget.initialLocalNotification!.notificationResponse?.payload;
      if (payload == 'auto_diary_record') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => AutoDiaryRecorderPage()),
        );
        return; // We handled a notification, so we're done.
      }
    }

    // If there was no notification, proceed with the regular splash screen animation.
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallet.colorPrimary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, child) {
                    return Transform.rotate(
                      angle: _controller.value * 1 * math.pi,
                      child: child,
                    );
                  },
                  child: Image.asset(
                    "assets/images/claire_icon.png",
                    height: 120,
                    width: 120,
                  ),
                ),
              ),
              Text("By Social Faculty", style: TextStyle(color: Colors.white),)
            ],
          ),
        ),
      ),
    );
  }
}
