import 'dart:io';
import 'dart:math';
import 'package:clairediary/widgets/audio_recorder.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/ui/ego-profile/claire_loves.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:clairediary/widgets/toast.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clairediary/services/user_model.dart';
import 'package:clairediary/ui/ego-profile/acvitity.dart';
import 'package:clairediary/ui/ego-profile/archive.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../routes/page_router_animation.dart';
import '../visited_user_ego_page/visited_user_ego_page.dart';
import 'clairevatar.dart';
import '../create_session/sound/custom_play_sound_widget.dart';

class EgoProfilePage extends StatefulWidget {
  final String title;
  const EgoProfilePage({Key? key, required this.title,}) : super(key: key);

  @override
  _EgoProfilePageState createState() => _EgoProfilePageState();
}

const int maxFailedLoadAttempts = 3;



class _EgoProfilePageState extends State<EgoProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _mantraController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();
  GlobalKey<FlipCardState> cardKey2 = GlobalKey<FlipCardState>();
  late String mantraUserId;
  late String mantraEgoName;
  double _uploadProgress = 0;



  @override
  void initState() {
    super.initState();
    getUser();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      print(_tabController.index);
    });
    _createEgoNameInterstitialAd();
    _createEgoMantraInterstitialAd();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
    _interstitialAd?.dispose();
    _interstitialAd2?.dispose();
  }

  int currentTabIndex = 0;
  UserModel userModel = UserModel();
  User? currentUser = FirebaseAuth.instance.currentUser;

  getUser() async {
    userModel = await firebaseServices.getUserInfo();
  }

  /// Edit nickname

  Future<void> editNickName() async {
    final nickname = _nicknameController.text;
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser?.uid)
        .update({
      "nickname": nickname,
    },
    );
    logger.d('Successfully saved new nickname');
    print('Nickname: $nickname');

    getUserNickname();
  }

  getUserNickname() async {
    userModel = await firebaseServices.getUserInfo();
  }



  /// Query Ego stream from Firestore

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserEgoStream() {

    return FirebaseFirestore.instance
        .collection('ego_stream')
        .where("userId", isEqualTo: currentUser?.uid)
        .limit(300)
        .orderBy('egoTime', descending: true)
        .snapshots();
  }


  /// Save Ego mantra

  Future<void> saveEgoMantra() async {
    final egoMessage = _mantraController.text;
    final egoTime = FieldValue.serverTimestamp();
    final egoName = userModel.nickname;
    final egoImage = userModel.avatarUrl;
    final userId = userModel.userId;
    final senderId = currentUser?.uid;
    FirebaseFirestore.instance
        .collection('ego_stream')
        .add({
      "egoMessage": egoMessage,
      "egoTime": egoTime,
      "egoName": egoName,
      "egoImage": egoImage,
      "userId": userId,
      "senderId": senderId,
    },
      //SetOptions(merge: true)
    );
    logger.d('Successfully saved your Ego message');
    print('Ego Message: $egoMessage');

  }

  /// Save Ego audio mantra

  Future<void> saveEgoAudioMantra(String audioPath) async {
    final egoTime = FieldValue.serverTimestamp();
    final egoName = userModel.nickname;
    final egoImage = userModel.avatarUrl;
    final userId = userModel.userId;
    final senderId = currentUser?.uid;

    final storageRef = FirebaseStorage.instance.ref();
    final audioRef = storageRef.child("ego_audio/\${DateTime.now().millisecondsSinceEpoch}.m4a");

    final uploadTask = audioRef.putFile(File(audioPath));

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      setState(() {
        _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
      });
    });

    await uploadTask.whenComplete(() {});

    final downloadUrl = await audioRef.getDownloadURL();

    FirebaseFirestore.instance
        .collection('ego_stream')
        .add({
      "egoAudioMessage": downloadUrl,
      "egoTime": egoTime,
      "egoName": egoName,
      "egoImage": egoImage,
      "userId": userId,
      "senderId": senderId,
    },
      //SetOptions(merge: true)
    );
    logger.d('Successfully saved your Ego audio message');
    print('Ego Audio Message: $downloadUrl');

    setState(() {
      _uploadProgress = 0;
    });
  }


  /// Delete an ego message

  Future<void> deleteEgoMessage(String egoMessage) async {
    final collection = FirebaseFirestore.instance
        .collection('ego_stream')
        .where("egoMessage", isEqualTo: egoMessage);
    collection.get().then((value) {
      value.docs.forEach((element) {
        element.reference.delete();
      });
    });
    logger.d('Successfully deleted an ego message');
  }

  InterstitialAd? _interstitialAd;
  InterstitialAd? _interstitialAd2;
  int _interstitialLoadAttempts = 0;

  // Create interstitial ad.

  void _createEgoNameInterstitialAd() {
    InterstitialAd.load(
      adUnitId:  Platform.isAndroid? "ca-app-pub-2404156870680632/9680520067" :
      Platform.isIOS? "ca-app-pub-2404156870680632/7910759937" :
      '',
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Failed to load an interstitial ad: ${error.message}');
          _interstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_interstitialLoadAttempts <= maxFailedLoadAttempts) {
            _createEgoNameInterstitialAd();
          }
        },
      ),
    );
  }

  void _createEgoMantraInterstitialAd() {
    InterstitialAd.load(
      adUnitId:  Platform.isAndroid? "ca-app-pub-2404156870680632/2338869057" :
      Platform.isIOS? "ca-app-pub-2404156870680632/5936716173" :
      '',
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd2 = ad;
          _interstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Failed to load an interstitial ad: ${error.message}');
          _interstitialLoadAttempts += 1;
          _interstitialAd2 = null;
          if (_interstitialLoadAttempts <= maxFailedLoadAttempts) {
            _createEgoMantraInterstitialAd();
          }
        },
      ),
    );
  }

  void _showEgoNameInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _createEgoNameInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _createEgoNameInterstitialAd();
        },
      );
      _interstitialAd!.show();
    }
  }


  void _showEgoMantraInterstitialAd() {
    if (_interstitialAd2 != null) {
      _interstitialAd2!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _createEgoMantraInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _createEgoMantraInterstitialAd();
        },
      );
      _interstitialAd2!.show();
    }
  }


  flagEgoAlertDialog(BuildContext context) {

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Back"),
      onPressed:  () {
        Navigator.of(context).pop();
      },
    );

    Widget continueButton = TextButton(
      child: Text("Okay"),
      onPressed:  () {
        Navigator.of(context).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Be Very Careful, You Are Flagged!"),
      content: Text(AppString.flagged_ego_alert_note),
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








// Profile page header
  Widget _pageHeader({
    String? avatarUrl,
    String? userName,
    String? userType,
    var sessionCount,
    var totalLoveCount,
    var advisesCount,
  }) {
    // Helper for userType styling
    Color _getHeaderColor() {
      switch (userType) {
        case 'ADMIN':
          return Pallet.colorSecondary;
        case 'SUPER_ADMIN':
          return Pallet.colorSecondary;
        case 'REGULAR':
        default:
          return Pallet.colorPrimary;
      }
    }

    String _getEgoTypeName() {
      switch (userType) {
        case 'ADMIN':
          return 'Alter Ego';
        case 'SUPER_ADMIN':
          return 'Super Ego';
        case 'REGULAR':
        default:
          return 'Ego';
      }
    }

    IconData _getEgoIcon() {
      switch (userType) {
        case 'ADMIN':
          return Icons.people_alt;
        case 'SUPER_ADMIN':
          return Icons.star_purple500_sharp;
        case 'REGULAR':
        default:
          return Icons.person;
      }
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImages.appChatBg),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar, Name, and Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              Navigator.of(context).pushNamed(
                                  AppRoutes.editClairevatar),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getHeaderColor().withOpacity(0.8),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: avatarUrl ?? "",
                              imageBuilder: (context, imageProvider) =>
                                  CircleAvatar(
                                    radius: 32, // MODIFIED: Reduced size
                                    backgroundImage: imageProvider,
                                  ),
                              placeholder: (context, url) =>
                                  CircleAvatar(radius: 32,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white)),
                              errorWidget: (context, url, error) =>
                                  CircleAvatar(radius: 32,
                                      backgroundImage: AssetImage(
                                          "assets/images/Speak_No_Evil_Monkey_Emoji.png")),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              Navigator.of(context).pushNamed(
                                  AppRoutes.editClairevatar),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(shape: BoxShape.circle,
                                color: Colors.white),
                            child: Icon(Icons.edit, size: 14,
                                color: _getHeaderColor()), // MODIFIED: Reduced size
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _showEditNicknameDialog(context),
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded,
                                  color: Pallet.colorWhite,
                                  size: 16,
                                ),
                                Flexible(
                                  child: Text(
                                    userName ?? "...",
                                    style: TextStyle(
                                      fontSize: 20, // MODIFIED: Reduced size
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(blurRadius: 2,
                                            color: Colors.black.withOpacity(0.5))
                                      ],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // ADDED: Re-integrated topBarWidget here
                                topBarWidget(),
                              ],
                            ),
                          ),
                          // ADDED: Edit Nickname button below the name
                          // Top Bar with Ego Badge and Menu
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getHeaderColor(),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_getEgoIcon(), color: Colors.white, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getEgoTypeName(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // User Stats Section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  // MODIFIED: Reduced padding
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(
                          Icons.chat_bubble_outline, "Sessions", sessionCount),
                      _buildStatColumn(
                          Icons.lightbulb_outline, "Advises", advisesCount),
                      _buildStatColumn(
                          Icons.favorite_border, "Loves", totalLoveCount),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // FlipCard for Mantra/Stream
                _buildMantraStreamCard(userType, context),

                if (_uploadProgress > 0 && _uploadProgress < 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: LinearPercentIndicator(
                      lineHeight: 8.0,
                      percent: _uploadProgress,
                      barRadius: Radius.circular(10),
                      backgroundColor: Colors.grey.shade700,
                      progressColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// NEW: Helper to show the nickname edit dialog
  void _showEditNicknameDialog(BuildContext context) {
    _nicknameController.text = userModel.nickname ?? '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Text("Change Ego Name", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: _nicknameController,
            autofocus: true,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter new name...",
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Pallet.colorPrimary)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Pallet.colorPrimary, width: 2)),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel", style: TextStyle(color: Colors.white70)),
              onPressed: () {
                _nicknameController.clear();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Save", style: TextStyle(
                  color: Pallet.colorPrimary, fontWeight: FontWeight.bold)),
              onPressed: () {
                if (_nicknameController.text.isNotEmpty) {
                  editNickName();
                  showToast(AppString.change_ego_name);
                  Future.delayed(
                      Duration(seconds: 3), () => _showEgoNameInterstitialAd());
                }
                _nicknameController.clear();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

// Helper method to build a single stat column
  Widget _buildStatColumn(IconData icon, String label, String? count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(count ?? "0", style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        // MODIFIED: Reduced size
        Text(label, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w400, color: Colors.white70)),
        // MODIFIED: Reduced size
      ],
    );
  }

