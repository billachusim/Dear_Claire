import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:clairediary/ui/create_session/quick_session_widget.dart';
import 'package:clairediary/ui/create_session/session_categorizer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/services/user_model.dart';
import 'package:clairediary/ui/create_session/session_model.dart';
import 'package:clairediary/ui/create_session/sound/custom_play_sound_widget.dart';
import 'package:clairediary/ui/create_session/view_singlesession_widget.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:clairediary/ui/splash_screen/rotate_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:clairediary/widgets/toast.dart';
import 'package:hive/hive.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/transaction_model.dart' as t_model;
import '../../services/notification_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/unified_media_widget.dart';
import '../featured/model/comment_session_model.dart';
import '../featured/model/session.dart';
import '../featured/notified_session_details.dart';
import '../routes/page_router_animation.dart';
import 'create_session_controller.dart';
import 'sound/sound_widget.dart';


class CreateSessionPage extends StatefulWidget {
  const CreateSessionPage({Key? key}) : super(key: key);

  @override
  _CreateSessionPageState createState() => _CreateSessionPageState();
}

const int maxFailedLoadAttempts = 3;

class _CreateSessionPageState extends State<CreateSessionPage> {
  final TransactionService _transactionService = TransactionService();
  TextEditingController sessionTitleController = TextEditingController();
  final FirebaseServices _firebaseServices = FirebaseServices();
  final c = Get.find<CreateSessionController>();

  Session? featuredSessionModel;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  late final int mood;

  //object for hive database
  late final box;

  bool isTyping = false;

//obtain user id, nickname and avatarUrl linked to this user
  var currentUser = FirebaseAuth.instance.currentUser;

  UserModel userModel = UserModel();

//used for generating random id for each session
  var uuid = Uuid();

  //input controller to access session message from user
  final sessionTextEditingController = TextEditingController();
  late FocusNode sessionTextFocusNode;

  void setStateIfMounted(f) {
    if (mounted) setState(f);
  }

//initialize the audio record file that stores user audio record. null by default
  File? recordFile;
  File? videoRecordFile;
  List<File> _videoFiles = [];

//initialize the image list stores user selected images.
  List<File> imageList = <File>[];

//for showing loading indicator when uploading data;
  bool isLoading = false;
  bool acceptReplies = false;
  bool followClaire = true;
  String sessionMood = 'Current Mood';
  String _location = '';


  // Function to retrieve audio path from Hive
  void _loadAudioFromHive() {
    final audioPath = box.get('audio_path');
    if (audioPath != null && audioPath.isNotEmpty) {
      final file = File(audioPath);
      if (file.existsSync()) {
        setState(() {
          recordFile = file;
        });
      } else {
        // If file doesn't exist, clear from Hive
        _deleteAudioFromHive();
      }
    }
  }

// Function to delete audio file and clear from Hive
  Future<void> _deleteAudioFromHive() async {
    final audioPath = box.get('audio_path');
    if (audioPath != null) {
      final fileToDelete = File(audioPath);
      if (fileToDelete.existsSync()) {
        await fileToDelete.delete();
      }
      await box.delete('audio_path');
      setState(() {
        recordFile = null;
      });
    }
  }




