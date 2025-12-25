import 'dart:io';
import 'package:clairediary/widgets/audio_recorder.dart';
import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/ui/featured/notified_session_details.dart';
import 'package:clairediary/ui/visited_user_ego_page/visited_profile_page_model.dart';
import 'package:clairediary/ui/visited_user_ego_page/visited_user_claireloves.dart';
import 'package:clairediary/ui/visited_user_ego_page/visited_user_model.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:clairediary/widgets/toast.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/ui/splash_screen/rotate_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../Admob/ad_state.dart';
import '../../helpers/toast_helper.dart' as CustomToast;
import '../../services/notification_service.dart';
import '../../widgets/pre_call_dialog.dart';
import '../alter_ego/alter_ego_calls_page.dart';
import '../call/admin_call_page.dart';
import '../call/admin_live_call_page.dart';
import '../create_session/sound/custom_play_sound_widget.dart';
import '../ego-profile/activity_widget.dart';
import '/services/data/notification_model.dart' as pushNotification;
import '../../services/user_activity_model.dart';
import '../../services/user_model.dart';
import '../../widgets/ego_mode_session_card.dart';
import '../featured/model/comment_session_model.dart';
import '../featured/model/session.dart';
import '../routes/page_router_animation.dart';

class VisitedUserEgoProfilePage extends StatefulWidget {
  final String visitedUsersID;
  final String visitedEgoName;

  VisitedUserEgoProfilePage(
      {Key? key, required this.visitedUsersID, required this.visitedEgoName})
      : super(key: key);

  @override
  _VisitedUserEgoProfilePageState createState() =>
      _VisitedUserEgoProfilePageState();
}

bool _isAvatarLoading = false;
const int maxFailedLoadAttempts = 3;