// Helper for Mantra/Stream Card
  Widget _buildMantraStreamCard(String? userType, BuildContext context) {
    return Container(
      height: 150, // MODIFIED: Reduced height
      child: FlipCard(
        key: cardKey,
        direction: FlipDirection.HORIZONTAL,
        front: Container(
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(15)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Text("Ego Stream", style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: getUserEgoStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                              "Tap to flip and share your first mantra...",
                              textAlign: TextAlign.center, style: TextStyle(
                              color: Colors.white70,
                              fontStyle: FontStyle.italic)),
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                          child: CircularProgressIndicator(color: Colors.white));
                    }
                    return ListView
                        .builder( // Use ListView.builder for performance
                      padding: EdgeInsets.zero,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> data = snapshot.data!.docs[index]
                            .data()! as Map<String, dynamic>;
                        bool isAudio = data.containsKey('egoAudioMessage');
                        return ListTile(
                          dense: true, // Make list items more compact
                          leading: CircleAvatar(radius: 18,
                              backgroundImage: NetworkImage(
                                  data['egoImage'] ?? "")),
                          title: Text(data['egoName'] ?? 'Anonymous',
                              style: TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14)),
                          subtitle: isAudio
                              ? CustomPlaySoundWidget(
                              filePath: data['egoAudioMessage'])
                              : Text(data['egoMessage'] ?? '', maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        back: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              Expanded(
                child: TextField(
                  controller: _mantraController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Share your mantra, or hold the mic to record...",
                    hintStyle: TextStyle(
                        color: Colors.white54, fontStyle: FontStyle.italic),
                    border: InputBorder.none,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onLongPressStart: (_) async {
                      HapticFeedback.heavyImpact();
                      showToast("Recording started...");
                      // await _audioRecorder.start();
                    },
                    onLongPressEnd: (_) async {
                      showToast("Recording saved.");
                      // final path = await _audioRecorder.stop();
                      // if (path != null) { saveEgoAudioMantra(path); }
                    },
                    child: CircleAvatar(radius: 25,
                        backgroundColor: Pallet.colorPrimary,
                        child: Icon(Icons.mic, color: Colors.white, size: 28)),
                  ),
                  SizedBox(width: 10),
                  FloatingActionButton(
                    heroTag: 'saveMantraButton',
                    mini: true,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.send, color: Pallet.colorPrimary),
                    onPressed: () {
                      if (_mantraController.text.isNotEmpty) {
                        saveEgoMantra();
                        _mantraController.clear();
                        if (cardKey.currentState != null) cardKey.currentState!
                            .toggleCard();
                        showToast(AppString.change_ego_mantra);
                        Future.delayed(Duration(seconds: 4), () =>
                            _showEgoMantraInterstitialAd());
                      }
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }







  @override
  Widget build(BuildContext context) {
    print("User nickname::: ${userModel.nickname}");
    print("User type::: ${userModel.userType}");

    return SafeArea(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
          showToast("Press back again to exit.");
        },
        child: Scaffold(
          backgroundColor: Pallet.colorSecondaryDark,
          body: Column(
            children: [
              Material(
                elevation: 10,
                child: FutureBuilder<
                    DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection("users")
                      .doc(currentUser?.uid)
                      .get(),
                  builder: (_, snapshot) {
                    if (snapshot.hasData) {
                      var data = snapshot.data!.data();
                      return _pageHeader(
                        userName: data?["nickname"] ?? "Claire's Darling",
                        sessionCount: data?["sessionCount"].toString() ?? "0",
                        advisesCount: data?["adviseCount"].toString() ?? "0",
                        totalLoveCount: data?["totalLoveCount"].toString() ?? "0",
                        userType: data?["userType"] ?? "Ego",
                        avatarUrl: data?["avatarUrl"] ?? " ",
                      );
                    }

                    return CircularProgressIndicator();
                  },
                ),

              ),


              /// The three Ego page tabs are here
              /// First tab is Activity Tab

              Expanded(
                  child: DefaultTabController(
                    length: 3, child: Column(children: [
                    SizedBox(height: 7.h),
                    Container(
                      // margin: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        //border: Border.all(color: Pallet.colorPrimary, width: 1),
                      ),
                      child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _tabController.animateTo(0);
                                    currentTabIndex = 0;
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  height: 43,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      border: currentTabIndex != 0
                                          ? Border.all(
                                          color: Pallet.colorPrimary, width: 3)
                                          : Border.all(
                                          color: Pallet.colorPrimary, width: 6),
                                      borderRadius: BorderRadius.circular(25),
                                      color: currentTabIndex != 0
                                          ? Pallet.colorWhite
                                          : Pallet.colorWhite),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Activity",
                                          style: TextStyle(
                                            color: currentTabIndex != 0
                                                ? Pallet.colorPrimary
                                                : Pallet.colorPrimary,
                                            fontWeight: currentTabIndex != 0
                                                ? FontWeight.w500
                                                : FontWeight.w700,
                                            fontSize: currentTabIndex != 0 ? 14 : 14,
                                          ),
                                        ),
                                        SizedBox(width: 14),
                                        currentTabIndex != 0
                                            ? SizedBox.shrink()
                                            : Icon(Icons.circle_notifications,
                                            color: Pallet.colorPrimary)
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),



                            /// Second tab is Claire Love Tab

                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _tabController.animateTo(1);
                                    currentTabIndex = 1;
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  height: 43,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      border: currentTabIndex != 1
                                          ? Border.all(
                                          color: Pallet.colorSecondary, width: 3)
                                          : Border.all(
                                          color: Pallet.colorSecondary, width: 6),
                                      borderRadius: BorderRadius.circular(25),
                                      color: currentTabIndex != 1
                                          ? Pallet.colorWhite
                                          : Pallet.colorWhite),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Wallet",
                                          style: TextStyle(
                                            color: currentTabIndex != 1
                                                ? Pallet.colorSecondary
                                                : Pallet.colorSecondary,
                                            fontWeight: currentTabIndex != 1
                                                ? FontWeight.w500
                                                : FontWeight.w700,
                                            fontSize: currentTabIndex != 1 ? 14 : 14,
                                          ),
                                        ),
                                        SizedBox(width: 14),
                                        currentTabIndex != 1
                                            ? SizedBox.shrink()
                                            : Icon(Icons.monetization_on_rounded,
                                            color: Pallet.colorSecondary)
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),


                            /// Third tab is Archive Tab

                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _tabController.animateTo(2);
                                    currentTabIndex = 2;
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  height: 43,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      border: currentTabIndex != 2
                                          ? Border.all(
                                          color: Pallet.deepGreen, width: 3)
                                          : Border.all(
                                          color: Pallet.deepGreen, width: 6),
                                      borderRadius: BorderRadius.circular(25),
                                      color: currentTabIndex != 2
                                          ? Pallet.colorWhite
                                          : Pallet.colorWhite),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Archive",
                                          style: TextStyle(
                                            color: currentTabIndex != 2
                                                ? Pallet.deepGreen
                                                : Pallet.deepGreen,
                                            fontWeight: currentTabIndex != 2
                                                ? FontWeight.w500
                                                : FontWeight.w700,
                                            fontSize: currentTabIndex != 2 ? 14 : 14,
                                          ),
                                        ),
                                        SizedBox(width: 14),
                                        currentTabIndex != 2
                                            ? SizedBox.shrink()
                                            : Icon(Icons.archive_rounded,
                                            color: Pallet.deepGreen)
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          ]
                      ),
                    ),

                    Expanded(
                      child: TabBarView(
                        physics: NeverScrollableScrollPhysics(),
                        controller: _tabController,
                        children: [
                          ActivityWidget(),
                          ClaireLoves(),
                          ArchiveWidget(),
                        ],
                      ),
                    )
                  ]),
                  ))
            ],
          ),
        ),
      ),
    );
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;

  const AudioPlayerWidget({Key? key, required this.audioPath}) : super(key: key);

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    try {
      await _audioPlayer.setUrl(widget.audioPath);
      _audioPlayer.play();
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  void _pause() {
    _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isPlaying) {
          _pause();
        } else {
          _play();
        }
      },
      child: Icon(
        _isPlaying ? Icons.pause : Icons.play_arrow,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}

