import 'dart:convert';

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
import '../../helpers/toast_helper.dart';
import '../../services/data/notification_model.dart' as push_notification;
import '../../services/firebase_services.dart';
import '../../services/notification_service.dart';
import '../../services/user_model.dart';
import '../../utils/helper.dart';
import '../../widgets/recent_transactions_list.dart';
import '../routes/page_router_animation.dart';
import '../visited_user_ego_page/visited_user_ego_page.dart';
import 'destination.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../data/models/transaction_model.dart' as t_model;
import '../../services/transaction_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomeDashboardPageState createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomePage>
    with TickerProviderStateMixin<HomePage> {
  var currentUser = FirebaseAuth.instance.currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final WebViewController _webViewController; // Updated initialization
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

  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 15),
    vsync: this,
  )..repeat(reverse: true);

  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticOut,
  );

  PageController _pageController = PageController(initialPage: 0);

  List<Widget> _body = [
    FeaturedPage(title: 'Dear Claire'),
    FollowedPage(title: 'Dear Claire'),
    DiaryPage(title: 'Dear Claire'),
    ChatRoomsPage(title: 'Dear Claire'),
    EgoProfilePage(title: 'Dear Claire'),
  ];

  /// Get the Ego User info
  Future<UserModel> getEgoInfo() async {
    final String? userId = currentUser?.uid.toString();
    DocumentSnapshot response = await FirebaseFirestore.instance
        .collection(AppString.users)
        .doc(userId)
        .get();

    var egoInfo =
        UserModel.fromFirestore(response.data() as Map<String, dynamic>);
    userName = egoInfo.nickname.toString();
    userType = egoInfo.userType.toString();
    avatarUrl = egoInfo.avatarUrl.toString();
    final _userId = egoInfo.userId.toString();
    await firebaseServices.updateUserLastTimeUnlocked(_userId);
    logger.d(
        'Successfully got an Ego user model and updated time last unlocked.');
    return egoInfo;
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

  String getDonateUrl() {
    return AppString.donate_url;
  }

  onDonateClicked() {
    Uri donateUrl = Uri.parse(getDonateUrl());
    launchUrl(donateUrl);
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

  void setTabIndex(index) async {
    if (await firebaseServices.isUserSignIn(context))
      _pageController.animateToPage(index,
          duration: Duration(milliseconds: 1500), curve: Curves.elasticOut);
    switch (index) {
      case 0:
        {
          _title = 'Featured Sessions';
        }
        break;
      case 1:
        {
          _title = 'Followed Sessions';
        }
        break;
      case 2:
        {
          _title = 'Diary Sessions';
        }
        break;
      case 3:
        {
          _title = 'Diary Rooms';
        }
        break;
      case 4:
        {
          _title = 'Ego Profile';
        }
        break;
    }
  }


  // In lib/ui/bottom_nav/stack_index_home.dart -> _HomeDashboardPageState

  @override
  void initState() {
    super.initState();
    getEgoInfo();
    _title = "Dear Claire";
    shakeDevice();
    AppTrackingTransparency.requestTrackingAuthorization();

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



  final AudioPlayer _audioPlayer = AudioPlayer();


  Future<void> _handleDrawReward() async {
    if (currentUser == null) return;
    const int rewardAmount = 2;

    // 1. Credit the user with 2 Loves
    final bool wasApproved = await firebaseServices.updateTreasuryAndUser(
      userId: currentUser!.uid,
      amount: rewardAmount,
      type: t_model.TransactionType.credit,
      userTransactionDescription: "$rewardAmount❤️ won from a Tic-Tac-Toe draw.",
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
        activityMessage: 'You had a draw with Claire in Tic-Tac-Toe and earned 2❤️.',
        // No recipientId needed as it's a system transaction
      );
      logger.d("User activity for 'game_draw' saved successfully.");
    } catch (e) {
      print("Failed to save 'Game Draw' user activity: $e");
    }

    // 3. Send the targeted notification for the draw
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
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
      // The callback now accepts a 'ShakeEvent' parameter
      onPhoneShake: (ShakeEvent event) {
        // Immediately invoke an anonymous async function to handle async operations
        () async {
          // Use a mounted check for safety in async callbacks
          if (!mounted) return;

          // Vibrate the device if possible
          if (await Vibration.hasVibrator()) {
            Vibration.vibrate();
          }

          Fluttertoast.showToast(
            toastLength: Toast.LENGTH_LONG,
            msg: "Switching Ego",
            textColor: Colors.white,
            backgroundColor: Pallet.colorSplashScreen,
          );

          // Get Alter Ego details
          String id = await sharedPreference.getAlterEgoId();
          String accessCode = await sharedPreference.getAlterEgoAccessCode();
          print("Show Alter details:: $id || $accessCode");

          // Add another mounted check before using context for navigation
          if (!mounted) return;

          if (id.isNotEmpty && accessCode.isNotEmpty) {
            await firebaseServices.getUserAlterEgo(context, id, accessCode);
          } else {
            Navigator.of(context).pushNamed(AppRoutes.alterEgoLogin);
          }
        }(); // The '()' here calls the anonymous function immediately
      },
      minimumShakeCount: 1,
      //shakeThresholdGravity: 1.5, // You can adjust this for sensitivity
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    detector.stopListening();
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
              physics: AlwaysScrollableScrollPhysics(),
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
        floatingActionButton: FloatingActionButton(
          heroTag: "fab",
          backgroundColor: Pallet.colorSplashScreen,
          onPressed: () {
            if (currentUser == null) {
              Navigator.of(context)
                  .pushReplacementNamed(AppRoutes.authSelection);
            } else {
              Navigator.of(context).pushNamed(AppRoutes.createSessionPage);
            }
          },
          tooltip: 'Hi, Darling!',
          child: RotateImage(45, 45),
        ),
      drawer: _AppDrawer(
        userName: userName,
        userType: userType,
        avatarUrl: avatarUrl,
        lockAlertDialog: () => lockAlertDialog(context),
        onAlterEgoTapped: () async {
          String id = await sharedPreference.getAlterEgoId();
          String accessCode = await sharedPreference.getAlterEgoAccessCode();
          print("Show Alter details:: $id || $accessCode");
          id.isNotEmpty && accessCode.isNotEmpty
              ? await firebaseServices.getUserAlterEgo(context, id, accessCode)
              : Navigator.of(context).pushNamed(AppRoutes.alterEgoLogin);
        },
        onDonateClicked: onDonateClicked,
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
  final VoidCallback onDonateClicked;
  final VoidCallback sendClaireToSomeone;
  final VoidCallback launchEmailApp;
  final Future<bool> Function() isUserSignedIn;
  final WebViewController ticTacToeController;
  final int playerScore;
  final int claireScore;
  final int drawCount;

  const _AppDrawer({Key? key,
        required this.userName,
        required this.userType,
        required this.avatarUrl,
        required this.lockAlertDialog,
        required this.onAlterEgoTapped,
        required this.onDonateClicked,
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
  final User? _currentUser = FirebaseAuth.instance.currentUser;
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
                  color: Colors.black.withOpacity(0.4),
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
              Image.asset("assets/images/claire_icon.png", height: 25, width: 25),
              Text(
                "Switch",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Pallet.colorWhite.withOpacity(0.95),
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
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Quick Tac Toe",
              style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
        color: Colors.black.withOpacity(0.3),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
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
          _milestoneWidget("20 Wins = ", "100 ❤️",),
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
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _scorePillar('You', widget.playerScore, Colors.white),
          Text('vs',
              style: GoogleFonts.lato(
                  color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600)),
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
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
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
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.howClaireWorks)),
          _MenuTile(
              title: "Request Alter Ego Mode",
              icon: Icons.star_rounded,
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.howAlterEgoWorks)),
          _MenuTile(
            title: "Auto Diary",
            icon: Icons.auto_awesome_motion_rounded,
            onTap: () async {
              if (await widget.isUserSignedIn()) {
                Navigator.of(context).pushNamed(AppRoutes.setupAutoDiary);
              }
            },
          ),
          /*_MenuTile(
              title: "Top Up Your Love",
              icon: Icons.currency_exchange_rounded,
              onTap: widget.onDonateClicked),*/
          _MenuTile(
            title: "More Games With Claire",
            icon: Icons.gamepad_rounded,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(AppRoutes.games);
            },
          ),
          _MenuTile(
              title: "Send Claire To Someone",
              icon: Icons.share_rounded,
              onTap: widget.sendClaireToSomeone),
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
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
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
          Expanded(
              child: DrawerRecentTransactionsList()),
        ],
      ),
    );
  }



  Future<void> _handleDrawReward() async {
    if (_currentUser == null) return;
    const int rewardAmount = 2;

    // 1. Credit the user with 2 Loves
    final bool wasApproved = await firebaseServices.updateTreasuryAndUser(
      userId: _currentUser!.uid,
      amount: rewardAmount,
      type: t_model.TransactionType.credit,
      userTransactionDescription: "$rewardAmount ❤️ won from a Tic-Tac-Toe draw.",
      metadata: {'game': 'tic-tac-toe', 'reason': 'player_draw'},
      fromGameWins: rewardAmount,
    );

    if (!wasApproved) {
      showToast(message: "Draw! Your 2❤️ reward is pending admin approval.");
      return;
    }

    // 2. Send the targeted notification for the draw
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
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

    // 3. Give immediate feedback to the user
    showToast(message: "It's a draw! You earned 2❤️.");
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
      lossMessage = "Claire reached 10 wins! You lose 50 ❤️. But the game isn't over!";
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
        showToast(message: "You won! Your $rewardAmount Love reward is pending admin approval.");
        return;
      }

      // Save User Activity for the Win
      try {
        await firebaseServices.saveUserActivity(
          activityType: 'game_win',
          activityMessage: 'You won $rewardAmount❤️ from a Tic-Tac-Toe milestone!',
        );
        logger.d("User activity for 'game_win' saved successfully.");
      } catch (e) {
        print("Failed to save 'Game Win' user activity: $e");
      }

      // --- START: NEW TARGETED NOTIFICATION LOGIC FOR WIN ---
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
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
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
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
      leading: Icon(icon, color: Colors.white.withOpacity(0.8)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      splashColor: Pallet.colorSecondary.withOpacity(0.3),
    );
  }
}


