import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'dart:async';
import 'package:clairediary/ui/ego-profile/top_up_loves_page.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:rxdart/rxdart.dart';
import 'package:clairediary/ui/alter_ego/alter_ego_calls_page.dart'; // For IncomingCall model
import 'package:clairediary/ui/call/incoming_call_page.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clairediary/widgets/drawer_transactions_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/ui/chats/chatrooms.dart';
import 'package:clairediary/ui/dairy/diary.dart';
import 'package:clairediary/ui/ego-profile/profile.dart';
import 'package:clairediary/ui/featured/featured_session_screen.dart';
import 'package:clairediary/ui/followed/followed.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:clairediary/ui/splash_screen/rotate_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shake/shake.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import '../../Automations/setup_autoDiary_widget.dart';
import '../../helpers/toast_helper.dart';
import '../../services/firebase_services.dart';
import '../../services/notification_service.dart';
import '../../services/user_model.dart';
import '../../utils/helper.dart';
import '../../widgets/pre_call_dialog.dart';
import '../call/companion_call_page.dart';
import '../call/live_call_page.dart';
import '../love_store/love_store_page.dart';
import '../routes/page_router_animation.dart';
import '../visited_user_ego_page/visited_user_ego_page.dart';
import 'destination.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../data/models/transaction_model.dart' as t_model;