/// A top bar widget for logout and switch ego. Might remove soon.

class topBarWidget extends StatelessWidget {
  const topBarWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FocusedMenuHolder(
              menuWidth: MediaQuery.of(context).size.width * 0.40,
              menuItemExtent: 45,
              menuBoxDecoration: BoxDecoration(
                  color: Pallet.colorPrimary,
                  borderRadius: BorderRadius.all(Radius.circular(15.0))),
              duration: Duration(milliseconds: 700),
              animateMenuItems: true,
              blurBackgroundColor: Pallet.colorPrimary,
              openWithTap: true,
              // Open Focused-Menu on Tap rather than Long Press
              menuOffset: 10.0,
              // Offset value to show menuItem from the selected item
              bottomOffsetHeight: 80.0,
              // Offset height to consider, for showing the menu item ( for example bottom navigation bar), so that the popup menu will be shown on top of selected item.
              menuItems: <FocusedMenuItem>[
                FocusedMenuItem(title: Text("< SWITCH >", style: TextStyle(color: Pallet.colorSecondary),),
                  onPressed: () async {
                    String id = await sharedPreference.getAlterEgoId();
                    String accessCode = await sharedPreference.getAlterEgoAccessCode();
                    print("Show Alter details:: $id || $accessCode");
                    id.isNotEmpty && accessCode.isNotEmpty ? await firebaseServices.getUserAlterEgo(context,id, accessCode)
                        : Navigator.of(context)
                        .pushNamed(AppRoutes.alterEgoLogin);
                  },),
                FocusedMenuItem(
                    title: Text(
                      "Lock Out",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onPressed: () async =>
                        lockAlertDialog(context),
                ),
                FocusedMenuItem(
                  title: Text(
                    "Delete Account",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onPressed: () async =>
                      deleteEgoAlertDialog(context),
                ),
              ],
              onPressed: () {},
              child: Icon(Icons.unfold_more_sharp,
                color: Pallet.colorWhite,
                size: 19,
              )
          )
        ],
      ),
    );
  }
}