  Future<Placemark?> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    final _response = await Geolocator.getCurrentPosition();
    return _getAddress(_response.latitude, _response.longitude);
  }

  Future<Placemark?> _getAddress(double lat, double long) async {
    Placemark? place;
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
      place = placemarks[0];
      setState(() {
        _location =
        "in ${place?.administrativeArea.toString()}, ${place?.country.toString()}";
      });
      print("Location is: $_location");
      return place;
    } catch (e) {
      logger.e(e);
    }
    return place;
  }




  randomizeBackgroundColor() {
    Random random = new Random();
    int randomNumber = random.nextInt(Constant.DIARY_COLORS.length);
    c.selectedBackgroundColor = randomNumber.obs;
  }


  @override
  void initState() {
    super.initState();
    //chatGPT = ChatGPT.instance.builder(API_KEY);
    _createInterstitialAd();
    _createQuickInterstitialAd();
    randomizeBackgroundColor();
    initializeDatabaseObject();
    sessionTextFocusNode = FocusNode();
    Future.delayed(Duration(seconds: 8), () {
      sessionTextFocusNode.requestFocus();
    }
    );
    randomizeNewDiarySessionToast();
  }

  void initializeDatabaseObject() async {
    box = await Hive.openBox('draft');
    // Load text
    String text = box.get("text", defaultValue: "");
    if (text.isNotEmpty) {
      sessionTextEditingController.text = text;
    }
    // Load audio
    _loadAudioFromHive();
  }

  randomizeNewDiarySessionToast() async {
    Random random = new Random();
    int randomNumber = random.nextInt(Constant.TOAST_NUMBERS.length);
    var message = randomNumber == 1 ? "Go on, Darling, talk to me..." :
    randomNumber == 2 ? "Start typing or recording anything." :
    randomNumber == 3 ? "You have come to a safe place." :
    randomNumber == 4 ? "Everything can be between us." :
    randomNumber == 5 ? "I'll always be here for you." :
    randomNumber == 5 ? "Let's have a heart to heart." :
    randomNumber == 6 ? "Go ahead, type or record anything." :
    randomNumber == 7 ? "Tell me what's happening, darling?" :
    randomNumber == 8 ? "Where are you and what's going on?" :
    randomNumber == 9 ? "You'll never be not truly loved." :
    randomNumber == 10 ? "A problem shared is..." :
    randomNumber == 11 ? "You are completely anonymous." :
    randomNumber == 12 ? "Write or record anything." :
    randomNumber == 13 ? "Tap the spinning flower after." :
    randomNumber == 14 ? "It's you and me time." :
    randomNumber == 15 ? "Start with Dear Claire" :
    randomNumber == 16 ? "Tap record and say Dear Claire" :
    randomNumber == 17 ? "I'm ready to listen." :
    randomNumber == 18 ? "I'm ready to read, listen and reply." :
    randomNumber == 19 ? "If you don't tell me, I won't know." :

    "Go on, Darling, talk to me...";
    await  Future.delayed(Duration(seconds: 5), () {
      Fluttertoast.showToast(
        toastLength: Toast.LENGTH_LONG,
        msg: message.toString(),
        textColor: Colors.white,
        backgroundColor: Pallet.colorSplashScreen,
      );    });
  }


  @override
  void dispose() {
    _interstitialAd?.dispose();
    _quickInterstitialAd?.dispose();
    sessionTextFocusNode.dispose();
    sessionTextEditingController.dispose();
    sessionTitleController.dispose();
    super.dispose();
  }


  /// checks if session meets original session rules...
  /// if it does, then increment necessary counts.
  Future<bool> isOriginalSession(String sessionText) async {
    final _session = sessionText.toString();
    final _length = _session.length;

    if (_session.contains("ear") &&
        _session.contains("laire") &&
        _length >= 50) {
      incrementSessionCount();

      if (currentUser != null) {
        // --- NEW TREASURY LOGIC ---
        final bool wasApproved = await _firebaseServices.updateTreasuryAndUser(
          userId: currentUser!.uid,
          amount: 10,
          type: t_model.TransactionType.credit,
          userTransactionDescription:
          "10 Loves received for an original diary session.",
          metadata: {'source': 'new_session'},
        );

        if (!wasApproved) {
          showToast("Your reward of 10 Loves is pending admin approval.");
          return true; // Exit gracefully.
        }
        // --- END OF NEW TREASURY LOGIC ---

        // --- Send Push Notification (Only if approved) ---
        try {
          // 1. Fetch the user's document to get their specific FCM token.
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .get();

          if (userDoc.exists) {
            final userToken = userDoc.data()?['fcmId'] as String?;
            // 2. Check if the token exists before trying to send.
            if (userToken != null && userToken.isNotEmpty) {
              // 3. Send notification directly to the user's token.
              await notificationService.sendNotification({
                "token": userToken, // Use 'token' instead of 'topic'
                "notification": {
                  "title": "You've Earned Love!",
                  "body": "You received 10 ❤️ for creating an original session."
                },
                "data": {"route": "wallet"}
              });
            }
          }
        } catch (e) {
          print("Failed to send 'Original Session' push notification: $e");
        }
      }

      // This local notification is still useful for immediate UI feedback.
      flutterLocalNotificationsPlugin.show(0, 'Clairelove Wallet',
          "You started an original diary session. 10 Loves for you.", _notificationDetails(), payload: "wallet");

      return true;
    }
    return false;
  }





  final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      importance: Importance.high,
      playSound: true);

  NotificationDetails? _notificationDetails() {
    return NotificationDetails(
        android: AndroidNotificationDetails(
            channel.id, channel.name,
            color: Pallet.colorPrimary,
            playSound: true,
            icon: '@drawable/claire_icon',
            enableLights: true,
            enableVibration: true,
            showWhen: true,
            channelShowBadge: true),
        iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true));
  }



  /// Increase session count when user creates new session.

  Future<void> incrementSessionCount() async {
    FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).set(
      {
        'sessionCount': FieldValue.increment(1),
      },
      SetOptions(merge: true),

    );
    logger.d('Successfully increased session count');
    print('Session Count is: $FieldValue');
  }


  /// Increase total love count when user creates new session or comment.

  Future<void> incrementTotalLoveCount() async {
    FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).set(
      {
        'totalLoveCount': FieldValue.increment(10),
      },
      SetOptions(merge: true),
    );
    logger.d('Successfully increased total love count');
    print('Session Count is: $FieldValue');
  }


  /// Ascertain current available love for the user.

  void ascertainCurrentLoveCount() {
    final totalLove = userModel.totalLoveCount;
    final withdrawnLove = userModel.withdrawnLoveCount;
    final currentLoveCount = totalLove! - withdrawnLove!;
    FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser?.uid)
        .set({
      "currentLoveCount": currentLoveCount,
    },
      SetOptions(merge: true),
    );
    logger.d('Got the current love count');
    print('Current love Count is: $currentLoveCount');

  }


  Widget _buildAudioPlayer() {
    if (recordFile != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: CustomPlaySoundWidget(filePath: recordFile!.path),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.white70),
              onPressed: () {
                // Show a confirmation dialog before deleting
                showDialog(
                  context: context,
                  builder: (ctx) =>
                      AlertDialog(
                        title: Text("Delete Recording"),
                        content: Text(
                            "Are you sure you want to delete this audio recording?"),
                        actions: [
                          TextButton(
                            child: Text("Cancel"),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                          TextButton(
                            child: Text("Delete"),
                            onPressed: () {
                              _deleteAudioFromHive();
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ],
                      ),
                );
              },
            ),
          ],
        ),
      );
    }
    return SizedBox.shrink();
  }