class HomePage extends StatefulWidget {
  @override
  _HomeDashboardPageState createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomePage>
    with TickerProviderStateMixin<HomePage>, WidgetsBindingObserver {
  var currentUser = FirebaseAuth.instance.currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final WebViewController _webViewController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  OverlayEntry? _overlayEntry;
  bool _isFabMenuOpen = false;
  final GlobalKey _fabKey = GlobalKey();
  late ShakeDetector detector;
  String filePath = 'assets/web_games/tictactoe/index2.html';
  String tweets = 'assets/tweet/index.html';
  int _currentIndex = 0;
  late String _title;
  String userName = "";
  String userType = "";
  String avatarUrl = "";
  bool isWon = false;
  int _playerScore = 0;
  int _claireScore = 0;
  int _drawCount = 0;
  bool _isHandlingOutcome = false;
  StreamSubscription? _userCallListener;
  String? _activeCallId;
  late Future<UserModel?> _egoInfoFuture;
  Timer? _flowerTimer;
  static bool _hasRandomizedInitialPage = false;
  late final ScrollController _featuredScrollController;

  void _showFallingFlowers() {
    // A single claire flower emoji
    const flowerEmoji = '🌺';

    final options = ConfettiOptions(
      particleCount: 1, // Only one flower at a time
      spread: 20,         // A bit of horizontal spread
      startVelocity: 10,  // How fast it starts
      gravity: 0.1,       // Makes it fall slowly
      ticks: 6000,         // How long it stays on screen to reach the bottom
      colors: [const Color(0xffffffff)], // Base color, not used by emoji
    );

    // Launch from Top Center
    Confetti.launch(
      context,
      options: options.copyWith(x: 0.5, y: -0.1, angle: 270), // Start above the screen, angle down
      particleBuilder: (index) => Emoji(
        emoji: flowerEmoji,
        textStyle: const TextStyle(
            fontSize: 28,
          color: Color.fromRGBO(255, 255, 255, 0.2),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
      // App is visible and running: Start a new timer if one isn't active.
        if (_flowerTimer == null || !_flowerTimer!.isActive) {
          _flowerTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
            if (mounted) {
              _showFallingFlowers();
            }
          });
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      // App is not visible: Cancel the timer to stop flowers from piling up.
        _flowerTimer?.cancel();
        break;
      case AppLifecycleState.hidden:
        _flowerTimer?.cancel();
    }
  }



  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 15),
    vsync: this,
  )..repeat(reverse: true);

  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticOut,
  );

  PageController _pageController = PageController(initialPage: 0);

  late List<Widget> _body;



  /// Checks if the user's premium subscription is expired and shows a renewal modal.
  void _checkAndPromptForRenewal(UserModel user) {
    // The smart condition: user was premium, but the expiry date has passed.
    final bool wasPremium = user.isPremium;
    final DateTime? expiryDate = user.premiumExpiryDate?.toDate();
    final bool isExpired = expiryDate != null && expiryDate.isBefore(DateTime.now());

    if (wasPremium && isExpired) {
      // Use a short delay to ensure the home page UI has settled.
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _showRenewSubscriptionModal();
        }
      });
    }
  }

  /// Displays a bottom sheet prompting the user to renew their subscription.
  void _showRenewSubscriptionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Pallet.colorSecondaryDark,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Pallet.colorPrimary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 24),
                Icon(
                  Icons.star_purple500_sharp,
                  color: Colors.amberAccent.withOpacity(0.7),
                  size: 50,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Premium Has Expired',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Renew now to continue enjoying an ad-free experience, monthly loves, and all-access features!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the modal
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const TopUpLovesPage(
                          feature: 'renew_subscription',
                        ),
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Pallet.colorSecondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'Renew Now',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the modal
                  },
                  child: const Text(
                    'Maybe Later',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  /// Get the Ego User info
  Future<UserModel?> getEgoInfo() async {
    // Null check at the beginning
    if (currentUser == null) {
      logger.w("getEgoInfo called with null user. Aborting.");
      return null;
    }
    final String? userId = currentUser?.uid;

    try {
      DocumentSnapshot response = await FirebaseFirestore.instance
          .collection(AppString.users)
          .doc(userId)
          .get();
      if (response.exists && response.data() != null) {
        var egoInfo =
            UserModel.fromFirestore(response.data() as Map<String, dynamic>);

        _checkAndPromptForRenewal(egoInfo);

        if (mounted) {
          setState(() {
            userName = egoInfo.nickname.toString();
            userType = egoInfo.userType.toString();
            avatarUrl = egoInfo.avatarUrl.toString();
          });
        }
        final _userId = egoInfo.userId.toString();
        await firebaseServices.updateUserLastTimeUnlocked(_userId);
        return egoInfo;
      } else {
        logger.w("User document not found for userId: $userId");
        return null;
      }
    } catch (e) {
      logger.e("Error in getEgoInfo: $e");
      return null; // Return null on error
    }
  }

  /// Get user detail for language/translation sake.
  Future<void> _updateLanguagePreference() async {
    if (currentUser != null) {
      // 1. Fetch user data from Firestore
      var userModel = await firebaseServices.getUserInfo();

        // Get device language
        final deviceLanguageCode = Platform.localeName.split('_').first;

        // Update the model in memory immediately for the UI
        userModel.languagePreference = deviceLanguageCode;

        // Asynchronously update Firestore in the background
        FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .set({'languagePreference': deviceLanguageCode}, SetOptions(merge: true));

        logger.d("Set language preference for existing user: $deviceLanguageCode");
    }
  }

  void _toggleFabMenu() {
    if (_isFabMenuOpen) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    } else {
      _overlayEntry = _createFabMenuOverlay();
      Overlay.of(context).insert(_overlayEntry!);
    }
    setState(() {
      _isFabMenuOpen = !_isFabMenuOpen;
    });
  }

  OverlayEntry _createFabMenuOverlay() {
    final RenderBox renderBox =
        _fabKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => _FabMenuOverlay(
        parentContext: this.context,
        fabSize: size,
        fabOffset: offset,
        onClose: _toggleFabMenu,
      ),
    );
  }

  launchEmailApp() {
    String? encodeQueryParameters(Map<String, String> params) {
      return params.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
    }

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'dearclaireapp@gmail.com',
      query: encodeQueryParameters(
          <String, String>{'subject': 'Questions About Dear Claire'}),
    );

    launchUrl(emailLaunchUri);
  }

  _loadHtmlFromAssets() async {
    String fileHtmlContents = await rootBundle.loadString(filePath);

    // Creating a Uri with the correct format for the loadRequest
    final uri = Uri.dataFromString(
      fileHtmlContents,
      mimeType: 'text/html',
      encoding: Encoding.getByName('utf-8'),
    );

    // Load the Uri directly
    _webViewController.loadRequest(uri);
  }

  void setTabIndex(int index) {
    // If the "Featured" tab is tapped and it's already the current index...
    if (index == 0 && _currentIndex == 0) {
      // ...and the controller is attached to a scroll view...
      if (_featuredScrollController.hasClients) {
        // ...scroll to the top.
        _featuredScrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
      return;
    }
    setState(() {
      _title = allDestinations[index].title;
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }


  void _listenForCallsFromClaire() {
    _userCallListener?.cancel();
    if (currentUser == null) return;

    final userId = currentUser!.uid;
    const statusToListenFor = 'dialing';

    // Define the streams for dialing calls
    Stream<QuerySnapshot> audioCallsStream = FirebaseFirestore.instance
        .collection('companion_calls')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: statusToListenFor)
        .snapshots();

    Stream<QuerySnapshot> videoCallsStream = FirebaseFirestore.instance
        .collection('live_sessions')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: statusToListenFor)
        .snapshots();

    _userCallListener = Rx.combineLatest2(
      audioCallsStream,
      videoCallsStream,
      (QuerySnapshot audio, QuerySnapshot video) =>
          [...audio.docs, ...video.docs],
    ).listen((callDocs) {
      // If there are no incoming calls, reset our active call tracker and do nothing.
      if (callDocs.isEmpty) {
        _activeCallId = null;
        return;
      }

      // Get the first incoming call document.
      final newCallDoc = callDocs.first;

      // --- THE DEFINITIVE FIX ---
      // If we are already showing an incoming call screen for this specific call,
      // or for any other call, do absolutely nothing.
      if (_activeCallId != null && _activeCallId == newCallDoc.id) {
        return;
      }
      if (_activeCallId != null && _activeCallId != newCallDoc.id) {
        // This case is for when a second call comes in while the first is ringing.
        // For now we ignore it, but in the future you could show a notification.
        return;
      }
      // --- END FIX ---

      // If we are here, it means this is a new call we haven't handled yet.
      // Set the active call ID immediately to prevent race conditions.
      _activeCallId = newCallDoc.id;

      final callData = newCallDoc.data() as Map<String, dynamic>;
      final isVideo = callData['type'] == 'video';
      final incomingCall = IncomingCall(doc: newCallDoc, isVideoCall: isVideo);

      // Navigate and wait for the entire call flow to complete.
      Navigator.of(context, rootNavigator: true)
          .push(
        MaterialPageRoute(
          builder: (context) => IncomingCallPage(call: incomingCall),
        ),
      )
          .then((_) {
        // This 'then' block runs when the call is over (or declined).
        // We can now safely reset the active call ID to allow new calls.
        _activeCallId = null;
      });
    });
  }

  void _initializeServices() {
    if (currentUser != null) {
      setState(() {
        _egoInfoFuture = getEgoInfo();
        _updateLanguagePreference();
      });
      shakeDevice();
      _listenForCallsFromClaire();
      firebaseServices.subscribeToAdminNotifications();
    }
    AppTrackingTransparency.requestTrackingAuthorization();
  }

  @override
  void initState() {
    super.initState();
    _featuredScrollController = ScrollController();

    _body = [
      FeaturedPage(title: 'Dear Claire', scrollController: _featuredScrollController),
      FollowedPage(title: 'Dear Claire'),
      DiaryPage(title: 'Dear Claire'),
      ChatRoomsPage(title: 'Dear Claire'),
      EgoProfilePage(title: 'Dear Claire'),
    ];

    _title = "Dear Claire";
    int initialPage = 0;
    if (currentUser != null && !_hasRandomizedInitialPage) {
      initialPage = Random().nextInt(5);
      _hasRandomizedInitialPage = true;
    }
    _currentIndex = initialPage;
    _pageController = PageController(initialPage: initialPage, keepPage: true);

    _flowerTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _showFallingFlowers();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeServices();
      }
    });
    // Initialize WebViewController for TicTacToe
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
    // --- CHANNEL 1: VIBRATION ---
      ..addJavaScriptChannel(
        'Vibration',
        onMessageReceived: (JavaScriptMessage message) async {
          if (await Vibration.hasVibrator()) {
            Vibration.vibrate(duration: 200);
          }
        },
      )
    // --- CHANNEL 2: SOUND ---
      ..addJavaScriptChannel(
        'Sound',
        onMessageReceived: (JavaScriptMessage message) async {
          if (message.message == 'win') {
            try {
              if (_audioPlayer.playing) await _audioPlayer.stop();
              await _audioPlayer.setAsset('assets/audio/win_sound.mp3');
              _audioPlayer.play();
            } catch (e) {
              print("Error playing win sound: $e");
            }
          }
        },
      )
    // --- CHANNEL 3: SCORE & GAME LOGIC ---
      ..addJavaScriptChannel(
        'Score',
        onMessageReceived: (JavaScriptMessage message) {
          // Immediately exit if an outcome is already being processed.
          if (!mounted || _isHandlingOutcome) return;

          if (message.message == 'player_wins') {
            setState(() => _playerScore++);
          } else if (message.message == 'claire_wins') {
            setState(() => _claireScore++);
          } else if (message.message == 'draw') {
            // Set the lock and update the UI in a single atomic call.
            setState(() {
              _isHandlingOutcome = true;
              _drawCount++;
            });

            // Call the reward function and reset the lock upon completion.
            _handleDrawReward().whenComplete(() {
              if (mounted) {
                setState(() {
                  _isHandlingOutcome = false;
                });
              }
            });
          }
        },
      );

    // Load drawer quick tac toe
    _loadHtmlFromAssets();
  }


  Future<void> _handleDrawReward() async {
    if (currentUser == null) return;
    const int rewardAmount = 2;

    // 1. Credit the user with 2 Loves
    final bool wasApproved = await firebaseServices.updateTreasuryAndUser(
      userId: currentUser!.uid,
      amount: rewardAmount,
      type: t_model.TransactionType.credit,
      userTransactionDescription:
          "$rewardAmount❤️ won from a Tic-Tac-Toe draw.",
      metadata: {'game': 'tic-tac-toe', 'reason': 'player_draw'},
      fromGameWins: rewardAmount,
    );

    if (!wasApproved) {
      showToast(message: "Draw! Your 2❤️ reward is pending admin approval.");
      return;
    }

    // 2. Save User Activity for the Draw
    try {
      await firebaseServices.saveUserActivity(
        activityType: 'game_draw', // A specific type for draws
        activityMessage:
            'You had a draw with Claire in Tic-Tac-Toe and earned 2❤️.',
        // No recipientId needed as it's a system transaction
      );
      logger.d("User activity for 'game_draw' saved successfully.");
    } catch (e) {
      print("Failed to save 'Game Draw' user activity: $e");
    }

    // 3. Send the targeted notification for the draw
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (userDoc.exists) {
        final userToken = userDoc.data()?['fcmId'] as String?;
        if (userToken != null && userToken.isNotEmpty) {
          await notificationService.sendNotification({
            "token": userToken,
            "notification": {
              "title": 'It\'s a Draw!',
              "body": "Well played! You earned 2❤️ from your draw with Claire."
            },
            "data": {"route": "wallet"} // Navigate user to wallet
          });
        }
      }
    } catch (e) {
      print("Failed to send 'Game Draw' push notification: $e");
    }

    // 4. Give immediate feedback to the user
    showToast(message: "It's a draw! You earned 2❤️.");
  }

  void shakeDevice() {
    detector = ShakeDetector.autoStart(
      shakeThresholdGravity: 5.5,
      onPhoneShake: (ShakeEvent event) {
        () async {
          if (!mounted) return;

          if (await Vibration.hasVibrator()) {
            Vibration.vibrate();
          }

          String id = await sharedPreference.getAlterEgoId();
          String accessCode = await sharedPreference.getAlterEgoAccessCode();

          if (!mounted) return;

          // --- FIX: Only gatekeep if they DON'T have credentials yet ---
          if (id.isEmpty || accessCode.isEmpty) {
            UserModel user = await firebaseServices.getUserInfo();
            // If they are "broke" and haven't set up an Alter Ego, send to Top Up
            if ((user.currentLoveCount ?? 0) < 2000) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const TopUpLovesPage(feature: 'alterego'),
                  ));
              return;
            }

            // If they have loves but no credentials, send to Login/Setup
            Navigator.of(context).pushNamed(
              AppRoutes.alterEgoLogin,
            );
            return;
          }

          // --- If credentials exist, proceed directly ---
          Fluttertoast.showToast(
            toastLength: Toast.LENGTH_LONG,
            msg: "Switching Ego",
            textColor: Colors.white,
            backgroundColor: Pallet.colorSplashScreen,
          );

          await firebaseServices.getUserAlterEgo(context, id, accessCode);
        }();
      },
      minimumShakeCount: 1,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _flowerTimer?.cancel();
    detector.stopListening();
    if (_isFabMenuOpen) {
      _overlayEntry?.remove();
    }
    _userCallListener?.cancel();
    _audioPlayer.dispose();
    _pageController.dispose();
    _featuredScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Pallet.colorPrimary,
        centerTitle: false,
        title: Text(_title,
            textAlign: TextAlign.start,
            maxLines: 1,
            style: GoogleFonts.lato(
                fontSize: 25.0,
                color: Colors.white,
                fontWeight: FontWeight.w600)),
        actions: [
          CupertinoButton(
              child: RotationTransition(
                turns: _animation,
                child: Icon(
                  Icons.travel_explore,
                  color: Pallet.colorWhite,
                  size: 35,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.searchPage);
              })
        ],
        leading: IconButton(
            icon: Icon(Icons.menu, color: Pallet.colorWhite, size: 25),
            onPressed: () {
              getEgoInfo();
              _openEndDrawer();
            }),
      ),
      body: Stack(children: [
        PageView(
            physics: NeverScrollableScrollPhysics(),
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: _body),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Pallet.colorBottomNav,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
        iconSize: 22,
        selectedFontSize: 0,
        unselectedFontSize: 0,
        onTap: (int index) => setTabIndex(index),
        items: allDestinations.map((Destination destination) {
          return BottomNavigationBarItem(
              icon: SvgPicture.asset(
                destination.icon,
              ),
              activeIcon: SvgPicture.asset(
                destination.activeIcon,
              ),
              backgroundColor: destination.color,
              label: destination.title);
        }).toList(),
      ),
      // Replace the existing floatingActionButton property in the Scaffold
      floatingActionButton: FloatingActionButton(
        key: _fabKey, // Key to find the FAB's position
        heroTag: "fab",
        backgroundColor: Pallet.colorSplashScreen,
        onPressed: _toggleFabMenu, // Triggers our custom menu
        tooltip: 'Start a new session',
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(child: child, scale: animation);
          },
          child: _isFabMenuOpen
              ? Icon(Icons.close, key: ValueKey('close_icon'), size: 30)
              : RotateImage(45, 45),
        ),
      ),

      drawer: _AppDrawer(
        userName: userName,
        userType: userType,
        avatarUrl: avatarUrl,
        lockAlertDialog: () => lockAlertDialog(context),
        onAlterEgoTapped: () async {
          String id = await sharedPreference.getAlterEgoId();
          String accessCode = await sharedPreference.getAlterEgoAccessCode();

          if (id.isNotEmpty && accessCode.isNotEmpty) {
            // User already has access, skip gate
            await firebaseServices.getUserAlterEgo(context, id, accessCode);
          } else {
            // User needs to unlock/login
            UserModel user = await firebaseServices.getUserInfo();
            if ((user.currentLoveCount ?? 0) < 2000) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const TopUpLovesPage(feature: 'alterego'),
                  ));
            } else {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.alterEgoLogin,
                (Route<dynamic> route) => false,
              );
            }
          }
        },
        sendClaireToSomeone: sendClaireToSomeone,
        launchEmailApp: launchEmailApp,
        isUserSignedIn: () => firebaseServices.isUserSignIn(context),
        ticTacToeController: _webViewController,
        playerScore: _playerScore,
        claireScore: _claireScore,
        drawCount: _drawCount,
      ),
    );
  }

  void _openEndDrawer() {
    _scaffoldKey.currentState!.openDrawer();
  }

  lockAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Ego Profile"),
      onPressed: () {
        String thisEgoName = "Guest View Of Your Ego";
        String? thisUser = currentUser?.uid.toString();
        PageRouter.gotoWidget(
            VisitedUserEgoProfilePage(
                visitedUsersID: thisUser.toString(),
                visitedEgoName: thisEgoName),
            context);
        print("Visited User ID::: $thisEgoName");
      },
    );

    Widget continueButton = TextButton(
      child: Text("Lock Out."),
      onPressed: () {
        firebaseServices.logUserOut(context);
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Lock Diary Or Visit Your Ego Profile?"),
      content: Text(AppString.lock_out_ego_alert_note),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}

// lib/ui/bottom_nav/stack_index_home.dart

// (Paste this entire block at the end of the file, replacing the old _AppDrawer)

class _AppDrawer extends StatefulWidget {
  final String userName;
  final String userType;
  final String avatarUrl;
  final VoidCallback lockAlertDialog;
  final VoidCallback onAlterEgoTapped;
  final VoidCallback sendClaireToSomeone;
  final VoidCallback launchEmailApp;
  final Future<bool> Function() isUserSignedIn;
  final WebViewController ticTacToeController;
  final int playerScore;
  final int claireScore;
  final int drawCount;

  const _AppDrawer({
    Key? key,
    required this.userName,
    required this.userType,
    required this.avatarUrl,
    required this.lockAlertDialog,
    required this.onAlterEgoTapped,
    required this.sendClaireToSomeone,
    required this.launchEmailApp,
    required this.isUserSignedIn,
    required this.ticTacToeController,
    required this.playerScore,
    required this.claireScore,
    required this.drawCount,
  }) : super(key: key);

  @override
  State<_AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<_AppDrawer> {
  late final AudioPlayer _audioPlayer;
  bool _isGameRewardProcessed = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

// Add the JavaScript channel for sound here
    widget.ticTacToeController.addJavaScriptChannel(
      'Sound',
      onMessageReceived: (JavaScriptMessage message) async {
        if (message.message == "win") {
          try {
            if (_audioPlayer.playing) {
              await _audioPlayer.stop();
            }
            await _audioPlayer.setAsset('assets/audio/win_sound.mp3');
            await _audioPlayer.seek(Duration.zero);
            _audioPlayer.play();
          } catch (e) {
            print("Error playing sound in drawer: $e");
          }
        }
      },
    );

// Trigger Claire's first move
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.ticTacToeController.runJavaScript('claireMakesFirstMove()');
      }
    });
  }

  @override
  void didUpdateWidget(covariant _AppDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the score has changed and trigger the game result logic
    if (widget.playerScore != oldWidget.playerScore ||
        widget.claireScore != oldWidget.claireScore) {
      _handleGameResult();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Pallet.colorPrimary,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildDrawerHeader(context),
              const SizedBox(height: 10),
              _buildTicTacToeGame(context),
              const SizedBox(height: 10),
              _buildMenuList(context),
              _buildRecentTransactions(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return UserAccountsDrawerHeader(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Pallet.colorPrimary,
      ),
      accountEmail: const Text(
        "You'll never be not truly loved.",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontStyle: FontStyle.italic,
          shadows: [Shadow(blurRadius: 2, color: Colors.black87)],
        ),
      ),
      accountName: Text(
        widget.userName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
        ),
      ),
      currentAccountPicture: GestureDetector(
        onTap: widget.lockAlertDialog,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  spreadRadius: 2,
                  blurRadius: 6)
            ],
          ),
          child: CachedNetworkImage(
            imageUrl: widget.avatarUrl,
            imageBuilder: (context, imageProvider) =>
                CircleAvatar(backgroundImage: imageProvider),
            placeholder: (context, url) =>
                const CircularProgressIndicator(color: Colors.white),
            errorWidget: (context, url, error) => const CircleAvatar(
                backgroundImage:
                    AssetImage("assets/images/Speak_No_Evil_Monkey_Emoji.png")),
          ),
        ),
      ),
      otherAccountsPictures: [
        GestureDetector(
          onTap: widget.onAlterEgoTapped,
          child: Column(
            //mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/claire_icon.png",
                  height: 25, width: 25),
              Text(
                "Switch",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Pallet.colorWhite.withValues(alpha: 0.95),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTicTacToeGame(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 25),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Quick Tac Toe",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 8),
          _buildScoreboard(context),
          const SizedBox(height: 12),
          _buildGameProgressBar(),
          const SizedBox(height: 4),
          _buildMilestoneMarkers(),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: WebViewWidget(controller: widget.ticTacToeController),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameProgressBar() {
    // Calculate the progress based on the player's score, capping at 20.
    double progress = (widget.playerScore / 20).clamp(0.0, 1.0);

    return Container(
      height: 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.transparent,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
        ),
      ),
    );
  }

  Widget _buildMilestoneMarkers() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _milestoneWidget("10 Wins = ", "50 ❤️"),
          _milestoneWidget(
            "20 Wins = ",
            "100 ❤️",
          ),
        ],
      ),
    );
  }

  Widget _milestoneWidget(String title, String subtitle) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.greenAccent,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreboard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _scorePillar('You', widget.playerScore, Colors.white),
          Text('vs',
              style: GoogleFonts.lato(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          _scorePillar('Claire', widget.claireScore, Colors.white),
        ],
      ),
    );
  }

  Widget _scorePillar(String label, int score, Color labelColor) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.montserrat(
                color: labelColor, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('$score',
            style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildMenuList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          _MenuTile(
              title: "How Claire Works",
              icon: Icons.info_rounded,
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.howClaireWorks)),
          _MenuTile(
              title: "Alter Ego Mode",
              icon: Icons.star_rounded,
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.howAlterEgoWorks)),
          _MenuTile(
              title: "Auto Diary Mode",
              icon: Icons.auto_awesome_motion_rounded,
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.setupAutoDiary);
              }),
          ListTile(
            leading: Icon(Icons.storefront, color: Pallet.colorWhite),
            title: Text('Buy Things With Love',
                style: TextStyle(color: Pallet.colorWhite)),
            onTap: () {
              Navigator.pop(context);
              PageRouter.gotoWidget(LoveStorePage(), context);
            },
          ),
          _MenuTile(
            title: "Top-Up Love/Go Premium",
            icon: Icons.card_giftcard,
            onTap: () {
              Navigator.pop(context);
              PageRouter.gotoWidget(TopUpLovesPage(), context);
            },
          ),
          _MenuTile(
            title: "More Games With Claire",
            icon: Icons.gamepad_rounded,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(AppRoutes.games);
            },
          ),
          ListTile(
            leading: Icon(Icons.share_rounded, color: Pallet.colorWhite),
            title: Text('Anonymous Referral Program',
                style: TextStyle(color: Pallet.colorWhite)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.referralProgram);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Container(
      height: 400,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Icon(Icons.history_rounded, color: Colors.white70),
                SizedBox(width: 8),
                Text(
                  "Recent Love Transactions",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(child: DrawerRecentTransactionsList()),
        ],
      ),
    );
  }


  Future<void> _handleGameResult() async {
    // Stop if a reward has already been processed for this milestone or if the user is not logged in
    if (_isGameRewardProcessed || currentUser == null) return;

    int rewardAmount = 0;
    int lossAmount = 50;
    String winMessage = "";
    String lossMessage = "";
    bool isGameOver = false;

    // --- MILESTONE LOGIC ---
    if (widget.playerScore == 10) {
      rewardAmount = 50;
      winMessage = "You reached 10 wins! 50 ❤️ have been added to your wallet.";
    } else if (widget.playerScore >= 20) {
      rewardAmount = 100;
      winMessage = "CONGRATS! You beat Claire with 20 wins and won 100 ❤️!";
      isGameOver = true;
    } else if (widget.claireScore == 10) {
      lossMessage =
          "Claire reached 10 wins! You lose 50 ❤️. But the game isn't over!";
    } else if (widget.claireScore >= 20) {
      lossMessage = "Claire beat you with 20 wins! You lose another 50 ❤️.";
      isGameOver = true;
    }

    // --- HANDLE WIN CONDITION ---
    if (rewardAmount > 0) {
      setState(() => _isGameRewardProcessed = true);

      final bool wasApproved = await firebaseServices.updateTreasuryAndUser(
        userId: currentUser!.uid,
        amount: rewardAmount,
        type: t_model.TransactionType.credit,
        userTransactionDescription: "$rewardAmount Loves won from Tic-Tac-Toe.",
        metadata: {'game': 'tic-tac-toe', 'reason': 'player_won_milestone'},
        fromGameWins: rewardAmount,
      );

      if (!wasApproved) {
        showToast(
            message:
                "You won! Your $rewardAmount Love reward is pending admin approval.");
        return;
      }

      // Save User Activity for the Win
      try {
        await firebaseServices.saveUserActivity(
          activityType: 'game_win',
          activityMessage:
              'You won $rewardAmount❤️ from a Tic-Tac-Toe milestone!',
        );
        logger.d("User activity for 'game_win' saved successfully.");
      } catch (e) {
        print("Failed to save 'Game Win' user activity: $e");
      }

      // --- START: NEW TARGETED NOTIFICATION LOGIC FOR WIN ---
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        final userToken = userDoc.data()?['fcmId'] as String?;
        if (userToken != null && userToken.isNotEmpty) {
          await notificationService.sendNotification({
            "token": userToken,
            "notification": {
              "title": 'You Won!',
              "body": "You beat Claire in Tic-Tac-Toe and won $rewardAmount ❤️."
            },
            "data": {"route": "wallet"}
          });
        }
      } catch (e) {
        print("Failed to send 'Game Won' push notification: $e");
      }
      // --- END: NEW NOTIFICATION LOGIC ---

      showToast(message: winMessage);
    }
    // --- HANDLE LOSS CONDITION ---
    else if (lossMessage.isNotEmpty) {
      setState(() => _isGameRewardProcessed = true);

      await firebaseServices.updateTreasuryAndUser(
        userId: currentUser!.uid,
        amount: lossAmount,
        type: t_model.TransactionType.debit,
        userTransactionDescription: "$lossAmount Loves lost in Tic-Tac-Toe.",
        metadata: {'game': 'tic-tac-toe', 'reason': 'player_lost_milestone'},
        forGameLoses: lossAmount,
      );

      // Save User Activity for the Loss
      try {
        await firebaseServices.saveUserActivity(
          activityType: 'game_loss',
          activityMessage: 'You lost $lossAmount❤️ in a Tic-Tac-Toe milestone.',
        );
        logger.d("User activity for 'game_loss' saved successfully.");
      } catch (e) {
        print("Failed to save 'Game Loss' user activity: $e");
      }

      // --- START: NEW TARGETED NOTIFICATION LOGIC FOR LOSS ---
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        final userToken = userDoc.data()?['fcmId'] as String?;
        if (userToken != null && userToken.isNotEmpty) {
          await notificationService.sendNotification({
            "token": userToken,
            "notification": {
              "title": 'Claire Won!',
              "body": "Claire beat you in Tic-Tac-Toe. You lost $lossAmount ❤️."
            },
            "data": {"route": "wallet"}
          });
        }
      } catch (e) {
        print("Failed to send 'Game Lost' push notification: $e");
      }
      // --- END: NEW NOTIFICATION LOGIC ---

      showToast(message: lossMessage);
    }

    // --- RESET GAME LOGIC ---
    if (isGameOver) {
      print("GAME OVER: Resetting scores now.");
      // NOTE: You need to implement the actual score reset logic.
      // For example, by calling a method passed down from a parent widget.
      // widget.onGameReset?.call();
    }
  }
}

