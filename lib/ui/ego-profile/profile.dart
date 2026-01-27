import 'dart:io';
import 'dart:ui';
import 'package:clairediary/ui/create_session/sound/custom_play_sound_widget.dart';
import 'package:clairediary/widgets/audio_recorder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
  const EgoProfilePage({
    Key? key,
    required this.title,
  }) : super(key: key);

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
    _recordedAudioPath = null;
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
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      showToast("Nickname cannot be empty.");
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .update(
        {
          "nickname": nickname,
        },
      );

      // Update the local user model and refresh the UI
      setState(() {
        userModel.nickname = nickname;
      });

      logger.d('Successfully saved new nickname');
      print('Nickname: $nickname');
      showToast("Ego name updated!");
    } catch (e) {
      logger.e('Error updating nickname: $e');
      showToast("Failed to update ego name.");
    }
  }

  // --- HELPER: SHOW CLAIREVATAR EDIT MODAL ---
  void _showEditClairevatarModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.85,
        minChildSize: 0.6,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Pallet.colorBlack,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: EditClairevatar(
            onAvatarChanged: (newAvatarUrl) {
              // This callback updates the UI without navigating away
              setState(() {
                userModel.avatarUrl = newAvatarUrl;
              });
            },
          ),
        ),
      ),
    );
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
    FirebaseFirestore.instance.collection('ego_stream').add(
      {
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
    await firebaseServices.saveUserActivity(
      activityType: 'mantra', // A new activity type
      activityMessage: "You left a new mantra for yourself, $egoName.",
    );
  }

  /// Save Ego audio mantra

  Future<void> saveEgoAudioMantra(String audioPath) async {
    final egoTime = FieldValue.serverTimestamp();
    final egoName = userModel.nickname;
    final egoImage = userModel.avatarUrl;
    final userId = userModel.userId;
    final senderId = currentUser?.uid;
    FirebaseFirestore.instance.collection('ego_stream').add(
      {
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
      await FirebaseFirestore.instance
          .collection('ego_stream')
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
      adUnitId: Platform.isAndroid
          ? "ca-app-pub-2404156870680632/9680520067"
          : Platform.isIOS
              ? "ca-app-pub-2404156870680632/7910759937"
              : '',
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
      adUnitId: Platform.isAndroid
          ? "ca-app-pub-2404156870680632/2338869057"
          : Platform.isIOS
              ? "ca-app-pub-2404156870680632/5936716173"
              : '',
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
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    Widget continueButton = TextButton(
      child: Text("Okay"),
      onPressed: () {
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

  // --- HELPER: NICKNAME EDIT FIELD (BACK OF CARD) ---
  Widget _buildNicknameEditField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nicknameController,
              cursorColor: Colors.white,
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16),
              decoration: InputDecoration(
                hintText: "...change ego name...",
                hintStyle: GoogleFonts.plusJakartaSans(
                    color: Colors.white38, fontSize: 13),
                border: InputBorder.none,
              ),
              maxLength: 35,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
            onPressed: () {
              if (_nicknameController.text.isNotEmpty) editNickName();
              _nicknameController.clear();
              cardKey2.currentState?.toggleCard();
              HapticFeedback.mediumImpact();
            },
          )
        ],
      ),
    );
  }

  // --- HELPER: MANTRA DISPLAY (FRONT OF CARD) ---
  Widget _buildMantraDisplay() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Dynamic colors for readability
    final mainTextColor = isDarkMode ? Colors.white : Colors.white;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.white60;
    final hintTextColor = isDarkMode ? Colors.white38 : Colors.white38;

    return StreamBuilder<QuerySnapshot>(
      stream: getUserEgoStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Tap to write a mantra you wish to live by...',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    color: secondaryTextColor,
                    fontSize: 13,
                    fontStyle: FontStyle.italic),
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: snapshot.data!.docs.map((doc) {
            Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
            return ListTile(
              dense: true,
              leading: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isDarkMode ? Colors.white10 : Colors.black12,
                      width: 1),
                ),
                child: ClipOval(
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
                          imageUrl: data['egoImage'] ?? "",
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
                                  .withValues(alpha: 0.5),
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
              ),
              title: Text(data['egoName'] ?? "",
                  style: GoogleFonts.plusJakartaSans(
                      color: mainTextColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12)),
              subtitle: data.containsKey('egoAudioMessage')
                  ? CustomPlaySoundWidget(filePath: data['egoAudioMessage'])
                  : Text(data['egoMessage'] ?? '',
                      style: GoogleFonts.plusJakartaSans(
                          color: mainTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
              trailing: IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    color: hintTextColor, size: 18),
                onPressed: () => deleteEgoStreamMessage(doc.id),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // --- HELPER: MANTRA INPUT (BACK OF CARD) ---
  Widget _buildMantraInput() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("NEW MANTRA",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.white70,
                  letterSpacing: 1.1)),
          const SizedBox(height: 8),
          Row(
            children: [
              AudioRecorder(
                onStart: () => setState(() => _mantraController.clear()),
                onStop: (path) => setState(() => _recordedAudioPath = path),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15)),
                  child: TextField(
                    controller: _mantraController,
                    maxLines: 2,
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: _recordedAudioPath != null
                          ? "Audio ready..."
                          : "Write or record...",
                      hintStyle: GoogleFonts.plusJakartaSans(
                          color: Colors.white30, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                onPressed: () {
                  if (_recordedAudioPath != null) {
                    saveEgoAudioMantra(_recordedAudioPath!);
                  } else if (_mantraController.text.isNotEmpty) {
                    saveEgoMantra();
                  }
                  cardKey.currentState?.toggleCard();
                },
                child: Icon(Icons.send_rounded,
                    color: Pallet.colorPrimary, size: 18),
              )
            ],
          ),
        ],
      ),
    );
  }

  // --- FULL PAGE HEADER ---
  Widget _pageHeader({
    String? avatarUrl,
    String? userName,
    String? userType,
    var sessionCount,
    var totalLoveCount,
    var advisesCount,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // FIX: Dynamic colors based on theme to prevent "misty/white" washout
    List<Color> getGlassColors() {
      if (userType == 'REGULAR') {
        return [
          Pallet.colorPrimary,
          Pallet.colorPrimary,
        ];
      } else if (userType == 'ADMIN' || userType == 'SUPER_ADMIN') {
        return [
          Pallet.colorSecondary,
          Pallet.colorSecondary,
        ];
      }
      return [
        isDarkMode
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        Colors.transparent
      ];
    }

    final glassColors = getGlassColors();
    final mainTextColor = isDarkMode ? Colors.white : Colors.white;

    return Container(
      width: getDeviceWidth(context),
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Pallet.colorSecondaryDark : Pallet.colorWhite,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _showEditClairevatarModal,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black87 : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color:
                                isDarkMode ? Colors.white24 : Colors.black12),
                        boxShadow: isDarkMode
                            ? []
                            : [
                                BoxShadow(color: Colors.black12, blurRadius: 4)
                              ]),
                    child: Icon(Icons.edit,
                        size: 14,
                        color: isDarkMode ? Colors.white : Colors.black87),
                  ),
                ),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: glassColors),
                        border: Border.all(
                            color: isDarkMode ? Colors.white24 : Colors.black12,
                            width: 1.5),
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          width: 80,
                          height: 80,
                          imageUrl: avatarUrl ?? "",
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Image.asset(
                              "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                              width: 80,
                              height: 80),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildGlassStat(sessionCount.toString(), "Sessions"),
                      _buildGlassStat(advisesCount.toString(), "Advises"),
                      _buildGlassStat(totalLoveCount.toString(), "Loves"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      height: 44,
                      width: getDeviceWidth(context) * 0.6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: glassColors),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                isDarkMode ? Colors.white24 : Colors.black12),
                      ),
                      child: FlipCard(
                        key: cardKey2,
                        front: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.black87
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: isDarkMode
                                            ? Colors.white24
                                            : Colors.black12),
                                    boxShadow: isDarkMode
                                        ? []
                                        : [
                                            BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 4)
                                          ]),
                                child: Icon(Icons.edit,
                                    size: 14,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87),
                              ),
                              const SizedBox(width: 4),
                              Text(userName ?? "",
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      color: mainTextColor,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        back: _buildNicknameEditField(),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: glassColors),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isDarkMode ? Colors.white10 : Colors.black12)),
                  child: Row(
                    children: [
                      Text(
                        userType == 'SUPER_ADMIN'
                            ? 'SUPER EGO'
                            : userType == 'ADMIN'
                                ? 'ALTER EGO'
                                : 'EGO',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: mainTextColor),
                      ),
                      const SizedBox(width: 4),
                      topBarWidget(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: double.infinity,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: glassColors),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                        color: isDarkMode ? Colors.white24 : Colors.black12,
                        width: 1.5),
                  ),
                  child: FlipCard(
                    key: cardKey,
                    front: _buildMantraDisplay(),
                    back: _buildMantraInput(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassStat(String value, String label) {
    // Dynamic color for text to ensure visibility in light mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.white54 : Colors.black54;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value == "null" || value.isEmpty ? "0" : value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: secondaryTextColor,
          ),
        ),
      ],
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
                        height:
                            150, // Give it a fixed height to avoid layout jumps
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
                                        borderRadius: BorderRadius.circular(25),
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
                                                  fontSize: currentTabIndex != 0
                                                      ? 14
                                                      : 14)),
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
                                        borderRadius: BorderRadius.circular(25),
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
                                                  color: Pallet.colorSecondary,
                                                  fontWeight:
                                                      currentTabIndex != 1
                                                          ? FontWeight.w500
                                                          : FontWeight.w700,
                                                  fontSize: currentTabIndex != 1
                                                      ? 14
                                                      : 14)),
                                          SizedBox(width: 14),
                                          currentTabIndex != 1
                                              ? SizedBox.shrink()
                                              : Icon(
                                                  Icons.monetization_on_rounded,
                                                  color: Pallet.colorSecondary)
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
                                        borderRadius: BorderRadius.circular(25),
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
                                                  fontSize: currentTabIndex != 2
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
                                ActivityWidget(userId: loadedUserModel.userId!),
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

  const AudioPlayerWidget({Key? key, required this.audioPath})
      : super(key: key);

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
                FocusedMenuItem(
                  title: Text(
                    "< SWITCH >",
                    style: TextStyle(color: Pallet.colorSecondary),
                  ),
                  onPressed: () async {
                    String id = await sharedPreference.getAlterEgoId();
                    String accessCode =
                        await sharedPreference.getAlterEgoAccessCode();
                    print("Show Alter details:: $id || $accessCode");
                    id.isNotEmpty && accessCode.isNotEmpty
                        ? await firebaseServices.getUserAlterEgo(
                            context, id, accessCode)
                        : Navigator.of(context)
                            .pushNamed(AppRoutes.alterEgoLogin);
                  },
                ),
                FocusedMenuItem(
                  title: Text(
                    "Lock Out",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onPressed: () async => lockAlertDialog(context),
                ),
                FocusedMenuItem(
                  title: Text(
                    "Delete Account",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onPressed: () async => deleteEgoAlertDialog(context),
                ),
              ],
              onPressed: () {},
              child: Icon(
                Icons.unfold_more_sharp,
                color: Pallet.colorWhite,
                size: 19,
              ))
        ],
      ),
    );
  }
}

lockAlertDialog(BuildContext context) {
  // set up the buttons
  Widget cancelButton = TextButton(
    child: Text("No, Wait."),
    onPressed: () {
      Navigator.of(context).pop();
    },
  );

  Widget continueButton = TextButton(
    child: Text("Yes, Lock Out."),
    onPressed: () {
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
    onPressed: () {
      Navigator.of(context).pop();
    },
  );

  Widget continueButton = TextButton(
    child: Text("YES, DELETE EGO."),
    onPressed: () {
      showToast("Long press to delete account.");
    },
    onLongPress: () {
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
