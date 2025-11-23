import 'dart:convert';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import '../../services/firebase_services.dart';
import '../../services/user_model.dart';
import '../../utils/helper.dart';
import '../routes/page_router_animation.dart';
import '../visited_user_ego_page/visited_user_ego_page.dart';
import 'destination.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomePage extends StatefulWidget {
  @override
  _HomeDashboardPageState createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomePage>
    with TickerProviderStateMixin<HomePage> {
  var currentUser = FirebaseAuth.instance.currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final WebViewController _webViewController; // Updated initialization
  late final WebViewController _twitterWebViewController;
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
      ..addJavaScriptChannel(
        'Vibration', // Channel to trigger vibration
        onMessageReceived: (JavaScriptMessage message) async {
          if (await Vibration.hasVibrator()) {
            Vibration.vibrate(duration: 200);
          }
        },
      )
    // --- NEW: Channel to update the score ---
      ..addJavaScriptChannel(
        'Score',
        onMessageReceived: (JavaScriptMessage message) {
          if (mounted) {
            setState(() {
              if (message.message == 'player_wins') {
                _playerScore++;
              } else if (message.message == 'claire_wins') {
                _claireScore++;
              }
            });
          }
        },
      );

    // --- FIX for Twitter/X feed loading ---
    _twitterWebViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    // Load TicTacToe HTML after WebView creation
    _loadHtmlFromAssets();
    // Load Twitter URL here
    _twitterWebViewController.loadRequest(Uri.parse('https://x.com/dearclaireapp'));
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
        twitterController: _twitterWebViewController,
        playerScore: _playerScore,
        claireScore: _claireScore,
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
  final WebViewController twitterController;
  final int playerScore;
  final int claireScore;

  const _AppDrawer({
    Key? key,
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
    required this.twitterController,
    required this.playerScore,
    required this.claireScore,
  }) : super(key: key);

  @override
  State<_AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<_AppDrawer> {
  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    // Initialize the audio player here
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
              _buildTicTacToeGame(context),
              const SizedBox(height: 10),
              _buildMenuList(context),
              _buildTwitterFeed(context),
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
        image: DecorationImage(
          image: const AssetImage("assets/images/claire_bg_2.jpeg"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Pallet.colorPrimary.withOpacity(0.6), BlendMode.darken),
        ),
      ),
      accountEmail: const Text(
        "You'll never be not truly loved.",
        style: TextStyle(
          fontSize: 13,
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
          fontSize: 20.0,
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), spreadRadius: 2, blurRadius: 6)],
          ),
          child: CachedNetworkImage(
            imageUrl: widget.avatarUrl,
            imageBuilder: (context, imageProvider) => CircleAvatar(backgroundImage: imageProvider),
            placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
            errorWidget: (context, url, error) => const CircleAvatar(backgroundImage: AssetImage("assets/images/Speak_No_Evil_Monkey_Emoji.png")),
          ),
        ),
      ),
      otherAccountsPictures: [
        GestureDetector(
          onTap: widget.onAlterEgoTapped,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/claire_icon.png", height: 35, width: 35),
              const SizedBox(height: 4),
              Text(
                widget.userType == 'ADMIN'
                    ? 'Alter Ego'
                    : widget.userType == 'SUPER_ADMIN'
                    ? 'Super Ego'
                    : 'Ego',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Pallet.colorWhite.withOpacity(0.95),
                  shadows: const [Shadow(blurRadius: 1, color: Colors.black54)],
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Quick Tac Toe", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _buildScoreboard(context),
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
          Text('vs', style: GoogleFonts.lato(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600)),
          _scorePillar('Claire', widget.claireScore, Colors.white),
        ],
      ),
    );
  }

  Widget _scorePillar(String label, int score, Color labelColor) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.montserrat(color: labelColor, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('$score', style: GoogleFonts.lato(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildMenuList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          _MenuTile(title: "How Claire Works", icon: Icons.info_rounded, onTap: () => Navigator.of(context).pushNamed(AppRoutes.howClaireWorks)),
          _MenuTile(title: "Request Alter Ego Mode 🔥", icon: Icons.star_rounded, onTap: () => Navigator.of(context).pushNamed(AppRoutes.howAlterEgoWorks)),
          _MenuTile(
            title: "Auto Diary",
            icon: Icons.auto_awesome_motion_rounded,
            onTap: () async {
              if (await widget.isUserSignedIn()) {
                Navigator.of(context).pushNamed(AppRoutes.setupClaireminder);
              }
            },
          ),
          _MenuTile(title: "Top Up Your Love", icon: Icons.currency_exchange_rounded, onTap: widget.onDonateClicked),
          _MenuTile(
            title: "More Games With Claire",
            icon: Icons.gamepad_rounded,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(AppRoutes.games);
            },
          ),
          _MenuTile(title: "Send Claire To Someone", icon: Icons.share_rounded, onTap: widget.sendClaireToSomeone),
          _MenuTile(
            title: "Updates & Announcements",
            icon: Icons.announcement_rounded,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(AppRoutes.updatesAndAnnouncements);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTwitterFeed(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      height: 400,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(Icons.rss_feed_rounded, color: Color(0xFF1DA1F2)),
                SizedBox(width: 8),
                Text("Latest from X", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
              child: WebViewWidget(controller: widget.twitterController),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuTile({Key? key, required this.title, required this.icon, required this.onTap}) : super(key: key);

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