class _MenuTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuTile(
      {Key? key, required this.title, required this.icon, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white.withValues(alpha: 0.8)),
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 15)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      splashColor: Pallet.colorSecondary.withValues(alpha: 0.3),
    );
  }
}


class _FabMenuOverlay extends StatefulWidget {
  final BuildContext parentContext;
  final Size fabSize;
  final Offset fabOffset;
  final VoidCallback onClose;

  const _FabMenuOverlay({
    Key? key,
    required this.parentContext,
    required this.fabSize,
    required this.fabOffset,
    required this.onClose,
  }) : super(key: key);

  @override
  _FabMenuOverlayState createState() => _FabMenuOverlayState();
}

class _FabMenuOverlayState extends State<_FabMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _blurAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<double> _itemPositions = [280.0, 210.0, 140.0, 70.0];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _blurAnimation = Tween<double>(begin: 0.0, end: 5.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeAndNavigate(Function navigationAction) {
    _animationController.reverse().then((_) {
      widget.onClose();
      navigationAction();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred background
          GestureDetector(
            onTap: () =>
                _animationController.reverse().then((_) => widget.onClose()),
            child: AnimatedBuilder(
              animation: _blurAnimation,
              builder: (context, child) {
                return BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: _blurAnimation.value,
                      sigmaY: _blurAnimation.value),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                );
              },
            ),
          ),
          // Menu Items
          Positioned(
            right: MediaQuery.of(context).size.width -
                widget.fabOffset.dx -
                widget.fabSize.width,
            bottom: MediaQuery.of(context).size.height -
                widget.fabOffset.dy -
                widget.fabSize.height,
            width: 300,
            height: 400,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                _buildMenuItem(
                  position: _itemPositions[0],
                  icon: Icons.edit_note_rounded,
                  label: "New Diary Session",
                  onPressed: () => _closeAndNavigate(() {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null) {
                      Navigator.of(widget.parentContext)
                          .pushReplacementNamed(AppRoutes.authSelection);
                    } else {
                      Navigator.of(widget.parentContext)
                          .pushNamed(AppRoutes.createSessionPage);
                    }
                  }),
                ),
                _buildMenuItem(
                  position: _itemPositions[1],
                  icon: Icons.phone_in_talk_outlined,
                  label: "New Call Session",
                  onPressed: () {
                    _animationController.reverse().then((_) async {
                      widget.onClose();
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser == null) {
                        Navigator.of(widget.parentContext)
                            .pushReplacementNamed(AppRoutes.authSelection);
                        return;
                      }

                      final callDetails = await showPreCallDialog(
                          widget.parentContext,
                          isVideoCall: false);

                      if (callDetails != null) {
                        await firebaseServices
                            .updateUserMoods(callDetails.moodId);
                        Navigator.of(widget.parentContext).push(
                          MaterialPageRoute(
                            builder: (context) => CompanionCallPage(
                              user: currentUser,
                              callDetails: callDetails, // Correct parameter
                              incomingCall: null, // Correctly passing null
                            ),
                          ),
                        );
                      }
                    });
                  },
                ),
                _buildMenuItem(
                  position: _itemPositions[2],
                  icon: Icons.videocam_rounded,
                  label: "New Live Session",
                  onPressed: () {
                    _animationController.reverse().then((_) async {
                      widget.onClose();
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser == null) {
                        Navigator.of(widget.parentContext)
                            .pushReplacementNamed(AppRoutes.authSelection);
                        return;
                      }

                      final callDetails = await showPreCallDialog(
                          widget.parentContext,
                          isVideoCall: true);

                      if (callDetails != null) {
                        await firebaseServices
                            .updateUserMoods(callDetails.moodId);
                        Navigator.of(widget.parentContext).push(
                          MaterialPageRoute(
                            builder: (context) => LiveCallPage(
                              user: currentUser,
                              callDetails: callDetails, // Correct parameter
                              incomingCall: null, // Correctly passing null
                            ),
                          ),
                        );
                        // --- END FIX ---
                      }
                    });
                  },
                ),
                _buildMenuItem(
                  position: _itemPositions[3],
                  icon: Icons.psychology_alt_rounded,
                  label: "Automatic Diary",
                  onPressed: () => _closeAndNavigate(() {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null) {
                      Navigator.of(widget.parentContext)
                          .pushReplacementNamed(AppRoutes.authSelection);
                    } else {
                      Navigator.of(widget.parentContext).push(MaterialPageRoute(
                          builder: (context) => const SetupAutoDiary()));
                    }
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required double position,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Positioned(
          bottom: position * _scaleAnimation.value,
          right: 0,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        )
                      ]),
                  child: Text(
                    label,
                    style: GoogleFonts.lato(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  heroTag: null, // Avoids tag conflicts
                  mini: true,
                  backgroundColor: Pallet.colorPrimary,
                  onPressed: onPressed,
                  child: Icon(icon, color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
