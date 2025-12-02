import 'dart:io';
import 'package:clairediary/ui/create_session/sound/custom_play_sound_widget.dart';
import 'package:clairediary/widgets/audio_recorder.dart';
import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
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
import 'package:clairediary/ui/ego-profile/activity_widget.dart';
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
import '../../services/data/notification_model.dart' as push_notification;
import '../../services/notification_service.dart';
import '../routes/page_router_animation.dart';
import '../splash_screen/rotate_logo.dart';
import '../visited_user_ego_page/visited_user_ego_page.dart';
import 'clairevatar.dart';


class EgoProfilePage extends StatefulWidget {
  final String title;
  const EgoProfilePage({Key? key, required this.title,}) : super(key: key);

  @override
  _EgoProfilePageState createState() => _EgoProfilePageState();
}
bool _isAvatarLoading = false;
const int maxFailedLoadAttempts = 3;



class _EgoProfilePageState extends State<EgoProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<UserModel> _userFuture;
  final TextEditingController _mantraController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();
  GlobalKey<FlipCardState> cardKey2 = GlobalKey<FlipCardState>();
  late String mantraUserId;
  late String mantraEgoName;
  String _audioStatusHint = "...write a new ego mantra...";
  String? _recordedAudioPath;
  bool _isUploadingAudio = false;




  @override
  void initState() {
    super.initState();
    _userFuture = getUser();
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

  Future<UserModel> getUser() async {
    userModel = await firebaseServices.getUserInfo();
    return userModel;
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
    FirebaseFirestore.instance
        .collection('ego_stream')
        .add({
      "egoAudioMessage": audioPath,
      "egoTime": egoTime,
      "egoName": egoName,
      "egoImage": egoImage,
      "userId": userId,
      "senderId": senderId,
    },
      //SetOptions(merge: true)
    );
    logger.d('Successfully saved your Ego audio message');
    print('Ego Audio Message: $audioPath');

  }


  /// Delete an ego message

  Future<void> deleteEgoStreamMessage(String documentId) async {
    try {
      await FirebaseFirestore.instance        .collection('ego_stream')
          .doc(documentId)
          .delete();
      logger.d('Successfully deleted ego stream message: $documentId');
      showToast("Message deleted");
    } catch (e) {
      logger.e('Error deleting ego stream message: $e');
      showToast("Failed to delete message");
    }
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





  /// Profile Cover header

  Widget _pageHeader(
      {String? avatarUrl, String? userName, String? userType,
        var sessionCount, var totalLoveCount, var advisesCount})
  {
    // Determine if the current theme is dark
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Define colors based on the theme
    Color getCardBackgroundColor() {
      if (userType == 'REGULAR') {
        return isDarkMode ? Pallet.colorPrimary : Colors.white;
      } else if (userType == 'ADMIN' || userType == 'SUPER_ADMIN') {
        return isDarkMode ? Pallet.colorSecondary : Colors.white;
      }
      // Default fallback
      return isDarkMode ? Color(0xFF2C2C2E) : Colors.white;
    }

    final cardBackgroundColor = getCardBackgroundColor();    final cardTextColor = isDarkMode ? Colors.white : Colors.black;
    final hintTextColor = isDarkMode ? Colors.white54 : Colors.black54;


    return Material(
      color: Colors.transparent, // Use transparent to show the container's decoration
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              AppImages.appChatBg,
            ),
            fit: BoxFit.fill,
          ),
        ),
        width: getDeviceWidth(context),
        margin: EdgeInsets.only(bottom: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Edit Clairevatar icon is here
                      GestureDetector(
                        onTap: () {
                          Navigator.pushAndRemoveUntil<dynamic>(
                            context,
                            MaterialPageRoute<dynamic>(
                              builder: (BuildContext context) => EditClairevatar(),
                            ),
                                (route) => false,//if you want to disable back feature set to false
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: userType == 'REGULAR'? Pallet.colorPrimary
                                  : userType == 'ADMIN'? Pallet.colorSecondary
                                  : userType == 'SUPER_ADMIN'?  Pallet.colorSecondary
                                  :Pallet.colorBlue,
                              borderRadius: BorderRadius.circular(100)
                          ),
                          height: 22,
                          width: 20,
                          margin: EdgeInsets.only(left: 4),
                          child: IconButton(
                              padding: EdgeInsets.only(right: 1),
                              icon: Icon(Icons.edit),
                              iconSize: 15,
                              color: Pallet.colorWhite,
                              onPressed: () {
                                Navigator.of(context)
                                    .pushNamed(AppRoutes.editClairevatar);
                              }
                          ),
                        ),
                      ),

                      //Clairevatar Container is here
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context)
                              .pushNamed(AppRoutes.editClairevatar);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: userType == 'REGULAR'? Pallet.colorPrimary
                                : userType == 'ADMIN'? Pallet.colorSecondary
                                : userType == 'SUPER_ADMIN'?  Pallet.colorSecondary
                                :Pallet.colorBlue,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          margin: EdgeInsets.only(left: 0),
                          child: Container(
                            height: 75,
                            width: 75,
                            margin: EdgeInsets.all(4),
                            child: CachedNetworkImage(
                                width: 70,
                                height: 70,
                                imageUrl: avatarUrl ??"",
                                imageBuilder: (context, imageProvider) => Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(100),
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),
                                placeholder: (context, url) =>
                                    CircularProgressIndicator(),
                                errorWidget: (context, url, error) => Image.asset(
                                  "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                                  width: 50,
                                  height: 50,
                                ) //Icon(Icons.error),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // The count columns (stats cards) are here
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(sessionCount, "Sessions", userType, context),
                        _buildStatCard(advisesCount, "Advises", userType, context),
                        _buildStatCard(totalLoveCount, "Loves", userType, context),
                      ],
                    ),
                  ),
                  SizedBox(width: 6,),
                ],
              ),
            ),



            /// Nickname and edit nickname FlipCard method

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                Container(
                  margin: EdgeInsets.all(4),
                  height: 40,
                  width: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                    color: userType == 'REGULAR'? Pallet.colorPrimary
                        : userType == 'ADMIN'? Pallet.colorSecondary
                        : userType == 'SUPER_ADMIN'?  Pallet.colorSecondary
                        :Pallet.colorBlue,
                  ),
                  child: FlipCard(
                    key: cardKey2,
                    direction: FlipDirection.VERTICAL, // default
                    front: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: cardBackgroundColor,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          margin: EdgeInsets.only(left: 17, right: 4, top: 4, bottom: 4),
                          alignment: Alignment.centerLeft,
                          width: 250,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              SizedBox(width: 4,),

                              Text(
                                userName ??"",
                                style: TextStyle(
                                    fontSize: 18,
                                    color: cardTextColor,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),

                        Icon(Icons.edit_rounded,
                          color: Pallet.colorWhite,
                          size: 16,
                        ),

                      ],
                    ),
                    back: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          margin: EdgeInsets.only(left: 4),
                          height: 40,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: Pallet.colorPrimary),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                new ConstrainedBox(
                                  constraints: new BoxConstraints(
                                    minWidth: 125,
                                    maxWidth: 190,
                                    minHeight: 40.0,
                                    maxHeight: 60.0,
                                  ),
                                  child: new Scrollbar(
                                    child: Container(
                                      padding: EdgeInsets.zero,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        color: cardBackgroundColor,
                                      ),
                                      child: TextField(
                                        cursorColor: Pallet.colorSplashScreen,
                                        keyboardType: TextInputType.text,
                                        style: TextStyle(color: cardTextColor),
                                        maxLines: 1,
                                        controller: _nicknameController,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding:
                                          EdgeInsets.only(left: 13.0, bottom: 18, right: 13.0),
                                          hintText: "...change ego name...",
                                          hintStyle: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: hintTextColor,
                                            fontSize: 13,
                                          ),
                                          counterText: '',
                                        ),
                                        maxLength: 35,
                                      ),
                                    ),
                                  ),
                                ),

                                FloatingActionButton(
                                  heroTag: "edit_nickname",
                                    mini: true,
                                    backgroundColor: Pallet.colorWhite,
                                    child: SvgPicture.asset(
                                      AppImages.appSend,
                                      colorFilter: ColorFilter.mode(Pallet.colorPrimary, BlendMode.srcIn),
                                      height: 20,
                                    ),
                                    onPressed: () {
                                      if (_nicknameController.text.isNotEmpty)
                                        editNickName();
                                      _nicknameController.clear();
                                      if(cardKey2.currentState != null) { //null safety
                                        cardKey2.currentState!.toggleCard();
                                      }
                                      setState(() {

                                      });
                                      showToast(AppString.change_ego_name);

                                      Future.delayed(Duration(seconds: 3), () {
                                        _showEgoNameInterstitialAd();
                                      });
                                    }
                                ),

                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Spacer(flex: 1,),


                /// Here is the Ego badge showing user's usertype

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.only(
                              left: 8, right: 4, top: 4, bottom: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: userType == 'REGULAR'? Pallet.colorPrimary
                                : userType == 'ADMIN'? Pallet.colorSecondary
                                : userType == 'SUPER_ADMIN'?  Pallet.colorSecondary
                                :Pallet.colorBlue,
                          ),
                          child: Row(
                            children: [
                              Text(
                                userType == 'REGULAR'? 'Ego' :
                                userType == 'ADMIN'? 'Alter Ego' :
                                userType == 'SUPER_ADMIN'? 'Super Ego' :
                                'Ego',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              topBarWidget(),
                            ],
                          ),
                        ),
                        SizedBox(width: 6,)
                      ],
                    ),


                    SizedBox(height: 3,),

                    /// Flagged user label

                    Visibility(
                      visible: userModel.flagged == true,
                      child: GestureDetector(
                        onTap: () {
                          if (userModel.flagged == true)
                            flagEgoAlertDialog(context);
                        },
                        child: Container(
                          margin: EdgeInsets.only(right: 6),
                          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 5),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Pallet.colorPrimaryDark,
                              )),
                          child: Row(
                            children: [
                              Icon(
                                userModel.flagged == true ? Icons.flag : Icons.flag_outlined,
                                color: Pallet.colorPrimaryDark,
                                size: 15,
                              ),
                              SizedBox(width: 2,),
                              Text(
                                "You Are Flagged!",
                                style: GoogleFonts.lato(
                                    fontSize: 11.0,
                                    color: Pallet.colorPrimaryDark,
                                    fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),


                  ],
                ),
              ],
            ),

            SizedBox(
              height: 2,
            ),



            /// Front card: Write Ego mantra and send to stream


        Container(
          width: getDeviceWidth(context),
          height: 100,
          margin: EdgeInsets.only(left: 4, right: 4, bottom: 4),
          child: FlipCard(
              key: cardKey,
              direction: FlipDirection.HORIZONTAL, // default
              back: SingleChildScrollView( // Fixes bottom overflow
                physics: NeverScrollableScrollPhysics(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: userType == 'REGULAR'
                            ? Pallet.colorPrimary
                            : userType == 'ADMIN'
                            ? Pallet.colorSecondary
                            : userType == 'SUPER_ADMIN'
                            ? Pallet.colorSecondary
                            : Pallet.colorBlue,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                userType == 'REGULAR'
                                    ? 'Ego Stream:'
                                    : userType == 'ADMIN'
                                    ? 'Alter Ego Stream:'
                                    : userType == 'SUPER_ADMIN'
                                    ? 'Super Ego Stream:'
                                    : '',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: 3),
                            Row(
                              children: [
                                AudioRecorder(
                                  onStart: () {
                                    // When recording starts, update the UI
                                    setState(() {
                                      _recordedAudioPath = null;
                                      _audioStatusHint = "Recording audio...";
                                      _mantraController.clear(); // Clear text field
                                    });
                                  },
                                  onStop: (String path) {
                                    // When recording stops, store the path and update the hint
                                    setState(() {
                                      _recordedAudioPath = path;
                                      _audioStatusHint = "Audio recorded! Hit send.";
                                    });
                                  },
                                  onCancel: () {
                                    // If recording is cancelled, reset everything
                                    setState(() {
                                      _recordedAudioPath = null;
                                      _audioStatusHint = "...write a new ego mantra...";
                                    });
                                  },
                                ),
                                Expanded(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: getDeviceWidth(context),
                                      maxWidth: getDeviceWidth(context),
                                      minHeight: 50.0,
                                      maxHeight: 90.0,
                                    ),
                                    child: Scrollbar(
                                      child: Container(
                                        padding: EdgeInsets.zero,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(30),
                                          color: cardBackgroundColor,
                                        ),
                                        child: TextField(
                                          // Make field read-only when recording or uploading
                                          readOnly: _recordedAudioPath != null || _isUploadingAudio,
                                          cursorColor: Pallet.colorSplashScreen,
                                          keyboardType: TextInputType.multiline,
                                          style: TextStyle(color: cardTextColor),
                                          maxLines: 2,
                                          controller: _mantraController, // Use your profile's controller
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.only(
                                                left: 13.0,
                                                right: 13.0,
                                                top: 10,
                                                bottom: 10),
                                            // Use the dynamic hint text from your state
                                            hintText: _audioStatusHint,
                                            hintStyle: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: hintTextColor,
                                              fontSize: 14,
                                            ),
                                            counterText: '',
                                          ),
                                          maxLength: 160,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                FloatingActionButton(
                                    onPressed: () {
                                      // --- NEW SMART SEND LOGIC ---
                                      // Check if we are sending an AUDIO message
                                      if (_recordedAudioPath != null) {
                                        if (_isUploadingAudio) return; // Prevent double taps

                                        setState(() {
                                          _isUploadingAudio = true;
                                          _audioStatusHint = "Uploading audio...";
                                        });

                                        // Call your audio save method
                                        saveEgoAudioMantra(_recordedAudioPath!).then((_) {
                                          showToast(AppString.change_ego_mantra);
                                          setState(() {
                                            _isUploadingAudio = false;
                                            _recordedAudioPath = null;
                                            _audioStatusHint = "...write a new ego mantra...";
                                          });
                                          if (cardKey.currentState?.isFront == false) {
                                            cardKey.currentState!.toggleCard();
                                          }
                                          Future.delayed(Duration(seconds: 4), () {
                                            _showEgoMantraInterstitialAd();
                                          });
                                        });
                                      }
                                      // Check if we are sending a TEXT message
                                      else if (_mantraController.text.trim().isNotEmpty) {
                                        if (userModel.nickname != null) {
                                          saveEgoMantra();
                                          _mantraController.clear();

                                          if (cardKey.currentState?.isFront == false) {
                                            cardKey.currentState!.toggleCard();
                                          }
                                          showToast(AppString.change_ego_mantra);
                                          Future.delayed(Duration(seconds: 4), () {
                                            _showEgoMantraInterstitialAd();
                                          });
                                        }
                                      }
                                      // If neither is ready
                                      else {
                                        showToast("Write a mantra or record audio.");
                                      }
                                    },
                                    mini: true,
                                    backgroundColor: Pallet.colorWhite,
                                    child: SvgPicture.asset(
                                      AppImages.appSend,
                                      colorFilter: ColorFilter.mode(
                                          Pallet.colorPrimary, BlendMode.srcIn),
                                      height: 20,
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),



        /// Back of card is Ego Stream for display


                front: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(25)),
                        color: userType == 'REGULAR'? Pallet.colorPrimary
                            : userType == 'ADMIN'? Pallet.colorSecondary
                            : userType == 'SUPER_ADMIN'?  Pallet.colorSecondary
                            :Pallet.colorBlue,
                      ),
                    ),

                    /// Build Ego stream from Firebase on a ListView

                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        children: [
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: getUserEgoStream(),
                              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                                if (snapshot.hasError) {
                                  return Text('Something went wrong');
                                }
                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Text('Write a mantra that you wish to live by currently by tapping on this space',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.white, fontSize: 14),),
                                    ),
                                  );
                                }

                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Center(child: Text("Loading", style: TextStyle(color: Colors.white)));
                                }

                                return ListView(
                                  children: snapshot.data!.docs.map((DocumentSnapshot document) {
                                    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                                    return ListTile(
                                      leading: ClipOval(
                                        child: GestureDetector(
                                          onTap: () async {
                                            setState(() {
                                              _isAvatarLoading = true;
                                            });
                                            try {
                                            // --- 1. SETUP TRANSACTION DETAILS ---
                                            final visitingUser = await firebaseServices.getUserInfo();
                                            final String visitedUserId = data['senderId'].toString();
                                            final String visitedEgoName = data['egoName'].toString();
                                            const int visitCost = 1;
                                            // --- 2. HANDLE SELF-VISIT ---
                                            if (visitingUser.userId == visitedUserId) {
                                              // If visiting self, just navigate without a transaction.
                                              PageRouter.gotoWidget(
                                                  VisitedUserEgoProfilePage(
                                                      visitedUsersID: visitedUserId,
                                                      visitedEgoName: visitedEgoName),
                                                  context);
                                              return;
                                            }

                                            // --- 3. CHECK PERMISSIONS & SUFFICIENT LOVES ---
                                            // Note: The permission message was slightly different, so I've used the more descriptive one from the avatar's logic.
                                            if (visitingUser.userType == "REGULAR" &&
                                                visitingUser.currentLoveCount < 500) { // Changed from 50 to 500 for consistency
                                              showToast("Need up to 500 Loves or Alter Ego to view other Ego Profiles.");
                                              return;
                                            }

                                            if (visitingUser.currentLoveCount < visitCost) {
                                              showToast("You need at least 1 ❤️ to visit a profile.");
                                              return;
                                            }

                                            // --- 4. PERFORM THE LOVE TRANSACTION ---
                                            final bool success =
                                            await firebaseServices.transferLoveBetweenUsers(
                                              senderId: visitingUser.userId!,
                                              receiverId: visitedUserId,
                                              amountToSend: visitCost,
                                              taxAmount: 0,
                                              totalDebitAmount: visitCost,
                                              senderTransactionDesc:
                                              "1❤️ for visiting ${visitedEgoName}'s Ego.",
                                              receiverTransactionDesc:
                                              "Received 1❤️ from ${visitingUser.nickname} visiting your Ego.",
                                              claireTransactionDesc:
                                              "Tax from a profile visit.", // Will be 0, but required
                                              forProfileVisits: 1, // Stat for the sender
                                              fromProfileVisits: 1, // Stat for the receiver
                                              metadata: {
                                                'reason': 'profile_visit',
                                                'visitedUserId': visitedUserId
                                              },
                                            );

                                            // --- 5. NAVIGATE ON SUCCESS ---
                                            if (success) {
                                              showToast("You are visiting ${visitedEgoName} with a kola of 1❤️.");

                                              // --- START TARGETED NOTIFICATION LOGIC ---
                                              try {
                                                // We already have the visiting user's info, now get the visited user's token.
                                                final receiverDoc = await FirebaseFirestore.instance.collection('users').doc(visitedUserId).get();
                                                if (receiverDoc.exists) {
                                                  final receiverToken = receiverDoc.data()?['fcmId'] as String?;
                                                  final senderName = visitingUser.nickname ?? 'A user';

                                                  if (receiverToken != null && receiverToken.isNotEmpty) {
                                                    await notificationService.sendNotification({
                                                      "token": receiverToken,
                                                      "notification": {
                                                        "title": "Your Ego profile has a visitor!",
                                                        "body": "$senderName just visited your profile with a kola of 1❤️."
                                                      },
                                                      "data": {
                                                        // Navigate the user to their own profile page to see the updated stats.
                                                        "route": "egoPage"
                                                      }
                                                    });
                                                  }
                                                }
                                              } catch (e) {
                                                print("Error sending profile visit notification: $e");
                                                // Don't block the user flow if notifications fail.
                                              }
                                              // --- END TARGETED NOTIFICATION LOGIC ---

                                              // --- NAVIGATE ---
                                              // Only navigate to the profile if the transaction was successful.
                                              PageRouter.gotoWidget(
                                                  VisitedUserEgoProfilePage(
                                                      visitedUsersID: visitedUserId,
                                                      visitedEgoName: visitedEgoName),
                                                  context);
                                            }
                                            } finally {
                                              // --- 3. HIDE THE LOADER (GUARANTEED) ---
                                              // This runs no matter how the try block exits.
                                              if (mounted) {
                                                setState(() {
                                                  _isAvatarLoading = false;
                                                });
                                              }
                                            }
                                          },
                                          child: Stack(
                                            children: [
                                              CachedNetworkImage(
                                                width: 40,
                                                height: 40,
                                                imageUrl: data['egoImage'],
                                                imageBuilder: (context, imageProvider) => Container(
                                                  decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.fill,
                                                    ),
                                                  ),
                                                ),
                                                placeholder: (context, url) =>
                                                    CircularProgressIndicator(),
                                                errorWidget: (context, url, error) => Image.asset(
                                                  "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                                                  width: 30,
                                                  height: 30,
                                                ),
                                              ),
                                              if (_isAvatarLoading)
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.5),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Center(
                                                    child:
                                                    CupertinoActivityIndicator(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      title: Row(
                                        // Use baseline alignment for perfect vertical text alignment
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic, // Required for baseline alignment
                                        children: [
                                          Text(
                                            data['egoName'].toString(),
                                            style: GoogleFonts.lato( // Using GoogleFonts.lato for consistency
                                              color: Colors.white, // Increased contrast for better readability
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold, // Make the name stand out
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          // Display the formatted timestamp
                                          Expanded(
                                            child: Text(
                                              // Check if egoTime exists and is a Timestamp
                                              (data['egoTime'] is Timestamp)
                                                  ? formatFirestoreTimestamp(data['egoTime'])
                                                  : '', // Show nothing if data is invalid
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.lato( // Using GoogleFonts.lato
                                                color: Colors.white60, // Slightly dimmed for hierarchy
                                                fontSize: 11,
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: data.containsKey('egoAudioMessage') ? CustomPlaySoundWidget(filePath: data['egoAudioMessage']) :
                                      Text(data['egoMessage'] ?? '',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      trailing: GestureDetector(
                                        onTap: () {
                                          // Get the unique document ID
                                          final String documentId = document.id;

                                          showCustomDialog(context,
                                              message: AppString.delete_mantra_alert_note,
                                              onPressed: () {
                                                PageRouter.goBack(context);
                                                // Call the new universal delete method
                                                deleteEgoStreamMessage(documentId);
                                              });
                                        },
                                        child: Icon(
                                          Icons.delete_forever_rounded,
                                          color: Colors.white70,
                                          size: 18,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Helper widget for the stat cards
  Widget _buildStatCard(var count, String label, String? userType, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Color getCardBackgroundColor() {
      if (userType == 'REGULAR') {
        return isDarkMode ? Pallet.colorPrimary : Colors.white;
      } else if (userType == 'ADMIN' || userType == 'SUPER_ADMIN') {
        return isDarkMode ? Pallet.colorSecondary : Colors.white;
      }
      // Default fallback
      return isDarkMode ? Color(0xFF2C2C2E) : Colors.white;
    }

    final cardBackgroundColor = getCardBackgroundColor();
    final cardTextColor = isDarkMode ? Colors.white : Colors.black;
    final labelTextColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Card(
      elevation: 4,
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: (getDeviceWidth(context) / 4) - 16,
        height: 60,
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              count ?? "---",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: cardTextColor),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: labelTextColor),
            ),
          ],
        ),
      ),
    );
  }







  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
          showToast("Press back again to exit.");
        },
        child: Scaffold(
          backgroundColor: Pallet.colorSecondaryDark,
          body: Column(
            children: [
              // This part for the header can remain as it is, as it has its own FutureBuilder
              Material(
                elevation: 10,
                child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
                        totalLoveCount:
                        data?["totalLoveCount"].toString() ?? "0",
                        userType: data?["userType"] ?? "Ego",
                        avatarUrl: data?["avatarUrl"] ?? " ",
                      );
                    }
                    // Show a placeholder or compact loader while the header loads
                    return SizedBox(
                        height: 150, // Give it a fixed height to avoid layout jumps
                        child: Center(child: CircularProgressIndicator()));
                  },
                ),
              ),

              // --- THE FIX IS APPLIED HERE ---
              // We wrap the part of the UI that needs the userModel in a FutureBuilder
              Expanded(
                child: FutureBuilder<UserModel>(
                  future: _userFuture,
                  builder: (context, userSnapshot) {
                    // While waiting for the user data, show a single loading indicator
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: RotateImage(70, 70));
                    }

                    // If we failed to get the user data, show an error
                    if (userSnapshot.hasError || !userSnapshot.hasData) {
                      return Center(
                          child: Text("Could not load user data.",
                              style: TextStyle(color: Colors.white70)));
                    }

                    // SUCCESS: We have the user data!
                    final loadedUserModel = userSnapshot.data!;

                    // Now, we can build the rest of the UI with confidence
                    return DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          SizedBox(height: 7.h),
                          // Your custom Tab Bar UI
                          Container(
                            decoration: BoxDecoration(),
                            child: Row(children: [
                              // Activity Tab Button
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
                                            color: Pallet.colorPrimary,
                                            width: 3)
                                            : Border.all(
                                            color: Pallet.colorPrimary,
                                            width: 6),
                                        borderRadius:
                                        BorderRadius.circular(25),
                                        color: currentTabIndex != 0
                                            ? Pallet.colorWhite
                                            : Pallet.colorWhite),
                                    child: Padding(
                                      padding: const EdgeInsets.all(3.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text("Activity",
                                              style: TextStyle(
                                                  color: Pallet.colorPrimary,
                                                  fontWeight:
                                                  currentTabIndex != 0
                                                      ? FontWeight.w500
                                                      : FontWeight.w700,
                                                  fontSize:
                                                  currentTabIndex != 0
                                                      ? 14
                                                      : 14)),
                                          SizedBox(width: 14),
                                          currentTabIndex != 0
                                              ? SizedBox.shrink()
                                              : Icon(
                                              Icons
                                                  .circle_notifications,
                                              color: Pallet.colorPrimary)
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Wallet (Claire Love) Tab Button
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
                                            color: Pallet.colorSecondary,
                                            width: 3)
                                            : Border.all(
                                            color: Pallet.colorSecondary,
                                            width: 6),
                                        borderRadius:
                                        BorderRadius.circular(25),
                                        color: currentTabIndex != 1
                                            ? Pallet.colorWhite
                                            : Pallet.colorWhite),
                                    child: Padding(
                                      padding: const EdgeInsets.all(3.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text("Wallet",
                                              style: TextStyle(
                                                  color:
                                                  Pallet.colorSecondary,
                                                  fontWeight:
                                                  currentTabIndex != 1
                                                      ? FontWeight.w500
                                                      : FontWeight.w700,
                                                  fontSize:
                                                  currentTabIndex != 1
                                                      ? 14
                                                      : 14)),
                                          SizedBox(width: 14),
                                          currentTabIndex != 1
                                              ? SizedBox.shrink()
                                              : Icon(
                                              Icons
                                                  .monetization_on_rounded,
                                              color:
                                              Pallet.colorSecondary)
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Archive Tab Button
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
                                            color: Pallet.deepGreen,
                                            width: 3)
                                            : Border.all(
                                            color: Pallet.deepGreen,
                                            width: 6),
                                        borderRadius:
                                        BorderRadius.circular(25),
                                        color: currentTabIndex != 2
                                            ? Pallet.colorWhite
                                            : Pallet.colorWhite),
                                    child: Padding(
                                      padding: const EdgeInsets.all(3.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text("Archive",
                                              style: TextStyle(
                                                  color: Pallet.deepGreen,
                                                  fontWeight:
                                                  currentTabIndex != 2
                                                      ? FontWeight.w500
                                                      : FontWeight.w700,
                                                  fontSize:
                                                  currentTabIndex != 2
                                                      ? 14
                                                      : 14)),
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
                            ]),
                          ),

                          // The TabBarView that contains the widgets
                          Expanded(
                            child: TabBarView(
                              physics: NeverScrollableScrollPhysics(),
                              controller: _tabController,
                              children: [
                                // Pass the CORRECT userId from the loaded data
                                ActivityWidget(
                                    userId: loadedUserModel.userId!),
                                ClaireLoves(),
                                ArchiveWidget(),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
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
      await _audioPlayer.setFilePath(widget.audioPath);
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
