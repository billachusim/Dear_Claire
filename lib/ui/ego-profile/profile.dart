import 'dart:io';
import 'dart:math';
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
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clairediary/services/user_model.dart';
import 'package:clairediary/ui/ego-profile/activity_widget.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/notification_service.dart';
import '../dairy/archived_diary.dart';
import '../routes/page_router_animation.dart';
import '../splash_screen/rotate_logo.dart';
import '../visited_user_ego_page/visited_user_ego_page.dart';
import 'clairevatar.dart';

class EgoProfilePage extends StatefulWidget {
  final String title;
  final bool showAppBar;
  final ScrollController scrollController;

  const EgoProfilePage({
    Key? key,
    required this.title,
    this.showAppBar = false,
    required this.scrollController,
  }) : super(key: key);

  @override
  _EgoProfilePageState createState() => _EgoProfilePageState();
}

bool _isAvatarLoading = false;
const int maxFailedLoadAttempts = 3;


class _EgoProfilePageState extends State<EgoProfilePage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
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
  bool _showMantraRecorder = false;
  bool _isPermissionCheckComplete = false;
  bool _isPremium = false;
  final ValueNotifier<int> _currentTabIndexNotifier = ValueNotifier<int>(0);


  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final random = Random();
    final initialIndex = random.nextInt(3);

    currentTabIndex = initialIndex;
    _currentTabIndexNotifier.value = initialIndex;

    _userFuture = getUser();
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);

    _userFuture.then((user) {
      if (mounted) {
        setState(() {
          _isPremium = user.isPremium;
        });
        if (!_isPremium) {
          _createEgoNameInterstitialAd();
          _createEgoMantraInterstitialAd();
        }
      }
    });
    _checkInitialPermission();
  }


  @override
  void dispose() {
    _tabController.dispose();
    _currentTabIndexNotifier.dispose();
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

  // --- NEW: Method to check permission ---
  Future<void> _checkInitialPermission() async {
    final status = await Permission.microphone.status;
    if (mounted) {
      setState(() {
        _showMantraRecorder = status.isGranted;
        _isPermissionCheckComplete = true;
      });
    }
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
                Future.delayed(Duration(seconds: 4),
                        () {
                      _showEgoNameInterstitialAd();
                    });
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

  /// Handles microphone permission and visibility for the mantra recorder.
  Future<void> _handleMantraRecordTap() async {
    // 1. Check the current permission status
    final PermissionStatus status = await Permission.microphone.status;

    // 2. Handle the different permission states
    if (status.isGranted) {
      // Permission already granted, show the recorder
      setState(() => _showMantraRecorder = true);
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied, show a dialog to open settings
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Microphone Permission'),
          content: const Text(
              'Microphone permission is required to record your mantra. Please enable it in app settings.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    } else {
      // Request permission for the first time or if previously denied once.
      final PermissionStatus requestStatus = await Permission.microphone.request();
      if (requestStatus.isGranted) {
        setState(() => _showMantraRecorder = true);
      } else {
        // Show a snackbar if permission is denied
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Microphone permission is required to record a mantra.'),
        ));
      }
    }
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
    if (_interstitialAd == null || _isPremium) return;

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
    _interstitialAd = null;
  }

  void _showEgoMantraInterstitialAd() {
    if (_interstitialAd2 == null || _isPremium) return; // <-- Add this check

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
    _interstitialAd2 = null;
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
              Future.delayed(Duration(seconds: 4),
                      () {
                    _showEgoNameInterstitialAd();
                  });
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
                onPressed: () {
                  final String documentId = doc.id;
                  showCustomDialog(context,
                      message: AppString.delete_mantra_alert_note,
                      onPressed: () {
                        deleteEgoStreamMessage(documentId);
                      });
                },
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
              // --- NEW: Conditional Recorder UI ---
              !_isPermissionCheckComplete
                  ? Container(
                height: 48,
                width: 48,
                padding: const EdgeInsets.all(12.0),
                child:
                const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : _showMantraRecorder
                  ? AudioRecorder(
                onStart: () => setState(() {
                  _mantraController.clear();
                  _audioStatusHint = "Recording audio...";
                  _recordedAudioPath = null;
                }),
                onStop: (path) => setState(() {
                  _recordedAudioPath = path;
                  _audioStatusHint = "Audio recorded! Hit send.";
                  _showMantraRecorder = false;
                }),
                onCancel: () => setState(() {
                  _recordedAudioPath = null;
                  _audioStatusHint = "...write a new ego mantra...";
                  _showMantraRecorder = false;                }),
              )
                  : GestureDetector(
                onTap: _handleMantraRecordTap,
                child: Container(
                  height: 48, // Match FAB height
                  width: 48, // Match FAB width
                  decoration: BoxDecoration(
                      color: Pallet.colorWhite, shape: BoxShape.circle),
                  child: Icon(
                    Icons.mic,
                    color: Pallet.colorPrimary,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(width: 8),
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
                        borderRadius:
                        BorderRadius.circular(30),
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: TextField(
                        // The text field is now read-only when an audio path is set
                        readOnly:
                        _recordedAudioPath != null ||
                            _isUploadingAudio,
                        cursorColor:
                        Pallet.colorSplashScreen,
                        keyboardType:
                        TextInputType.multiline,
                        style:
                        TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        controller:
                        _mantraController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(
                              left: 13.0,
                              right: 13.0,
                              top: 10,
                              bottom: 10),
                          // USE THE DYNAMIC HINT TEXT
                          hintText: _audioStatusHint,
                          hintStyle: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.white54,
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
              const SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                onPressed: () {
                  if (_recordedAudioPath != null) {
                    saveEgoAudioMantra(_recordedAudioPath!);
                    // Reset state after saving
                    setState(() {
                      _recordedAudioPath = null;
                      _showMantraRecorder = false;
                    });
                  } else if (_mantraController.text.isNotEmpty) {
                    saveEgoMantra();
                    _mantraController.clear();
                  }
                  cardKey.currentState?.toggleCard();
                  HapticFeedback.mediumImpact();
                  Future.delayed(Duration(seconds: 4),
                          () {
                        _showEgoMantraInterstitialAd();
                      });
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

  Widget _buildContent(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        showToast("Press back again to exit.");
      },
      child: Scaffold(
        appBar: widget.showAppBar
            ? AppBar(
          title: Text(widget.title),
          backgroundColor: Pallet.colorSecondaryDark,
          elevation: 0,
          automaticallyImplyLeading: true,
        )
            : null, // No AppBar if showAppBar is false
        backgroundColor: Pallet.colorSecondaryDark,
        body: NestedScrollView(
          controller: widget.scrollController, // Use controller from parent
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            // These are the widgets that will scroll away (the header)
            return <Widget>[
              // Sliver 1: The main profile header
              SliverToBoxAdapter(
                child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance.collection("users").doc(currentUser?.uid).get(),
                  builder: (_, snapshot) {
                    if (snapshot.hasData) {
                      var data = snapshot.data!.data();
                      // This is your existing _pageHeader method
                      return _pageHeader(
                        userName: data?["nickname"] ?? "Claire's Darling",
                        sessionCount: data?["sessionCount"].toString() ?? "0",
                        advisesCount: data?["adviseCount"].toString() ?? "0",
                        totalLoveCount: data?["totalLoveCount"].toString() ?? "0",
                        userType: data?["userType"] ?? "Ego",
                        avatarUrl: data?["avatarUrl"] ?? " ",
                      );
                    }
                    return SizedBox(
                      height: 150,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
              // Sliver 2: The sticky TabBar
              // In _buildContent, inside the NestedScrollView's headerSliverBuilder:
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  // Your Container of tabs remains the same
                  Container(
                    padding: EdgeInsets.only(top: 5.h, bottom: 5),
                    color: Pallet.colorSecondaryDark,
                    child: Row(
                      children: [
                        _buildTabButton(0, "Activity", Pallet.colorPrimary, Icons.circle_notifications),
                        _buildTabButton(1, "Wallet", Pallet.colorSecondary, Icons.monetization_on_rounded),
                        _buildTabButton(2, "Archive", Pallet.deepGreen, Icons.archive_rounded),
                      ],
                    ),
                  ),
                  _currentTabIndexNotifier, // Pass the notifier here
                ),
                pinned: true,
              ),
            ];
          },
          // This is the content of the tabs
          body: FutureBuilder<UserModel>(
            future: _userFuture,
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: RotateImage(70, 70));
              }
              if (userSnapshot.hasError || !userSnapshot.hasData) {
                return Center(child: Text("Could not load user data.", style: TextStyle(color: Colors.white70)));
              }
              final loadedUserModel = userSnapshot.data!;
              return TabBarView(
                physics: NeverScrollableScrollPhysics(),
                controller: _tabController,
                children: [
                  ActivityWidget(userId: loadedUserModel.userId!),
                  ClaireLoves(),
                  ArchivedDiaryPage(title: 'Diary'),
                ],
              );
            },
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildContent(context);
  }



  Widget _buildTabButton(int index, String text, Color color, IconData icon) {
    return ValueListenableBuilder<int>(
      valueListenable: _currentTabIndexNotifier,builder: (context, currentIndex, child) {
      bool isSelected = currentIndex == index;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            _tabController.animateTo(index);
            _currentTabIndexNotifier.value = index;
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            height: 43,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? color : Pallet.colorWhite,
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: isSelected ? Colors.white : color,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: isSelected ? 14 : 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this.tabBar, this.tabIndexNotifier); // Update constructor
  final Container tabBar;
  final ValueNotifier<int> tabIndexNotifier; // Add this

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Wrap the UI in a ValueListenableBuilder
    return ValueListenableBuilder<int>(
      valueListenable: tabIndexNotifier,
      builder: (context, value, child) {
        // This builder will ONLY run when the notifier's value changes.
        // It rebuilds the tabBar (your Row of buttons) with the new state.
        return tabBar;
      },
    );
  }

  @override
  double get maxExtent => tabBar.padding!.vertical + 43;
  @override
  double get minExtent => tabBar.padding!.vertical + 43;
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar || tabIndexNotifier != oldDelegate.tabIndexNotifier;
  }
}