class _VisitedUserEgoProfilePageState extends State<VisitedUserEgoProfilePage>
    with SingleTickerProviderStateMixin {
  late Future<List<UserActivityModel>> _userActivitiesFuture;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _userSessionsStream;
  late TabController _tabController;
  final TextEditingController _visitorMantraController =
      TextEditingController();
  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();
  GlobalKey<FlipCardState> cardKey2 = GlobalKey<FlipCardState>();

  /// create instance of FirebaseMessaging
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  int currentTabIndex = 0;
  User? currentUser = FirebaseAuth.instance.currentUser;
  VisitedUserModel? visitedUser = VisitedUserModel();
  String? visitedUsersID;
  List<Session>? _sessionList = [];
  UserModel? _visitingUser = UserModel();
  bool? isFlagged;
  bool _isLoading = true;
  String _audioStatusHint = "...write a new ego mantra...";
  String? _recordedAudioPath;
  bool _isUploadingAudio = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _userActivitiesFuture = getActivityByVisitedUser();
    _userSessionsStream = visitedUsersSessions();
    _createEgoMantraInterstitialAd();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
    _interstitialAd2?.dispose();
  }

  // Admob Ad Units.
  BannerAd? visitedUserTopOfSessionsBanner;
  BannerAd? visitedUserBottomOfSessionsBanner;
  BannerAd? visitedUserTopOfActivitiesBanner;
  BannerAd? visitedUserBottomOfActivitiesBanner;
  bool _isTopOfSessionsBannerLoaded = false;
  bool _isBottomOfSessionsBannerLoaded = false;
  bool _isTopOfActivitiesBannerLoaded = false;
  bool _isBottomOfActivitiesBannerLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // We can remove the _areAdsInitialized check to allow for reloading if needed,
    // since the individual loaded flags will prevent crashes.
    final adState = Provider.of<AdState>(context);

    adState.initialization.then((status) {
      setState(() {
        // --- Load Top of Sessions Banner ---
        visitedUserTopOfSessionsBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.visitedUserTopOfSessionBannerAdUnitId,
            request: AdRequest(),
            listener: BannerAdListener(
              onAdLoaded: (ad) {
                print('Ad loaded: ${ad.adUnitId}');
                setState(() {
                  _isTopOfSessionsBannerLoaded = true;
                });
              },
              onAdFailedToLoad: (ad, error) {
                print('Ad failed to load: ${ad.adUnitId}, error: $error');
                ad.dispose();
              },
            ))
          ..load();

        // --- Load Bottom of Sessions Banner ---
        visitedUserBottomOfSessionsBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.visitedUserBottomOfSessionsBannerAdUnitId,
            request: AdRequest(),
            listener: BannerAdListener(
              onAdLoaded: (ad) {
                print('Ad loaded: ${ad.adUnitId}');
                setState(() {
                  _isBottomOfSessionsBannerLoaded = true;
                });
              },
              onAdFailedToLoad: (ad, error) {
                print('Ad failed to load: ${ad.adUnitId}, error: $error');
                ad.dispose();
              },
            ))
          ..load();

        // --- Load Top of Activities Banner ---
        visitedUserTopOfActivitiesBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.visitedUserTopOfActivitiesBannerAdUnitId,
            request: AdRequest(),
            listener: BannerAdListener(
              onAdLoaded: (ad) {
                print('Ad loaded: ${ad.adUnitId}');
                setState(() {
                  _isTopOfActivitiesBannerLoaded = true;
                });
              },
              onAdFailedToLoad: (ad, error) {
                print('Ad failed to load: ${ad.adUnitId}, error: $error');
                ad.dispose();
              },
            ))
          ..load();

        // --- Load Bottom of Activities Banner ---
        visitedUserBottomOfActivitiesBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.visitedUserBottomOfActivitiesBannerAdUnitId,
            request: AdRequest(),
            listener: BannerAdListener(
              onAdLoaded: (ad) {
                print('Ad loaded: ${ad.adUnitId}');
                setState(() {
                  _isBottomOfActivitiesBannerLoaded = true;
                });
              },
              onAdFailedToLoad: (ad, error) {
                print('Ad failed to load: ${ad.adUnitId}, error: $error');
                ad.dispose();
              },
            ))
          ..load();
      });
    });
  }

  Future<void> _fetchInitialData() async {
    try {
      // --- 1. FETCH BOTH USERS' DATA CONCURRENTLY ---
      // This is more efficient than awaiting them one by one.
      final results = await Future.wait([
        getVisitingUserInfo(), // Fetches the current user
        getVisitedUserInfo(), // Fetches the user whose profile is being viewed
      ]);

      // Safely cast the results
      final UserModel fetchedVisitingUser = results[0] as UserModel;
      final VisitedUserModel fetchedVisitedUser =
          results[1] as VisitedUserModel;

      // --- 2. SAVE THE VISIT ACTIVITY ---
      // Now you have the visiting user's nickname to use in the message.
      await firebaseServices.saveUserActivity(
        activityType: 'visit_ego',
        activityMessage: "${fetchedVisitingUser.nickname ?? 'You'} visited ${fetchedVisitedUser.nickname ?? 'A Darling'}'s Ego",
        recipientId: widget.visitedUsersID,
        recipientNickname: widget.visitedEgoName,
      );

      // --- 3. UPDATE STATE AND TURN OFF LOADING ---
      // This is the crucial part. We update the state with ALL fetched data at once.
      if (mounted) {
        setState(() {
          _visitingUser = fetchedVisitingUser; // Now this is set immediately
          visitedUser = fetchedVisitedUser; // And this is set too
          _isLoading = false; // Turn off loading AFTER data is set
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false; // Also turn off loading on error
        });
      }
      logger.e("Failed to fetch initial data: $e");
      CustomToast.showToast(message: "Failed to load profile data.");
    }
  }

  /// Get Visiting Ego User info
  Future<UserModel> getVisitingUserInfo() async {
    DocumentSnapshot response = await FirebaseFirestore.instance
        .collection(AppString.users)
        .doc(currentUser?.uid)
        .get();

    var visitingUser =
        UserModel.fromFirestore(response.data() as Map<String, dynamic>);
    logger.d('Successfully got the visiting user model');
    return visitingUser;
  }


  void _initiateCallToUser({required bool isVideoCall}) async {
    // 1. Show the pre-call setup dialog
    final callDetails = await showPreCallDialog(context, isVideoCall: isVideoCall);

    // 2. Check if the user cancelled
    if (callDetails == null) {
      print("Admin cancelled call setup.");
      return;
    }

    // 3. Prepare call data with reversed roles
    final Uuid uuid = Uuid();
    final callId = uuid.v4();
    final collectionName = isVideoCall ? 'live_sessions' : 'companion_calls';
    final channelName = isVideoCall ? 'live_session_$callId' : 'companion_call_$callId';
    final adminId = currentUser?.uid; // The admin is the caller
    final recipientId = widget.visitedUsersID; // The visited user is the receiver

    if (adminId == null) {
      showToast("Authentication error. Cannot place call.");
      return;
    }

    // 4. Create the call document in Firestore
    try {
      await FirebaseFirestore.instance.collection(collectionName).doc(callId).set({
        'callerId': adminId, // Admin is the caller
        'receiverId': recipientId, // User is the receiver
        'channelName': channelName,
        'status': 'dialing',
        'createdAt': FieldValue.serverTimestamp(),
        'recordingUrl': null,
        // --- Details from the dialog ---
        'title': callDetails.title,
        'moodId': callDetails.moodId,
        'isPrivate': callDetails.isPrivate,
        'repliesEnabled': callDetails.repliesEnabled,
        'locationEnabled': callDetails.locationEnabled,
        'locationData': callDetails.locationData,
        'type': isVideoCall ? 'video' : 'audio',
      });

      // 5. Navigate the admin to the appropriate call page
      // We need to create a temporary IncomingCall object to pass to the admin pages
      final callDoc = await FirebaseFirestore.instance.collection(collectionName).doc(callId).get();
      final tempIncomingCall = IncomingCall(doc: callDoc, isVideoCall: isVideoCall);

      if (!mounted) return;

      if (isVideoCall) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AdminLiveCallPage(
              user: currentUser!,
              call: tempIncomingCall,
            ),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AdminCallPage(
              user: currentUser!,
              call: tempIncomingCall,
            ),
          ),
        );
      }
    } catch (e) {
      print("Error initiating call to user: $e");
      showToast("Failed to initiate call. Please try again.");
    }
  }


  /// Query Ego stream from Firestore

  Stream<QuerySnapshot<Map<String, dynamic>>> getVisitedUserEgoStream() {
    return FirebaseFirestore.instance
        .collection('ego_stream')
        .where("userId", isEqualTo: widget.visitedUsersID)
        .limit(300)
        .orderBy('egoTime', descending: true)
        .snapshots();
  }

  /// Save Ego mantra

  Future<void> saveEgoMessage() async {
    final egoMessage = _visitorMantraController.text;
    final egoTime = FieldValue.serverTimestamp();
    final egoName = _visitingUser?.nickname;
    final egoImage = _visitingUser?.avatarUrl;
    final userId = widget.visitedUsersID;
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
    );
    logger.d('Successfully sent an Ego message to $egoName');
    await firebaseServices.saveUserActivity(
      activityType: 'mantra', // A new activity type
      activityMessage: "$egoName left a new mantra for you, ${widget.visitedEgoName}.",
      recipientId: widget.visitedUsersID,
      recipientNickname: widget.visitedEgoName,
    );
  }

  /// Save Ego audio mantra

  Future<void> saveEgoAudioMessage(String audioPath) async {
    final egoTime = FieldValue.serverTimestamp();
    final egoName = _visitingUser?.nickname;
    final egoImage = _visitingUser?.avatarUrl;
    final userId = widget.visitedUsersID;
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
    logger.d('Successfully sent an Ego audio message to $egoName');
    await firebaseServices.saveUserActivity(
      activityType: 'mantra', // Same activity type
      activityMessage:
          "You left a new audio mantra for ${widget.visitedEgoName}.",
      recipientId: widget.visitedUsersID,
      recipientNickname: widget.visitedEgoName,
    );
  }

  Future<void> pushMantraNotification() async {
    final egoMessage = _visitorMantraController.text;
    final egoName = _visitingUser?.nickname ?? 'An Ego';
    final senderId = currentUser?.uid;

    // A mantra is only pushed if there is a message to send.
    if (egoMessage.isEmpty) {
      return;
    }

    try {
      // --- 1. FETCH THE RECIPIENT'S USER DATA TO GET THEIR FCM TOKEN ---
      final UserModel visitedUser = await firebaseServices.getUserWithId(id: widget.visitedUsersID);
      final String? receiverToken = visitedUser.fcmId;

      // --- 2. PROCEED ONLY IF A TOKEN EXISTS ---
      if (receiverToken != null && receiverToken.isNotEmpty) {
        // --- 3. CONSTRUCT THE NOTIFICATION PAYLOAD AS A SIMPLE MAP ---
        final Map<String, dynamic> notificationPayload = {
          "token": receiverToken,
          "notification": {
            "title": "Ego Mantra Received!",
            "body": "$egoName sent a new mantra to your ego stream."
          },
          "data": {
            // The route should navigate the user to where they can see the mantra.
            // Assuming 'visitedEgo' is the correct route to view another user's profile.
            'route': 'visitedEgo',
            'visitedUserId': widget.visitedUsersID,
            'visitedEgoName': widget.visitedEgoName
          }
        };

        // --- 4. SEND THE NOTIFICATION ---
        await notificationService.sendNotification(notificationPayload);

        logger.d('Successfully pushed an Ego mantra notification to ${visitedUser.nickname}');
      } else {
        logger.w('Could not send mantra notification: User ${widget.visitedEgoName} has no FCM token.');
      }
    } catch (e) {
      logger.e('Failed to push mantra notification: $e');
      // We don't show a toast here to not interrupt the sender's experience.
      // The failure is only logged.
    }
  }


  Future<void> pushAudioMantraNotification() async {
    final egoName = _visitingUser?.nickname;
    final userId = widget.visitedUsersID;
    final senderId = currentUser?.uid;

    await _firebaseMessaging.subscribeToTopic(userId);

    final pushNotification.NotificationModel _notificationModel =
        pushNotification.NotificationModel(
            topic: userId,
            data: pushNotification.Data(id: senderId, route: 'wallet'),
            notification: pushNotification.Notification(
                title: "Ego Mantra",
                body: '$egoName sent a new audio mantra to your ego stream.'));
    notificationService.sendNotification(_notificationModel.toJson());

    logger
        .d('Successfully pushed an Ego audio message notification to $egoName');
  }

  /// Delete an ego message

  Future<void> deleteEgoStreamMessage(String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('ego_stream')
          .doc(documentId)
          .delete();
      logger.d(
          'Successfully deleted ego stream message from visited profile: $documentId');
      CustomToast.showToast(message: "Message deleted");
    } catch (e) {
      logger.e('Error deleting ego stream message: $e');
      CustomToast.showToast(message: "Failed to delete message");
    }
  }

  /// Get Visited Ego User info
  Future<VisitedUserModel> getVisitedUserInfo() async {
    DocumentSnapshot response = await FirebaseFirestore.instance
        .collection(AppString.users)
        .doc(widget.visitedUsersID)
        .get();

    var visitedUser =
        VisitedUserModel.fromFirestore(response.data() as Map<String, dynamic>);
    logger.d('Successfully got the visited user model');
    return visitedUser;
  }

  /// Get visited user's sessions that have been featured or marked for replies.
  Stream<QuerySnapshot<Map<String, dynamic>>> visitedUsersSessions() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("userId", isEqualTo: widget.visitedUsersID)
        .where("repliesEnabled", isEqualTo: true)
        .where("archived", isEqualTo: false)
        .where("flagged", isEqualTo: false)
        .limit(AppString.appSessionLength)
        //.orderBy('timeLastActivity', descending: true)
        .snapshots();
  }

  /// [User Activity] -> get visited user activities.
  Future<List<UserActivityModel>> getActivityByVisitedUser() async {
    List<UserActivityModel> _userActivityList = [];
    visitedUser = await getVisitedUserInfo();
    try {
      final _value = await FirebaseFirestore.instance
          .collection(AppString.userActivity)
          .where("clientId", isEqualTo: widget.visitedUsersID)
          .orderBy('dateCreated', descending: true)
          .limit(AppString.allSessionLength)
          .get();

      _value.docs
          .map((e) =>
              _userActivityList.addAll([UserActivityModel.fromJson(e.data())]))
          .toList();
    } catch (e) {
      logger.e(e);
    }
    return _userActivityList;
  }

  InterstitialAd? _interstitialAd2;
  int _interstitialLoadAttempts = 0;

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

  /// Block a user only by Super Ego

  Future<void> blockUser() async {
    final userId = visitedUser?.userId;
    final userToBlock =
        FirebaseFirestore.instance.collection('users').doc(userId);
    await userToBlock.delete();
    logger.d('Successfully blocked a user');
    print("The Blocked User Is: $userId");
  }

  flagEgoAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    Widget continueButton = TextButton(
      child: Text("Flag"),
      onPressed: () {
        sendToFlagged();
        showToast("Thank You!\n Claire will check this Ego for violations.");
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Flag And Report This User?"),
      content: Text(AppString.flag_ego_alert_note),
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

  /// Flag a user

  Future<bool?> sendToFlagged() async {
    final userId = visitedUser?.userId;
    final value = true;
    FirebaseFirestore.instance.collection('users').doc(userId).set(
      {
        "flagged": value,
      },
      SetOptions(merge: true),
    );
    logger.d('Successfully flagged a user');
    print('Is Flagged?: $userId');
    isFlagged = value;
    return value;
  }

  unflagEgoAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Back"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = TextButton(
      child: Text("Unflag"),
      onPressed: () {
        removeFromFlagged();
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Unflag This User?"),
      content: Text(AppString.unflag_ego_alert_note),
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

  /// Unflag a user

  Future<bool?> removeFromFlagged() async {
    final userId = visitedUser?.userId;
    final value = false;
    FirebaseFirestore.instance.collection('users').doc(userId).set(
      {
        "flagged": value,
      },
      SetOptions(merge: true),
    );
    logger.d('Successfully unflagged a user');
    print('Is Flagged?: $value');
    isFlagged = value;
    return value;
  }

  /// Visited User Ego Profile Info Here

  Future<VisitedEgoProfileInfo> getVisitedUserEgoProfileInfo() async {
    VisitedEgoProfileInfo visitedProfileInfo = VisitedEgoProfileInfo();
    visitedUser = await getVisitedUserInfo();

    visitedProfileInfo = VisitedEgoProfileInfo(visitedUserModel: visitedUser);

    //get user session count
    List<Session> _sessionList = [];
    try {
      final _value = await FirebaseFirestore.instance
          .collection(AppString.appFeaturedSessions)
          .where("userId", isEqualTo: widget.visitedUsersID)
          // .limit(AppString.appSessionLength)
          .get();

      debugPrint(
          " This is the number of sessions by date for this visited user ${_value.docs.length}");
      _value.docs
          .map((e) => _sessionList.addAll([Session.fromJson(e.data())]))
          .toList();

      debugPrint(
          " This is the number of sessions by date for this visited user ${_sessionList.length}");
    } catch (e) {
      debugPrint(e.toString());
    }

    //get advises count

    List<CommentSessionModel> _advisesList = [];

    try {
      final _value = await FirebaseFirestore.instance
          .collection("user_comment_counters")
          .where("userId", isEqualTo: widget.visitedUsersID)
          //  .limit(AppString.appSessionLength)
          .get();

      debugPrint(
          " This is the number of advises given by this visited user ${_value.docs.length}");
      _value.docs
          .map((e) =>
              _advisesList.addAll([CommentSessionModel.fromJson(e.data())]))
          .toList();

      debugPrint(
          " This is the number of advises given by this visited user ${_advisesList.length}");
    } catch (e) {
      debugPrint(e.toString());
    }

    //get follows count

    List<VisitedUserModel> _followsList = [];

    try {
      final _value = await FirebaseFirestore.instance
          .collection(AppString.users)
          .where("userId", isEqualTo: widget.visitedUsersID)
          // .limit(AppString.appCommentLength)
          .get();

      debugPrint(
          " This is the number of follows given to this visited user ${_value.docs.length}");
      _value.docs
          .map(
              (e) => _followsList.addAll([VisitedUserModel.fromJson(e.data())]))
          .toList();

      debugPrint(
          " This is the number of follows given to this visited user ${_followsList.length}");
    } catch (e) {
      debugPrint(e.toString());
    }

    visitedProfileInfo = VisitedEgoProfileInfo(
      visitedUserModel: visitedUser,
      sessionCount: _sessionList.length,
      advisesCount: _advisesList.length,
      followCount: _followsList.length,
    );
    return visitedProfileInfo;
  }

  /// Profile Cover header
  Widget _visitedPageHeader({required VisitedUserModel? visitedUser}) {
    // If for some reason the user object is null, we are safe.
    if (visitedUser == null) {
      return Container();
    }

    // Determine if the current theme is dark
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Define colors based on the theme
    Color getCardBackgroundColor() {
      if (visitedUser.userType == 'REGULAR') {
        return isDarkMode ? Pallet.colorPrimary : Colors.white;
      } else if (visitedUser.userType == 'ADMIN' ||
          visitedUser.userType == 'SUPER_ADMIN') {
        return isDarkMode ? Pallet.colorSecondary : Colors.white;
      }
      // Default fallback
      return isDarkMode ? Color(0xFF2C2C2E) : Colors.white;
    }

    final cardBackgroundColor = getCardBackgroundColor();
    final cardTextColor = isDarkMode ? Colors.white : Colors.black;
    final hintTextColor = isDarkMode ? Colors.white54 : Colors.black54;

    return Material(
      color: Colors
          .transparent, // Use transparent to show the container's decoration
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
                      Container(
                        decoration: BoxDecoration(
                            color: visitedUser.userType == 'REGULAR'
                                ? Pallet.colorPrimary
                                : visitedUser.userType == 'ADMIN'
                                    ? Pallet.colorSecondary
                                    : visitedUser.userType == 'SUPER_ADMIN'
                                        ? Pallet.colorSecondary
                                        : Pallet.colorBlue,
                            borderRadius: BorderRadius.circular(100)),
                        height: 22,
                        width: 20,
                        margin: EdgeInsets.only(left: 4),
                        child: Icon(
                          visitedUser.userType == "ADMIN"
                              ? Icons.star_half_rounded
                              : visitedUser.userType == "SUPER_ADMIN"
                                  ? Icons.star
                                  : Icons.star_border_rounded,
                          color: Pallet.colorWhite,
                          size: 20,
                        ),
                      ),

                      //Clairevatar Container is here
                      Container(
                        decoration: BoxDecoration(
                          color: visitedUser.userType == 'REGULAR'
                              ? Pallet.colorPrimary
                              : visitedUser.userType == 'ADMIN'
                                  ? Pallet.colorSecondary
                                  : visitedUser.userType == 'SUPER_ADMIN'
                                      ? Pallet.colorSecondary
                                      : Pallet.colorBlue,
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
                              imageUrl: visitedUser.avatarUrl ?? "",
                              imageBuilder: (context, imageProvider) =>
                                  Container(
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
                    ],
                  ),

                  // The count columns (stats cards) are here
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(
                            (visitedUser.sessionCount ?? 0).toString(),
                            "Sessions",
                            visitedUser.userType,
                            context),
                        _buildStatCard(
                            (visitedUser.adviseCount ?? 0).toString(),
                            "Advises",
                            visitedUser.userType,
                            context),
                        _buildStatCard(
                            (visitedUser.totalLoveCount ?? 0).toString(),
                            "Loves",
                            visitedUser.userType,
                            context),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 6,
                  ),
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
                    color: visitedUser.userType == 'REGULAR'
                        ? Pallet.colorPrimary
                        : visitedUser.userType == 'ADMIN'
                            ? Pallet.colorSecondary
                            : visitedUser.userType == 'SUPER_ADMIN'
                                ? Pallet.colorSecondary
                                : Pallet.colorBlue,
                  ),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Pallet.colorWhite,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        margin: EdgeInsets.only(
                            left: 17, right: 4, top: 4, bottom: 4),
                        alignment: Alignment.centerLeft,
                        width: 250,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 4,
                            ),
                            Text(
                              visitedUser.nickname ?? "",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        visitedUser.userType == "ADMIN"
                            ? Icons.star_half_rounded
                            : visitedUser.userType == "SUPER_ADMIN"
                                ? Icons.star
                                : Icons.star_border_rounded,
                        color: Pallet.colorWhite,
                        size: 20,
                      ),
                    ],
                  ),
                ),

                Spacer(
                  flex: 1,
                ),

                /// Here is the Ego badge showing user's usertype

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 6),
                          padding: EdgeInsets.only(
                            left: 8,
                            right: 4,
                            top: 4,
                            bottom: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: visitedUser.userType == 'REGULAR'
                                ? Pallet.colorPrimary
                                : visitedUser.userType == 'ADMIN'
                                    ? Pallet.colorSecondary
                                    : visitedUser.userType == 'SUPER_ADMIN'
                                        ? Pallet.colorSecondary
                                        : Pallet.colorBlue,
                          ),
                          child: Row(
                            children: [
                              Text(
                                visitedUser.userType == 'REGULAR'
                                    ? 'Ego'
                                    : visitedUser.userType == 'ADMIN'
                                        ? 'Alter Ego'
                                        : visitedUser.userType == 'SUPER_ADMIN'
                                            ? 'Super Ego'
                                            : 'Ego',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(
                      height: 3,
                    ),

                    /// Flagged user label

                    GestureDetector(
                      onTap: () {
                        if (visitedUser.flagged == false)
                          showCustomDialog(context,
                              message: visitedUser.flagged == true
                                  ? AppString.unflag_ego_alert_note
                                  : AppString.flag_ego_alert_note,
                              onPressed: () {
                            setState(() {
                              PageRouter.goBack(context);
                              sendToFlagged();
                            });
                          });
                        else
                          showCustomDialog(context,
                              message: visitedUser.flagged == false
                                  ? AppString.flag_ego_alert_note
                                  : AppString.unflag_ego_alert_note,
                              onPressed: () {
                            setState(() {
                              PageRouter.goBack(context);
                              removeFromFlagged();
                            });
                          });
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: 6),
                        padding:
                            EdgeInsets.symmetric(vertical: 0, horizontal: 5),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Pallet.colorPrimaryDark,
                            )),
                        child: Row(
                          children: [
                            Icon(
                              visitedUser.flagged == true
                                  ? Icons.flag
                                  : Icons.flag_outlined,
                              color: Pallet.colorPrimaryDark,
                              size: 15,
                            ),
                            SizedBox(
                              width: 2,
                            ),
                            Text(
                              visitedUser.userType == 'REGULAR'
                                  ? 'Flag Ego'
                                  : visitedUser.userType == 'ADMIN'
                                      ? 'Flag Alter Ego'
                                      : visitedUser.userType == 'SUPER_ADMIN'
                                          ? 'Flag Super Ego'
                                          : '',
                              style: GoogleFonts.lato(
                                  fontSize: 11.0,
                                  color: Pallet.colorPrimaryDark,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
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
              margin: EdgeInsets.only(
                  left: 4, right: 4, bottom: 4), // Added bottom margin
              child: FlipCard(
                key: cardKey,
                direction: FlipDirection.HORIZONTAL, // default
                back: SingleChildScrollView(
                  physics: NeverScrollableScrollPhysics(),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: visitedUser.userType == 'REGULAR'
                              ? Pallet.colorPrimary
                              : visitedUser.userType == 'ADMIN'
                                  ? Pallet.colorSecondary
                                  : visitedUser.userType == 'SUPER_ADMIN'
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
                                  visitedUser.userType == 'REGULAR'
                                      ? 'Ego Stream:'
                                      : visitedUser.userType == 'ADMIN'
                                          ? 'Alter Ego Stream:'
                                          : visitedUser.userType ==
                                                  'SUPER_ADMIN'
                                              ? 'Super Ego Stream:'
                                              : '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 3,
                              ),
                              Row(
                                children: [
                                  AudioRecorder(
                                    onStart: () {
                                      // When recording starts, clear old paths and update the hint
                                      setState(() {
                                        _recordedAudioPath = null;
                                        _audioStatusHint = "Recording audio...";
                                        // Disable the text field while recording
                                        _visitorMantraController.clear();
                                      });
                                    },
                                    onStop: (String path) {
                                      // When recording stops, store the path and update the hint
                                      setState(() {
                                        _recordedAudioPath = path;
                                        _audioStatusHint =
                                            "Audio recorded! Hit send.";
                                      });
                                    },
                                    onCancel: () {
                                      // If recording is cancelled, reset everything
                                      setState(() {
                                        _recordedAudioPath = null;
                                        _audioStatusHint =
                                            "...write a new ego mantra...";
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
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            color: cardBackgroundColor,
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
                                                TextStyle(color: cardTextColor),
                                            maxLines: 2,
                                            controller:
                                                _visitorMantraController,
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
                                        // Check if we are sending an AUDIO message
                                        if (_recordedAudioPath != null) {
                                          // Prevent double taps while uploading
                                          if (_isUploadingAudio) return;

                                          setState(() {
                                            _isUploadingAudio = true;
                                            _audioStatusHint =
                                                "Uploading audio...";
                                          });

                                          // Use the path we stored in the state
                                          saveEgoAudioMessage(
                                                  _recordedAudioPath!)
                                              .then((_) {
                                            // After saving is complete
                                            pushAudioMantraNotification();
                                            showToast(
                                                AppString.sent_ego_message);

                                            setState(() {
                                              _isUploadingAudio = false;
                                              _recordedAudioPath =
                                                  null; // Reset path
                                              _audioStatusHint =
                                                  "...write a new ego mantra..."; // Reset hint
                                            });

                                            // Flip card and show ad
                                            if (cardKey.currentState?.isFront ==
                                                false) {
                                              cardKey.currentState!
                                                  .toggleCard();
                                            }
                                            Future.delayed(Duration(seconds: 4),
                                                () {
                                              _showEgoMantraInterstitialAd();
                                            });
                                          });
                                        }
                                        // Check if we are sending a TEXT message
                                        else if (_visitorMantraController.text
                                            .trim()
                                            .isNotEmpty) {
                                          if (_visitingUser?.nickname != null) {
                                            saveEgoMessage();
                                            pushMantraNotification();
                                            _visitorMantraController.clear();

                                            if (cardKey.currentState?.isFront ==
                                                false) {
                                              cardKey.currentState!
                                                  .toggleCard();
                                            }
                                            showToast(
                                                AppString.sent_ego_message);
                                            Future.delayed(Duration(seconds: 4),
                                                () {
                                              _showEgoMantraInterstitialAd();
                                            });
                                          } else {
                                            CustomToast.showToast(
                                                message:
                                                    "Could not identify sender.");
                                          }
                                        }
                                        // If neither audio is recorded nor text is written
                                        else {
                                          CustomToast.showToast(
                                              message:
                                                  "Write a mantra or record audio.");
                                        }
                                      },
                                      mini: true,
                                      backgroundColor: Pallet.colorWhite,
                                      child: SvgPicture.asset(
                                        AppImages.appSend,
                                        colorFilter: ColorFilter.mode(
                                            Pallet.colorPrimary,
                                            BlendMode.srcIn),
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
                        color: visitedUser.userType == 'REGULAR'
                            ? Pallet.colorPrimary
                            : visitedUser.userType == 'ADMIN'
                                ? Pallet.colorSecondary
                                : visitedUser.userType == 'SUPER_ADMIN'
                                    ? Pallet.colorSecondary
                                    : Pallet.colorBlue,
                      ),
                    ),

                    /// Build Ego stream from Firebase on a ListView

                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        children: [
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: getVisitedUserEgoStream(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<QuerySnapshot> snapshot) {
                                if (snapshot.hasError) {
                                  return Text('Something went wrong');
                                }
                                if (!snapshot.hasData) {
                                  return Text(
                                    'Write a mantra by currently by tapping on this space',
                                    style: TextStyle(color: Colors.white),
                                  );
                                }

                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Text("Loading");
                                }

                                return ListView(
                                  children: snapshot.data!.docs
                                      .map((DocumentSnapshot document) {
                                    Map<String, dynamic> data = document.data()!
                                        as Map<String, dynamic>;
                                    return ListTile(
                                      leading: ClipOval(
                                        child: GestureDetector(
                                          onTap: () async {
                                            setState(() {
                                              _isAvatarLoading = true;
                                            });
                                            try {
                                              final String _mantraUserId =
                                                  data['senderId'].toString();
                                              final String _mantraEgoName =
                                                  data['egoName'].toString();
                                              PageRouter.gotoWidget(
                                                  VisitedUserEgoProfilePage(
                                                      visitedUsersID:
                                                          _mantraUserId,
                                                      visitedEgoName:
                                                          _mantraEgoName),
                                                  context);
                                              print(
                                                  "Visited User ID::: $_mantraUserId");
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
                                                imageUrl:
                                                    data['egoImage'].toString(),
                                                imageBuilder:
                                                    (context, imageProvider) =>
                                                        Container(
                                                  decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.fill,
                                                    ),
                                                  ),
                                                ),
                                                placeholder: (context, url) =>
                                                    CircularProgressIndicator(),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Image.asset(
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
                                      // UPDATED TITLE WIDGET
                                      title: Row(
                                        // Use baseline alignment for perfect vertical text alignment
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline
                                            .alphabetic, // Required for baseline alignment
                                        children: [
                                          Text(
                                            data['egoName'].toString(),
                                            style: GoogleFonts.lato(
                                              // Using GoogleFonts.lato for consistency
                                              color: Colors
                                                  .white, // Increased contrast for better readability
                                              fontSize: 14,
                                              fontWeight: FontWeight
                                                  .bold, // Make the name stand out
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          // Display the formatted timestamp
                                          Expanded(
                                            child: Text(
                                              // Check if egoTime exists and is a Timestamp
                                              (data['egoTime'] is Timestamp)
                                                  ? formatFirestoreTimestamp(
                                                      data['egoTime'])
                                                  : '', // Show nothing if data is invalid
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.lato(
                                                // Using GoogleFonts.lato
                                                color: Colors
                                                    .white60, // Slightly dimmed for hierarchy
                                                fontSize: 11,
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: data
                                              .containsKey('egoAudioMessage')
                                          ? CustomPlaySoundWidget(
                                              filePath: data['egoAudioMessage'])
                                          : Text(
                                              data['egoMessage'] ?? '',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                      trailing: Visibility(
                                        // Show the delete icon ONLY if the current user is the sender of the message.
                                        visible: _visitingUser?.userType ==
                                                "SUPER_ADMIN" ||
                                            _visitingUser?.userId ==
                                                data['senderId'],
                                        child: GestureDetector(
                                          onTap: () {
                                            // Get the unique document ID
                                            final String documentId =
                                                document.id;

                                            showCustomDialog(context,
                                                message: AppString
                                                    .delete_mantra_alert_note,
                                                onPressed: () {
                                              PageRouter.goBack(context);
                                              // Call the new universal delete method
                                              deleteEgoStreamMessage(
                                                  documentId);
                                            });
                                          },
                                          child: Icon(
                                            Icons.delete_forever_rounded,
                                            color: Colors.white70,
                                            size: 18,
                                          ),
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
  Widget _buildStatCard(
      var count, String label, String? userType, BuildContext context) {
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
    print("User nickname::: ${visitedUserModel.nickname}");
    print("User type::: ${visitedUserModel.userType}");

    return SafeArea(
      child: Scaffold(
        backgroundColor: Pallet.colorSecondaryDark,
        appBar: AppBar(
          backgroundColor: visitedUser?.userType == 'REGULAR'
              ? Pallet.colorPrimary
              : Pallet.colorSecondary,
          centerTitle: true,
          title: Text(
            widget.visitedEgoName.toString(),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Pallet.colorWhite,
            ),
          ),
          elevation: 0,
          actions: [
            // Only show buttons if the visiting user is an admin
            if (_visitingUser?.userType == 'ADMIN' || _visitingUser?.userType == 'SUPER_ADMIN')
              IconButton(
                icon: const Icon(Icons.call),
                tooltip: 'Companion Call User',
                onPressed: () => _initiateCallToUser(isVideoCall: false),
              ),
            if (_visitingUser?.userType == 'ADMIN' || _visitingUser?.userType == 'SUPER_ADMIN')
              IconButton(
                icon: const Icon(Icons.videocam),
                tooltip: 'Live Session with User',
                onPressed: () => _initiateCallToUser(isVideoCall: true),
              ),
          ],
        ),
        body: Column(
          children: [
            Material(
              elevation: 10,
              child: _visitedPageHeader(
                visitedUser: visitedUser,
              ),
            ),

            /// The three Ego page tabs are here
            /// First tab is Sessions Tab

            Expanded(
                child: DefaultTabController(
              length: 3,
              child: Column(children: [
                SizedBox(height: 7.h),
                Container(
                  // margin: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      //border: Border.all(color: Pallet.colorPrimary, width: 1),
                      ),
                  child: Row(children: [
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
                                      color: Pallet.deepGreen, width: 3)
                                  : Border.all(
                                      color: Pallet.deepGreen, width: 6),
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
                                  "Sessions",
                                  style: TextStyle(
                                    color: currentTabIndex != 1
                                        ? Pallet.deepGreen
                                        : Pallet.deepGreen,
                                    fontWeight: currentTabIndex != 1
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                    fontSize: currentTabIndex != 1 ? 14 : 14,
                                  ),
                                ),
                                SizedBox(width: 14),
                                currentTabIndex != 0
                                    ? SizedBox.shrink()
                                    : Icon(Icons.archive_rounded,
                                        color: Pallet.deepGreen)
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// Second tab is Activities Tab

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
                                      color: Pallet.colorPrimary, width: 3)
                                  : Border.all(
                                      color: Pallet.colorPrimary, width: 6),
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
                                  "Activities",
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
                                currentTabIndex != 1
                                    ? SizedBox.shrink()
                                    : Icon(Icons.circle_notifications,
                                        color: Pallet.colorPrimary)
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// Third tab is Claire Love Tab

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
                                      color: Pallet.colorSecondary, width: 3)
                                  : Border.all(
                                      color: Pallet.colorSecondary, width: 6),
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
                                  "Wallet",
                                  style: TextStyle(
                                    color: currentTabIndex != 2
                                        ? Pallet.colorSecondary
                                        : Pallet.colorSecondary,
                                    fontWeight: currentTabIndex != 2
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                    fontSize: currentTabIndex != 2 ? 14 : 14,
                                  ),
                                ),
                                SizedBox(width: 14),
                                currentTabIndex != 2
                                    ? SizedBox.shrink()
                                    : Icon(Icons.monetization_on_rounded,
                                        color: Pallet.colorSecondary)
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      StreamBuilder(
                        stream: _userSessionsStream,
                        builder:
                            (context, AsyncSnapshot<QuerySnapshot> session) {
                          if (session.connectionState ==
                              ConnectionState.waiting) {
                            return RotateImage(70, 70);
                          }
                          if (!session.hasData) {
                            return Center(
                              child: Text("No Session data",
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                      fontSize: 15.0,
                                      color: Pallet.colorBlack,
                                      //fontStyle: FontStyle.normal,
                                      fontWeight: FontWeight.w600)),
                            );
                          }
                          if (session.hasData) {
                            // clear list
                            _sessionList!.clear();

                            session.data!.docs.map((e) {
                              _sessionList!.add(Session.fromJson(e.data()));
                            }).toList();

                            return Scrollbar(
                              child: ListView(
                                children: [
                                  // Top ad unit is here
                                  if (visitedUserTopOfSessionsBanner != null &&
                                      _isTopOfSessionsBannerLoaded)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: Container(
                                        height: visitedUserTopOfSessionsBanner!
                                            .size.height
                                            .toDouble(),
                                        width: visitedUserTopOfSessionsBanner!
                                            .size.width
                                            .toDouble(),
                                        child: AdWidget(
                                            ad: visitedUserTopOfSessionsBanner!),
                                        alignment: Alignment.center,
                                      ),
                                    ),

                                  ..._sessionList!
                                      .map((element) => EgoModeSessionCard(
                                            element: element,
                                            visitedUsersID: '',
                                            visitedEgoName: '',
                                          ))
                                      .toList(),

                                  // Bottom ad unit is here
                                  if (visitedUserBottomOfSessionsBanner !=
                                          null &&
                                      _isBottomOfSessionsBannerLoaded)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: Container(
                                        height:
                                            visitedUserBottomOfSessionsBanner!
                                                .size.height
                                                .toDouble(),
                                        width:
                                            visitedUserBottomOfSessionsBanner!
                                                .size.width
                                                .toDouble(),
                                        child: AdWidget(
                                            ad: visitedUserBottomOfSessionsBanner!),
                                        alignment: Alignment.center,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }
                          return Container();
                        },
                      ),
                      ActivityWidget(userId: widget.visitedUsersID),
                      VisitedUserClaireLoves(
                        visitedEgoName: visitedUser?.nickname.toString() ?? '',
                        visitedUsersID: visitedUser?.userId.toString() ?? '',
                      ),
                    ],
                  ),
                )
              ]),
            ))
          ],
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
