import 'dart:math' as math;

import 'package:clairediary/Automations/setup_autoDiary_widget.dart';
import 'package:clairediary/ui/routes/routes.dart';
import 'package:clairediary/utils/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../featured/notified_session_details.dart';

class SplashPage extends StatefulWidget {
  final RemoteMessage? initialRemoteMessage;
  final NotificationAppLaunchDetails? initialLocalNotification;

  const SplashPage({
    Key? key,
    this.initialRemoteMessage,
    this.initialLocalNotification,
  }) : super(key: key);

  @override
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

    // This is the single, correct place for this callback.
    // It ensures all logic runs only after the first frame is drawn.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialNotification();
    });
  }

  void _handleInitialNotification() {
    // --- Handle Remote (FCM) Notification ---
    if (widget.initialRemoteMessage != null) {
      final route = widget.initialRemoteMessage!.data["route"];
      if (route != null) {
        // We removed the nested callback. Navigation now happens directly.
        switch (route) {
        // This is the correct, unified case for both room types
          case 'diaryRooms':
          case 'alterEgoDiaryRooms':
            navService.pushReplacementNamed(
              '/$route',
              args: {
                'roomId': widget.initialRemoteMessage!.data['roomId'],
                'cornerId': widget.initialRemoteMessage!.data['cornerId'],
              },
            );
            break;

        // Redundant cases for 'diaryRooms' and 'alterEgoDiaryRooms' have been removed.

          case 'alterEgoHomepage':
            navService.pushReplacementNamed('/alterEgoHomepage');
            break;
          case 'room': // Legacy case
            navService.pushReplacementNamed('/diaryRooms');
            break;
          case 'wallet':
          case 'egoPage':
          case 'love_transfer_received':
          case 'love_transfer_sent':
            navService.pushReplacementNamed('/egoPage');
            break;
          case 'claireminder':
          case 'createSession':
            navService.pushReplacementNamed('/createSession');
            break;
          case 'game':
            navService.pushReplacementNamed('/games');
            break;
          default:
            navService.pushReplacementNamed('/notifiedSessionDetails', args: route);
        }
        // Since we handled a notification, we exit the function to prevent
        // the normal app launch animation listener from being added.
        return;
      }
    }
    // --- Handle Local Notification ---
    else if (widget.initialLocalNotification != null &&
        widget.initialLocalNotification!.didNotificationLaunchApp) {
      final payload = widget.initialLocalNotification!.notificationResponse?.payload;
      if (payload == 'auto_diary_record') {
        // No callback needed here either.
        navService.pushReplacementNamed(AppRoutes.setupAutoDiary);
        return; // Handled, so we exit.
      }
    }

    // --- NO NOTIFICATION: Proceed with normal animation-based launch ---
    // This listener is only added if no notification was handled.
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Pallet.colorPrimary,
        body: SafeArea(
          child: Center(
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
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      "By Social Faculty",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