//show up when user clicks on the FAB to create a session
  Future<void> _showCardDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return Center(
          child: AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0)),
            title: Container(
              child: Text(AppString.save_or_share_title,
                  textAlign: TextAlign.center),
            ),
            content: SingleChildScrollView(
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: sessionTitleController,
                        decoration: InputDecoration(
                          //border: InputBorder,
                          hintText: AppString.whats_this_session_about,
                        ),
                      ),
                      Obx(
                        () => DropdownButton(
                          borderRadius: BorderRadius.circular(30.0),
                          isExpanded: true,
                          value: c.sessionMood.value,
                          icon: Icon(
                            Icons.arrow_circle_down_rounded,
                            color: Colors.pink,
                          ),
                          items:
                              Constant.USER_SESSION_MOODS.map((String items) {
                            return DropdownMenuItem(
                                value: items, child: Text(items));
                          }).toList(),
                          onChanged: (val) => c.changeMood(val.toString()),
                        ),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      Container(
                          child: Row(
                        children: [
                          Obx(
                                () => c.acceptReplies.value
                                ? Icon(Icons.lock_open_outlined)
                                : Icon(Icons.lock),
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(AppString.do_you_want_other_users,
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          Obx(() => Switch(
                                value: c.acceptReplies.value,
                                onChanged: (value) {
                                  c.acceptReplies.value = value;
                                  acceptReplies = value;
                                },
                                // activeTrackColor: Colors.lightGreenAccent,
                                // activeColor: Colors.green,
                              ))
                        ],
                      )),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                          child: Row(
                        children: [
                          Obx(
                                () => c.followClaire.value
                                ? Icon(Icons.lock_open_outlined)
                                : Icon(Icons.lock),
                          ),
                          SizedBox(width: 10),
                          Flexible(
                            child: Text(
                                "Do you want Claire to reply and follow this diary session?",
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          Obx(() => Switch(
                                value: c.followClaire.value,
                                onChanged: (value) {
                                  c.followClaire.value = value;
                                },
                                activeTrackColor: Colors.purpleAccent,
                                activeColor: Pallet.colorSecondary,
                              ))
                        ],
                      )),
                      SizedBox(
                        height: 9,
                      ),
                      Container(
                          child: Row(
                            children: [
                              Obx(
                                    () => c.location.value
                                    ? Icon(Icons.location_on)
                                    : Icon(Icons.location_off),
                              ),
                              SizedBox(width: 9),
                              Flexible(
                                child: Text("Do you want to tag your location?",
                                    style: TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w600)
                                ),
                              ),
                          Obx(() => Switch(
                                value: c.location.value,
                                onChanged: (showLocation) async {
                                  c.location.value = showLocation;

                                  if (showLocation) {
                                    await determinePosition();
                                    setState(() {});
                                  }
                                },
                                // activeTrackColor: Colors.lightGreenAccent,
                                // activeColor: Colors.green,
                              ))
                        ],
                      )),
                      SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Obx(
                  () => c.acceptReplies.value
                      ? Text("Share and Save",
                          style: TextStyle(color: Pallet.colorSecondary, fontSize: 18))
                      : Text('Save',
                          style: TextStyle(color: Pallet.colorSecondary, fontSize: 18)),
                ),
                onPressed: () {
                  if (sessionTitleController.text.isNotEmpty) {
                    Navigator.of(context).pop();
                    createSession();
                    showToast(AppString.started_new_session);
                  } else {
                    _interstitialAd?.dispose();
                    showToast(AppString.new_session_error);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor:
              Constant.DIARY_COLORS[c.selectedBackgroundColor.value],
          title: Text(
            "Start A Diary Session",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
              color: Pallet.colorWhite,
            ),
          ),
          elevation: 0,
        ),
        backgroundColor:
            Constant.DIARY_COLORS[c.selectedBackgroundColor.value],
        body: isLoading
            ? Center(
                child: Container(
                    height: 200,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        RotateImage(60, 60),
                        SizedBox(
                          height: 10,
                        ),
                        Text("Please Wait your Diary Session is being created, "
                            "If you have many videos and images, be patient.",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white))
                      ],
                    )))
            : SingleChildScrollView(
              child: Container(
                  height: MediaQuery.of(context).size.height,
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          child: AutoSizeTextField(
                            style: Constant
                                .DIARY_FONT_STYLES[c.selectedFontIndex.value],
                            maxLines: null,
                            minLines: 1,
                            onChanged: (text) {
                              if (text != null) {
                                setState(() {
                                  isTyping = true;
                                  box.put("text", text);
                                });
                              } else {
                                isTyping = false;
                                setState(() {
                                  isTyping = false;
                                });
                              }
                            },

                            scrollPadding: EdgeInsets.all(20.0),
                            controller: sessionTextEditingController,
                            focusNode: sessionTextFocusNode,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.all(10),
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              border: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              hintText:
                                  "Start your text or voice note with Dear Claire",
                              hintStyle: TextStyle(
                                  color: Pallet.colorWhite, fontSize: 12.sp),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                        width: 15.w,
                      ),


                      _buildVideoSelector(),

                      SizedBox(height: 20,),

                      Align(
                          alignment: Alignment.center,
                          child: _imagesGridView()
                      ),

                      _buildAudioPlayer(),



                      SizedBox(height: 20,),


                      /// Introducing Quick Sessions.
                      Visibility(
                        visible: !isTyping,
                        child: QuickSessionWidget(
                          sessionTitleController: sessionTitleController,
                          sessionTextEditingController: sessionTextEditingController,
                          createQuickSession: (newMood) {
                            // This anonymous function calls your existing method
                            // and handles the mood update.
                            setState(() {
                              mood = newMood;
                            });
                            createQuickSession();
                          },
                        ),
                      ),

                      SizedBox(height: 80,),
                    ],
                  ),
                ),
            ),
        bottomSheet: Container(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
            decoration: BoxDecoration(
              color: Constant.DIARY_COLORS[c.selectedBackgroundColor.value],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                    height: 30.h,
                    width: 35.w,
                    child: IconButton(
                      alignment: Alignment.topCenter,
                      icon: Icon(Icons.camera_enhance_rounded,
                          size: 35, color: Pallet.colorWhite),
                      onPressed: loadAssets,
                    )),
                SizedBox(
                  width: 23.w,
                ),
                Container(
                    height: 30.h,
                    width: 35.w,
                    child: IconButton(
                      icon: Icon(
                        Icons.video_call_rounded,
                        size: 35,
                        color: Pallet.colorWhite,
                      ),
                      onPressed: pickVideo,
                    )),
                SizedBox(
                  width: 20.w,
                ),
                Container(
                    height: 20.h,
                    width: 25.w,
                    child: IconButton(
                      icon: Icon(Icons.text_fields, color: Pallet.colorWhite),
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Select Font'),
                                content: showFontSelectionDialog(context),
                              );
                            });
                      },
                    )),
                SizedBox(
                  width: 20.w,
                ),
                Container(
                    height: 20.h,
                    width: 25.w,
                    child: IconButton(
                      icon: Icon(Icons.color_lens_rounded,
                          color: Pallet.colorWhite),
                      onPressed: () => c.changeColor(),
                    )),
                SizedBox(
                  width: 20.w,
                ),
                Container(
                    height: 30.h,
                    width: 35.w,
                    child: IconButton(
                      icon: Icon(
                        Icons.mic_rounded,
                        size: 35,
                        color: Pallet.colorWhite,
                      ),
                      onPressed: () async {
                        var status = await Permission.microphone.request();

                        // 2. Check the permission status
                        if (status.isGranted) {
                          // Permission is granted, proceed to the recorder
                          if (!mounted) return;
                          var data = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SoundRecorderWidget(
                                onRecordComplete: (recordFile) {},
                              ),
                            ),
                          );
                          if (data != null) {
                            setState(() {
                              recordFile = data;
                            });
                          }
                        } else if (status.isPermanentlyDenied) {
                          // Permission is permanently denied, show a dialog to open settings
                          showToast(
                              'Microphone permission is required to record audio. Please enable it in your phone settings.');
                          await openAppSettings();
                        } else {
                          // Permission was denied, but not permanently.
                          showToast(
                              'Microphone permission is required to record audio.');
                        }
                      },
                    )),
                SizedBox(
                  width: 10.w,
                ),
              ],
            )),
        floatingActionButton: FloatingActionButton(
          heroTag: "sendSession",
          backgroundColor: Pallet.colorSplashScreen,
          onPressed: () {
            _showCardDialog();
          },
          tooltip: 'Send or Save',
          child: RotateImage(45, 45),
        ),
      ),
    );
  }



  // This function is correct. It correctly picks files and updates the state.
  Future<void> loadAssets() async {
    List<XFile>? pickedFiles;
    try {
      pickedFiles = await ImagePicker().pickMultiImage();
    } catch (e) {
      print('Error picking images: $e');
    }

    if (!mounted) return;

    setState(() {
      if (pickedFiles != null) {
        // This correctly converts XFile to File and updates the controller's list.
        c.images = pickedFiles.map((file) => File(file.path)).toList();
      }
      // The 'else' block seems to assign an old list back.
      // You might want to remove it if the intention is just to add new images.
      // else {
      //   c.images = imageList;
      // }
    });
  }




  /// Picks multiple videos from the gallery, up to a limit of 3.
  Future<void> pickVideo() async {
    // 1. Enforce the max limit before even opening the picker.
    if (_videoFiles.length >= 3) {
      showToast("You can select a maximum of 3 videos.");
      return;
    }

    try {
      // 2. Use pickMultipleMedia which is the modern approach.
      final List<XFile> pickedFiles = await ImagePicker().pickMultipleMedia();

      if (!mounted || pickedFiles.isEmpty) return;

      // 3. IMPORTANT: Filter for video files only.
      final List<File> selectedVideos = pickedFiles
          .where((file) {
        final path = file.path.toLowerCase();
        return path.endsWith('.mp4') ||
            path.endsWith('.mov') ||
            path.endsWith('.avi') ||
            path.endsWith('.mkv');
      })
          .map((file) => File(file.path))
          .toList();

      if (selectedVideos.isEmpty) {
        showToast('No video files were selected.');
        return;
      }

      // 4. Enforce the 3 video limit after selection.
      final totalVideos = _videoFiles.length + selectedVideos.length;
      if (totalVideos > 3) {
        showToast("You can only add up to 3 videos in total.");
        final remainingSlots = 3 - _videoFiles.length;
        _videoFiles.addAll(selectedVideos.take(remainingSlots));
      } else {
        _videoFiles.addAll(selectedVideos);
      }

      setState(() {}); // Refresh the UI

    } catch (e) {
      print('Error picking videos: $e');
      showToast('An error occurred while picking videos.');
    }
  }






  /// Builds the UI for video selection and preview using the UnifiedMediaViewer.
  Widget _buildVideoSelector() {
    if (_videoFiles.isNotEmpty) {
      // If videos are selected, show the UnifiedMediaViewer for preview.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: SizedBox(
          width: double.infinity, // Prevent layout errors
          child: UnifiedMediaViewer(
            // A smaller aspect ratio for a less intrusive preview
            aspectRatio: 1.4,
            mediaItems: List.generate(_videoFiles.length, (index) { // <-- Use List.generate
              final file = _videoFiles[index];
              return MediaItem(
                networkUrl: file.path,
                type: MediaType.video,
                onDelete: () { // <-- PROVIDE THE FUNCTION
                  setState(() {
                    _videoFiles.removeAt(index);
                  });
                },
              );
            }),
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }




  // Font selection dialog.

  Widget showFontSelectionDialog(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: Constant.ALTER_EGO_FONT_STYLES
              .map((e) => ListTile(
                    title: e,
                    onTap: () {
                      var index = Constant.ALTER_EGO_FONT_STYLES.indexOf(e);
                      c.selectFont(index);
                      Navigator.pop(context);
                    },
                  ))
              .toList()),
    );
  }

  Widget _imagesGridView() {
    return Container(
      width: 400,
      alignment: Alignment.center,
      padding: EdgeInsets.all(20),
      child: GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: 5,
        children: List.generate(c.images.length, (index) {
          File imageFile = c.images[index];
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.file(
                imageFile,
                width: 200,
                height: 300,
                fit: BoxFit.cover,
              ),
              Positioned(
                right: -2,
                top: -9,
                child: IconButton(
                  icon: Icon(
                    Icons.cancel,
                    color: Colors.red,
                    size: 18,
                  ),
                  onPressed: () => setState(() {
                    c.images.removeAt(index);
                  }),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }




  /*void startAiChat(CreateSessionModel session, String input) async {
    final request = CompleteReq(
        prompt: input, model: kTranslateModelV3, max_tokens: 800);

    _subscription = chatGPT!
        .onCompleteStream(request: request)
        .distinct()
        .first
        .asStream()
        .listen((response) async {
      print("ADVISE IS : ${response!.choices.first.text}");
      final theResponse = response.choices.first.text.trim();
      final String latestContext = "You are a sweet, smart and friendly AI Assistance called Claire and my first message to you says: $input. And then you responded: $theResponse";
      updateSessionForAI(session, latestContext);
      await sendAiAdvise(session, theResponse);
    });
  }*/



  Future <void> sendAiAdvise(CreateSessionModel session, String response) async {
    final advise = response.toString();

    CollectionReference ref =
    FirebaseFirestore.instance
        .collection("sessions")
        .doc(session.sessionId!)
        .collection("comments");

    String docId = ref.doc().id;

    final _commentModel = CommentSessionModel(
        alterEgoId: 'CLaiRE',
        audioUrl: '',
        commentId: docId,
        flagged: session.flagged!,
        imageUrls: [],
        image1: '',
        image2: '',
        thanks: [],
        numberOfThanks: 0,
        isUserAdmin: true,
        message: advise,
        timeCreated: Timestamp.now(),
        userAvatarUrl: '',
        userId: 'CLaiRE',
        userNickname: 'CLaiRE',
        originalAdviseCategory: session.category1);

    await ref.doc(docId).set(_commentModel.toJson());


    firebaseServices.addCommentNotification(
      title: session.title ?? '',
      docId: session.sessionId!,
      sender: 'CLaiRE',
    );

    updateSessionTimeLastActivity(session);
    saveAIAlterEgoCommentActivity();
  }


  /// Update a session's conversation context for AI when new comment is made.

  Future<void> updateSessionForAI(CreateSessionModel session, String theContext) async {
    FirebaseFirestore.instance
        .collection("sessions")
        .doc(session.sessionId)
        .set({
      'timeLastActivity': FieldValue.serverTimestamp(),
      'theContext': theContext,
    },
      SetOptions(merge: true),
    );
    logger.d('Successfully updated conversation context for AI');
  }


  /// Save alter ego comment activity

  Future<void> saveAIAlterEgoCommentActivity() async {
    final Session? theSession = featuredSessionModel;
    final dateCreated = FieldValue.serverTimestamp();
    final sessionId = theSession?.sessionId;
    final sessionOwnerId = theSession?.userId;
    final sessionOwnerAvatar = theSession?.userAvatarUrl.toString();
    final sessionOwnerNickname = theSession?.userNickname.toString();
    final sessionVisitorId = 'CLaiRE';
    final sessionVisitorNickname = 'CLaiRE';
    final sessionVisitorAvatar = "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fclaire_icon.png?alt=media&token=5e14455d-0402-453d-80d0-63b55890f691";
    final activityMessage = "$sessionVisitorNickname commented on $sessionOwnerNickname's session.";
    final activityType = "comment";
    final userActivityId = "";
    FirebaseFirestore.instance
        .collection('user_activity')
        .add({
      "activityMessage": activityMessage,
      "activityType": activityType,
      "clientAvatarUrl": sessionVisitorAvatar,
      "clientId": sessionVisitorId,
      "clientNickname": sessionVisitorNickname,
      "dateCreated": dateCreated,
      "sessionId": sessionId,
      "userActivityId": userActivityId,
      "userId": sessionOwnerId,
      "userNickname": sessionOwnerNickname,
      "userAvatarUrl": sessionOwnerAvatar,

    },
    );
    logger.d('Successfully saved your comment activity');
    print('Activity Message: $activityMessage');

  }



  /// Update a session's timeLastActivity when new comment is made.

  Future<void> updateSessionTimeLastActivity(CreateSessionModel? session) async {
    FirebaseFirestore.instance
        .collection("sessions")
        .doc(session?.sessionId)
        .update({
      'timeLastActivity': FieldValue.serverTimestamp(),
      'respondentUserId': 'ClaireAI',
    },
    );
    logger.d('Successfully updated time of last activity');

  }



  /// Create quick sessions.



  createQuickSession() async {
    userModel = await _firebaseServices.getUserInfo();

    CreateSessionModel sessionObject = CreateSessionModel();

    if (recordFile != null) {
      sessionObject.audioUrl = await _firebaseServices.uploadSound(recordFile!);
      sessionObject.containsAudio = true;
    }

    List<String> imageDownloadUrls = <String>[];
    for (var image in imageList) {
      imageDownloadUrls.add(await _firebaseServices.uploadImage(image));
    }
    sessionObject.imageUrls = imageDownloadUrls;
  
    sessionObject.userAvatarUrl = userModel.avatarUrl;
    sessionObject.userNickname = userModel.nickname;
    sessionObject.title = sessionTitleController.text;
    sessionObject.private = c.acceptReplies.value;
    sessionObject.repliesEnabled = false;
    sessionObject.message = sessionTextEditingController.text;
    sessionObject.colorHex =
    Constant.DIARY_COLORS_HEXCODE[c.selectedBackgroundColor.value];
    sessionObject.sessionId = uuid.v1();
    sessionObject.userId = userModel.userId;
    sessionObject.moodId = mood;
    sessionObject.location = '#QuickSession';
    sessionObject.timeLastActivity = Timestamp.now();

    bool isSuccessfull =
    await _firebaseServices.createSession(session: sessionObject);

    await _firebaseServices.updateUserMoods(mood);

    // Call saveUserActivity
    await _firebaseServices.saveUserActivity(
      activityType: 'session',
      activityMessage: "You started a quick diary session: '${sessionObject.title}'.",
      sessionId: sessionObject.sessionId,
    );

    Future.delayed(Duration(seconds: 4), () {
      _showQuickInterstitialAd();
    });

    _firebaseServices.subscribeToYourSession(userModel.nickname.toString(), sessionObject);

    _firebaseServices.notifyClaireForSession(userModel.nickname.toString(), sessionObject);

  }





  /// CREATE NEW SESSION METHOD IS HERE
  createSession() async {
    setState(() {
      isLoading = true;
    });

    try {
      userModel = await _firebaseServices.getUserInfo();
      CreateSessionModel sessionObject = CreateSessionModel();
      if (recordFile != null) {
        sessionObject.audioUrl =
        await _firebaseServices.uploadSound(recordFile!);
        sessionObject.containsAudio = true;
      }

      // --- Image Upload ---
      try {
        List<Future<String>> uploadTasks = c.images.map((imageFile) {
          return _firebaseServices.uploadImage(imageFile);
        }).toList();
        List<String> imageDownloadUrls = await Future.wait(uploadTasks);
        sessionObject.imageUrls = imageDownloadUrls;
        print('${imageDownloadUrls.length} images uploaded successfully.');
      } catch (e) {
        print('Error uploading images: $e');
        // Optionally, show an error message to the user here.
      }

      // --- Multi-Video Upload Logic ---
      if (_videoFiles.isNotEmpty) {
        List<String> videoDownloadUrls = [];
        List<String> thumbnailDownloadUrls = [];

        List<Future<List<String>>> allUploadTasks =
        _videoFiles.map((videoFile) {
          return Future.wait([
            _firebaseServices.uploadVideoToStorage(videoFile),
            _firebaseServices.uploadVideoThumbnailToStorage(videoFile),
          ]);
        }).toList();

        List<List<String>> allResults = await Future.wait(allUploadTasks);

        for (var resultPair in allResults) {
          videoDownloadUrls.add(resultPair[0]);
          thumbnailDownloadUrls.add(resultPair[1]);
        }

        sessionObject.videoUrls = videoDownloadUrls;
        sessionObject.videoThumbnailUrls = thumbnailDownloadUrls;
        sessionObject.containsVideo = true;
        print('${videoDownloadUrls.length} videos uploaded successfully.');
      }

      SessionCategorizer.assignCategories(
          sessionObject, sessionTextEditingController.text);

      sessionObject.userAvatarUrl = userModel.avatarUrl;
      sessionObject.userNickname = userModel.nickname;
      sessionObject.title = sessionTitleController.text;
      sessionObject.private = c.acceptReplies.value;
      sessionObject.repliesEnabled = c.acceptReplies.value;
      sessionObject.message = sessionTextEditingController.text;
      sessionObject.colorHex = Constant.DIARY_COLORS_HEXCODE[c.selectedBackgroundColor.value];
      sessionObject.sessionId = uuid.v1();
      sessionObject.userId = userModel.userId;
      sessionObject.moodId = Constant.USER_SESSION_MOODS.indexOf(c.sessionMood.value);
      sessionObject.location = _location;
      sessionObject.timeLastActivity = Timestamp.now();

      await _firebaseServices.createSession(session: sessionObject);

      await _firebaseServices.updateUserMoods(Constant.USER_SESSION_MOODS.indexOf(c.sessionMood.value));

      await _firebaseServices.saveUserActivity(
        activityType: 'session',
        activityMessage:
        "You started a new diary session: '${sessionObject.title}'.",
        sessionId: sessionObject.sessionId,
      );

      Hive.box("draft").clear();

      categorize(sessionObject);

      isOriginalSession(sessionTextEditingController.text);

      ascertainCurrentLoveCount();

      Future.delayed(Duration(seconds: 4), () {
        _showInterstitialAd();
      });

      _firebaseServices.subscribeToYourSession(userModel.nickname.toString(), sessionObject);

      _firebaseServices.notifyClaireForSession(userModel.nickname.toString(), sessionObject);

      // This will only be called after all previous awaits are complete.
      if (mounted && sessionObject.sessionId != null && sessionObject.sessionId!.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => NotifiedSessionDetails(sessionId: sessionObject.sessionId!),
          ),
        );
      }

    } catch (e) {
      // If any error occurs during the process, log it.
      print("An error occurred during session creation: $e");
      // Optionally, show a toast or dialog to the user that something went wrong.

    } finally {
      // This block will ALWAYS run, whether the try block succeeds or fails.
      // This is the perfect place to turn off the loading indicator.
      if (mounted) { // Check if the widget is still in the tree
        setState(() {
          sessionTextEditingController.clear();
          isLoading = false;
          imageList.clear();
          _videoFiles.clear();
          recordFile = null;
        });
      }
    }
  }



  /// Create new session interstitial ad.

  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;

  // Create interstitial ad.

  void _createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: Platform.isAndroid
          ? "ca-app-pub-2404156870680632/3729355238"
          : Platform.isIOS
              ? "ca-app-pub-2404156870680632/7377790353"
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
            _createInterstitialAd();
          }
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _createInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _createInterstitialAd();
        },
      );
      _interstitialAd!.show();
    }
  }



  InterstitialAd? _quickInterstitialAd;
  int _quickInterstitialLoadAttempts = 0;

  // Create quick session interstitial ad.

  void _createQuickInterstitialAd() {
    InterstitialAd.load(
      adUnitId: Platform.isAndroid
          ? "ca-app-pub-2404156870680632/8800174899"
          : Platform.isIOS
          ? "ca-app-pub-2404156870680632/1147263196"
          : '',
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _quickInterstitialAd = ad;
          _quickInterstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Failed to load an interstitial ad: ${error.message}');
          _quickInterstitialLoadAttempts += 1;
          _quickInterstitialAd = null;
          if (_quickInterstitialLoadAttempts <= maxFailedLoadAttempts) {
            _createQuickInterstitialAd();
          }
        },
      ),
    );
  }

  void _showQuickInterstitialAd() {
    if (_quickInterstitialAd != null) {
      _quickInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _createQuickInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _createQuickInterstitialAd();
        },
      );
      _quickInterstitialAd!.show();
    }
  }



  void navigateToNewSession(CreateSessionModel? session) {
    print('done');
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => SessionPostDetailsScreen(
                  sessionModel: session,
                )));
  }



  void categorize(CreateSessionModel createSessionModel) {
    if (createSessionModel.message!.contains('love') &&
        createSessionModel.message!.contains('relationship')) {
      _firebaseServices.addToCategory(
          AppString.loveAndRelationship, createSessionModel);
    }

    if (createSessionModel.message!.contains('marriage') &&
        createSessionModel.message!.contains('family')) {
      _firebaseServices.addToCategory(
          AppString.marriageAndFamily, createSessionModel);
    }

    if (createSessionModel.message!.contains('sex') &&
        createSessionModel.message!.contains('dating')) {
      _firebaseServices.addToCategory(
          AppString.sexAndDating, createSessionModel);
    }

    if (createSessionModel.message!.contains('school') &&
        createSessionModel.message!.contains('education')) {
      _firebaseServices.addToCategory(
          AppString.schoolAndEducation, createSessionModel);
    }

    if (createSessionModel.message!.contains('work') &&
        createSessionModel.message!.contains('career')) {
      _firebaseServices.addToCategory(
          AppString.workAndCareer, createSessionModel);
    }

    if (createSessionModel.message!.contains('hate') &&
        createSessionModel.message!.contains('abuse')) {
      _firebaseServices.addToCategory(
          AppString.hateAndAbuse, createSessionModel);
    }

    if (createSessionModel.message!.contains('friends') &&
        createSessionModel.message!.contains('fun')) {
      _firebaseServices.addToCategory(
          AppString.friendsAndFun, createSessionModel);
    }

    if (createSessionModel.message!.contains('depression') &&
        createSessionModel.message!.contains('anxiety')) {
      _firebaseServices.addToCategory(
          AppString.depressionAndAnxiety, createSessionModel);
    }

    if (createSessionModel.message!.contains('help') &&
        createSessionModel.message!.contains('charity')) {
      _firebaseServices.addToCategory(
          AppString.helpAndCharity, createSessionModel);
    }

    if (createSessionModel.message!.contains('health') &&
        createSessionModel.message!.contains('fitness')) {
      _firebaseServices.addToCategory(
          AppString.healthAndFitness, createSessionModel);
    }

    if (createSessionModel.message!.contains('husband') &&
        createSessionModel.message!.contains('wife')) {
      _firebaseServices.addToCategory(
          AppString.husbandAndWife, createSessionModel);
    }

    if (createSessionModel.message!.contains('boyfriend') &&
        createSessionModel.message!.contains('girlfriend')) {
      _firebaseServices.addToCategory(
          AppString.boyfriendAndGirlfriend, createSessionModel);
    }

    if (createSessionModel.message!.contains('food') &&
        createSessionModel.message!.contains('drink')) {
      _firebaseServices.addToCategory(
          AppString.foodAndDrink, createSessionModel);
    }

    if (createSessionModel.message!.contains('birthday') &&
        createSessionModel.message!.contains('anniversary')) {
      _firebaseServices.addToCategory(
          AppString.birthdayAndAnniversary, createSessionModel);
    }

    if (createSessionModel.message!.contains('prayer') &&
        createSessionModel.message!.contains('thanksgiving')) {
      _firebaseServices.addToCategory(
          AppString.prayerAndThanksgiving, createSessionModel);
    }

    if (createSessionModel.message!.contains('childhood') &&
        createSessionModel.message!.contains('memory')) {
      _firebaseServices.addToCategory(
          AppString.childhoodAndMemory, createSessionModel);
    }

    if (createSessionModel.message!.contains('parents') &&
        createSessionModel.message!.contains('children')) {
      _firebaseServices.addToCategory(
          AppString.parentsAndChildren, createSessionModel);
    }

    if (createSessionModel.message!.contains('business') &&
        createSessionModel.message!.contains('entrepreneur')) {
      _firebaseServices.addToCategory(
          AppString.businessAndEntrepreneur, createSessionModel);
    }

    if (createSessionModel.message!.contains('art') &&
        createSessionModel.message!.contains('photography')) {
      _firebaseServices.addToCategory(
          AppString.artsAndPhotography, createSessionModel);
    }

    if (createSessionModel.message!.contains('music') &&
        createSessionModel.message!.contains('videos')) {
      _firebaseServices.addToCategory(
          AppString.musicAndVideos, createSessionModel);
    }

    if (createSessionModel.message!.contains('riddles') &&
        createSessionModel.message!.contains('jokes')) {
      _firebaseServices.addToCategory(
          AppString.riddlesAndJokes, createSessionModel);
    }

    if (createSessionModel.message!.contains('television') &&
        createSessionModel.message!.contains('movies')) {
      _firebaseServices.addToCategory(
          AppString.televisionAndMovies, createSessionModel);
    }
  }
}