lockAlertDialog(BuildContext context) {

  // set up the buttons
  Widget cancelButton = TextButton(
    child: Text("No, Wait."),
    onPressed:  () {
      Navigator.of(context).pop();
    },
  );

  Widget continueButton = TextButton(
    child: Text("Yes, Lock Out."),
    onPressed:  () {
      firebaseServices.logUserOut(context);
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text("Close and Lock Your Diary?"),
    content: Text(AppString.lock_out_alert_note),
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


deleteEgoAlertDialog(BuildContext context) {

  // set up the buttons
  Widget cancelButton = TextButton(
    child: Text("NO, WAIT!"),
    onPressed:  () {
      Navigator.of(context).pop();
    },
  );

  Widget continueButton = TextButton(
    child: Text("YES, DELETE EGO."),
    onPressed: () {
      showToast("Long press to delete account.");
    },
    onLongPress:  () {
      firebaseServices.deleteEgoAccount(context, currentUser!.uid);
      Navigator.pushReplacementNamed(context, AppRoutes.authSelection);
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text("Delete your account and all your data?"),
    content: Text(AppString.delete_account_alert_note),
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

// Paste this helper widget at the bottom of your profile.dart file
class AudioWaveform extends StatelessWidget {
  const AudioWaveform({Key? key}) : super(key: key);

  @override Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        15,
            (index) => Container(
          width: 2.5,
          height: (index % 2 == 0 ? 15 : 10) * (Random().nextDouble() + 0.5),
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}
