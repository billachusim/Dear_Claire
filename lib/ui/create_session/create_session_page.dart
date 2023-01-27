import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/services/user_model.dart';
import 'package:dear_claire/ui/create_session/session_model.dart';
import 'package:dear_claire/ui/create_session/sound/custom_play_sound_widget.dart';
import 'package:dear_claire/ui/create_session/view_singlesession_widget.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:emoji_chooser/emoji_chooser.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:dear_claire/widgets/toast.dart';
import 'package:hive/hive.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:uuid/uuid.dart';
import '../featured/model/comment_session_model.dart';
import '../featured/model/session.dart';
import 'create_session_controller.dart';
import 'sound/sound_widget.dart';
import 'package:http/http.dart' as http;


class CreateSessionPage extends StatefulWidget {
  const CreateSessionPage({Key? key}) : super(key: key);

  @override
  _CreateSessionPageState createState() => _CreateSessionPageState();
}

const int maxFailedLoadAttempts = 3;

class _CreateSessionPageState extends State<CreateSessionPage> {
  TextEditingController sessionTitleController = TextEditingController();
  final FirebaseServices _firebaseServices = FirebaseServices();
  final c = Get.find<CreateSessionController>();

  Session? featuredSessionModel;

  final apiKey = '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';
  final endpoint = 'https://api.openai.com/v1/engines/davinci/completions';

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

  ///this function is triggered when user clicks on any emoji
  appendEmojiToText(EmojiData emoji) {
    var newText = sessionTextEditingController.text + emoji.char;
    sessionTextEditingController.text = newText;
  }

//initialize the audio record file that stores user audio record. null by default
  File? recordFile;
  String? videoFile;
  String? videoThumbnail;


//initialize the image list stores user selected images.
  List<Asset> imageList = <Asset>[];

//for showing loading indicator when uploading data;
  bool isLoading = false;
  bool acceptReplies = false;
  bool followClaire = true;
  String sessionMood = 'Current Mood';
  String? _location = '';



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
      _location = ("in  ${place.administrativeArea}, ${place.country}");
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
    _createInterstitialAd();
    _createQuickInterstitialAd();
    randomizeBackgroundColor();
    initializeDatabaseObject();
    sessionTextFocusNode = FocusNode();
    Future.delayed(Duration(seconds: 5), () {
      sessionTextFocusNode.requestFocus();
    }
    );
    randomizeNewDiarySessionToast();
  }

  void initializeDatabaseObject() async {
    box = await Hive.openBox('draft');
    String text = box.get("text");
    print("text is:$text");
    if (text.isNotEmpty) {
      sessionTextEditingController.text = text;
    }
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
    // Clean up the focus node when the Form is disposed.
    sessionTextFocusNode.dispose();
    sessionTextEditingController.dispose();
    sessionTitleController.dispose();
    super.dispose();
  }


  /// checks if advise meets original advise rules...
  /// if it does, then increment necessary counts.
  Future<bool> isOriginalSession(String sessionText) async {
    final _session = sessionText.toString();
    final _length = _session.length;

    if (_session.contains("ear"))
      if (_session.contains("laire"))
        if (_length >= 50)

      {
        incrementSessionCount();
        incrementTotalLoveCount();

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
        iOS: IOSNotificationDetails(
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
                          Icon(Icons.lock),
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
                          Icon(Icons.lock),
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
                              Icon(Icons.location_on_sharp),
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
      () => SafeArea(
        child: Scaffold(
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
                          Text("Please Wait",
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
                              textAlign: TextAlign.center,
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
                        Container(
                            height: 100.h,
                            width: 100.w,
                            child: IconButton(
                              icon: Icon(
                                Icons.mic_rounded,
                                size: 80,
                                color: Pallet.colorWhite,
                              ),
                              onPressed: () async {
                                var data = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => SoundRecorderWidget(
                                          onRecordComplete: (recordFile) {},
                                        )));
                                if (data != null) {
                                  recordFile = data;
                                  setState(() {});
                                }
                              },
                            )),

                        SizedBox(height: 20,),



                  /// Introducing Quick Sessions.


                        Visibility(
                          visible: !isTyping,
                            child: Container(
                              margin: const EdgeInsets.only(top: 4),
                              child: Column(
                                children: [

                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Container(
                                      padding: EdgeInsets.all(2),
                                      height: 20,
                                      width: 160,
                                      decoration: BoxDecoration(
                                          color: Pallet.colorWhite,
                                          borderRadius: BorderRadius.circular(20)
                                      ),
                                      child: Text(
                                        "Share A Quick Session",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 5,),

                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: <Widget>[

                                        GestureDetector(
                                          onTap: (){
                                            String quickSessionMessage = "Dear Claire, I'm feeling so alive today!";
                                            String quickSessionTitle = "Feeling Alive Today";
                                            mood = 1;
                                            sessionTitleController.text = quickSessionTitle;
                                            sessionTextEditingController.text = quickSessionMessage;

                                              Navigator.of(context).pop();
                                              createQuickSession();
                                              showToast(AppString.started_new_session);
                                          },

                                          child: Container(
                                            width: 77.0,
                                            margin: EdgeInsets.all(2),
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius: BorderRadius.circular(15)
                                            ),
                                            child: Column(
                                              children: [
                                                Align(
                                                    alignment: Alignment.center,
                                                    child: Text("I'm Alive!",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.italic,
                                                        fontSize: 15,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),



                                        GestureDetector(
                                          onTap: (){
                                            String quickSessionMessage = "Dear Claire,\n"
                                                "Hmmm. Something's in the air o...\n"
                                                "It seems like I'm falling in love today!";
                                            String quickSessionTitle = "Falling in Love Today";
                                            mood = 4;
                                            sessionTitleController.text = quickSessionTitle;
                                            sessionTextEditingController.text = quickSessionMessage;

                                              Navigator.of(context).pop();
                                              createQuickSession();
                                              showToast(AppString.started_new_session);
                                          },

                                          child: Container(
                                            width: 110.0,
                                            margin: EdgeInsets.all(2),
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius: BorderRadius.circular(15)
                                            ),
                                            child: Column(
                                              children: [
                                                Align(
                                                    alignment: Alignment.center,
                                                    child: Text("Falling in love!",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.italic,
                                                        fontSize: 15,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),


                                        GestureDetector(
                                          onTap: (){
                                            String quickSessionMessage = "Dear Claire, I'm so motivated and ready to face today!\n"
                                                "Ginger oh ginger... Na you dey ginger me o ginger!";
                                            String quickSessionTitle = "Feeling Gingered Today";
                                            mood = 15;
                                            sessionTitleController.text = quickSessionTitle;
                                            sessionTextEditingController.text = quickSessionMessage;

                                              Navigator.of(context).pop();
                                              createQuickSession();
                                              showToast(AppString.started_new_session);
                                          },

                                          child: Container(
                                            width: 135.0,
                                            margin: EdgeInsets.all(2),
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                                color: Colors.orange,
                                                borderRadius: BorderRadius.circular(15)
                                            ),
                                            child: Column(
                                              children: [
                                                Align(
                                                    alignment: Alignment.center,
                                                    child: Text("Feeling gingered!",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.italic,
                                                        fontSize: 15,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),



                                        GestureDetector(
                                          onTap: (){
                                            String quickSessionMessage = "Dear Claire, I'm feeling so fly today. Woo!\n"
                                                "Flamboyance is a state of mind.\n"
                                                "Nobody can tell me anything.";
                                            String quickSessionTitle = "Feeling So Fly!";
                                            mood = 16;
                                            sessionTitleController.text = quickSessionTitle;
                                            sessionTextEditingController.text = quickSessionMessage;

                                              Navigator.of(context).pop();
                                              createQuickSession();
                                              showToast(AppString.started_new_session);
                                          },

                                          child: Container(
                                            width: 45.0,
                                            margin: EdgeInsets.all(2),
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                                color: Colors.purple,
                                                borderRadius: BorderRadius.circular(15)
                                            ),
                                            child: Column(
                                              children: [
                                                Align(
                                                    alignment: Alignment.center,
                                                    child: Text("Fly!",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.italic,
                                                        fontSize: 15,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),



                                  SizedBox(height: 8,),

                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: <Widget>[

                                        GestureDetector(
                                          onTap: (){
                                            String quickSessionMessage = "Dear Claire, I'm feeling sad.\n"
                                                "What could this be? I'm thinking, lost in my sad thoughts.";
                                            String quickSessionTitle = "Feeling Sad";
                                            mood = 2;
                                            sessionTitleController.text = quickSessionTitle;
                                            sessionTextEditingController.text = quickSessionMessage;

                                              Navigator.of(context).pop();
                                              createQuickSession();
                                              showToast(AppString.started_new_session);
                                          },

                                          child: Container(
                                            width: 112.0,
                                            margin: EdgeInsets.all(2),
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                                color: Colors.blueAccent,
                                                borderRadius: BorderRadius.circular(15)
                                            ),
                                            child: Column(
                                              children: [
                                                Align(
                                                    alignment: Alignment.center,
                                                    child: Text("Mtcheew, Sad",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.italic,
                                                        fontSize: 15,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),


                                        GestureDetector(
                                          onTap: (){
                                            String quickSessionMessage = "Dear Claire, I'm really surprised. WOW!";
                                            String quickSessionTitle = "Surprise!!!";
                                            mood = 11;
                                            sessionTitleController.text = quickSessionTitle;
                                            sessionTextEditingController.text = quickSessionMessage;

                                              Navigator.of(context).pop();
                                              createQuickSession();
                                              showToast(AppString.started_new_session);
                                          },

                                          child: Container(
                                            width: 75.0,
                                            margin: EdgeInsets.all(2),
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                                color: Colors.brown,
                                                borderRadius: BorderRadius.circular(15)
                                            ),
                                            child: Column(
                                              children: [
                                                Align(
                                                    alignment: Alignment.center,
                                                    child: Text("Surprise!",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.italic,
                                                        fontSize: 15,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),


                                        GestureDetector(
                                          onTap: (){
                                            String quickSessionMessage = "Dear Claire,\n"
                                                "I'm kinda feeling anxious today txmqaqkcqtfch.\n"
                                                "I really need to get hold of myselfkc";
                                            String quickSessionTitle = "So Anxious Today";
                                            mood = 8;
                                            sessionTitleController.text = quickSessionTitle;
                                            sessionTextEditingController.text = quickSessionMessage;

                                            Navigator.of(context).pop();
                                              createQuickSession();
                                              showToast(AppString.started_new_session);
                                          },

                                          child: Container(
                                            width: 80.0,
                                            margin: EdgeInsets.all(2),
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                                color: Colors.blueGrey,
                                                borderRadius: BorderRadius.circular(15)
                                            ),
                                            child: Column(
                                              children: [
                                                Align(
                                                    alignment: Alignment.center,
                                                    child: Text("Anxious",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.italic,
                                                        fontSize: 15,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),



                                        GestureDetector(
                                          onTap: (){
                                            String quickSessionMessage = "Dear Claire, I'm just so sick and tired.";
                                            String quickSessionTitle = "Sick And Tired";
                                            mood = 9;
                                            sessionTitleController.text = quickSessionTitle;
                                            sessionTextEditingController.text = quickSessionMessage;

                                              Navigator.of(context).pop();
                                              createQuickSession();
                                              showToast(AppString.started_new_session);
                                          },

                                          child: Container(
                                            width: 107.0,
                                            margin: EdgeInsets.all(2),
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius: BorderRadius.circular(15)
                                            ),
                                            child: Column(
                                              children: [
                                                Align(
                                                    alignment: Alignment.center,
                                                    child: Text("Sick and tired",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.italic,
                                                        fontSize: 15,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),







                                  SizedBox(height: 8,),

                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: <Widget>[

                                        GestureDetector(
                                          onTap: (){
                                            String quickSessionMessage = "Dear Claire,\n"
                                                "Hmmm. This must be jealousy all over me. I don't think I'm envious though.";
                                            String quickSessionTitle = "Jealous Mood";
                                            mood = 12;
                                            sessionTitleController.text = quickSessionTitle;
                                            sessionTextEditingController.text = quickSessionMessage;

                                              Navigator.of(context).pop();
                                              createQuickSession();
                                              showToast(AppString.started_new_session);
                                          },

                                          child: Container(
                                            width: 85.0,
                                            margin: EdgeInsets.all(2),
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.circular(15)
                                            ),
                                            child: Column(
                                              children: [
                                                Align(
                                                    alignment: Alignment.center,
                                                    child: Text("I'm jealous",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.italic,
                                                        fontSize: 15,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),



                                        GestureDetector(
                                          onTap: (){
                                            String quickSessionMessage = "Dear Claire,\n"
                                                "I'm falling out of love again.\n"
                                                "I don't want to get philosophical but our mistakes only leads us to becoming a better version of ourselves.\n"
                                                "Heartbroken, yet, we move.";
                                            String quickSessionTitle = "Out Of Love";
                                            mood = 5;
                                            sessionTitleController.text = quickSessionTitle;
                                            sessionTextEditingController.text = quickSessionMessage;

                                              Navigator.of(context).pop();
                                              createQuickSession();
                                              showToast(AppString.started_new_session);
                                          },

                                          child: Container(
                                            width: 105.0,
                                            margin: EdgeInsets.all(2),
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius: BorderRadius.circular(15)
                                            ),
                                            child: Column(
                                              children: [
                                                Align(
                                                    alignment: Alignment.center,
                                                    child: Text("Heartbroken",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.italic,
                                                        fontSize: 15,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),


                                        GestureDetector(
                                          onTap: (){
                                            String quickSessionMessage = "Dear Claire, I'm afraid.\n"
                                                "Just afraid. I'll be careful. I promise.";
                                            String quickSessionTitle = "I'm Afraid Right Now";
                                            mood = 10;
                                            sessionTitleController.text = quickSessionTitle;
                                            sessionTextEditingController.text = quickSessionMessage;

                                              Navigator.of(context).pop();
                                              createQuickSession();
                                              showToast(AppString.started_new_session);
                                          },

                                          child: Container(
                                            width: 80.0,
                                            margin: EdgeInsets.all(2),
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                                color: Colors.deepPurpleAccent,
                                                borderRadius: BorderRadius.circular(15)
                                            ),
                                            child: Column(
                                              children: [
                                                Align(
                                                    alignment: Alignment.center,
                                                    child: Text("I'm afraid",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.italic,
                                                        fontSize: 15,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),



                                        GestureDetector(
                                          onTap: (){
                                            String quickSessionMessage = "Dear Claire, I'm feeling so fly today!\n"
                                                " Flamboyance is a state of mind";
                                            String quickSessionTitle = "I'm So Embarrassed";
                                            mood = 14;
                                            sessionTitleController.text = quickSessionTitle;
                                            sessionTextEditingController.text = quickSessionMessage;

                                              Navigator.of(context).pop();
                                              createQuickSession();
                                              showToast(AppString.started_new_session);
                                          },

                                          child: Container(
                                            width: 130.0,
                                            margin: EdgeInsets.all(2),
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                                color: Colors.brown,
                                                borderRadius: BorderRadius.circular(15)
                                            ),
                                            child: Column(
                                              children: [
                                                Align(
                                                    alignment: Alignment.center,
                                                    child: Text("I'm embarrassed",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.italic,
                                                        fontSize: 15,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),



                                  SizedBox(height: 8,),

                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: <Widget>[

                                        GestureDetector(
                                          onTap: (){
                                            String quickSessionMessage = "Dear Claire, I love you!.";
                                            String quickSessionTitle = "Oh My Claire!";
                                            mood = 17;
                                            sessionTitleController.text = quickSessionTitle;
                                            sessionTextEditingController.text = quickSessionMessage;

                                              Navigator.of(context).pop();
                                              createQuickSession();
                                              showToast(AppString.started_new_session);
                                          },

                                          child: Container(
                                            width: 100.0,
                                            margin: EdgeInsets.all(2),
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                                color: Colors.deepPurple,
                                                borderRadius: BorderRadius.circular(15)
                                            ),
                                            child: Column(
                                              children: [
                                                Align(
                                                    alignment: Alignment.center,
                                                    child: Text("I love Claire!",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.italic,
                                                        fontSize: 15,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),


                                        GestureDetector(
                                          onTap: (){
                                            String quickSessionMessage = "Dear Claire, Hala!\n"
                                                "I'm feeling so excited today!\n"
                                                "I'm so actually hyperactive right now. Woooo!! E for energy!.";
                                            String quickSessionTitle = "I'm excited!";
                                            mood = 3;
                                            sessionTitleController.text = quickSessionTitle;
                                            sessionTextEditingController.text = quickSessionMessage;

                                              Navigator.of(context).pop();
                                              createQuickSession();
                                              showToast(AppString.started_new_session);
                                          },

                                          child: Container(
                                            width: 70.0,
                                            margin: EdgeInsets.all(2),
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                                color: Colors.pink,
                                                borderRadius: BorderRadius.circular(15)
                                            ),
                                            child: Column(
                                              children: [
                                                Align(
                                                    alignment: Alignment.center,
                                                    child: Text("Excited!",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.italic,
                                                        fontSize: 15,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),



                                        GestureDetector(
                                          onTap: (){
                                            String quickSessionMessage = "Dear Claire,\n"
                                                "I think I'm feeling depressed today.\n"
                                                "I'm doing my best to shake out the beast.";
                                            String quickSessionTitle = "I'm Depressed";
                                            mood = 6;
                                            sessionTitleController.text = quickSessionTitle;
                                            sessionTextEditingController.text = quickSessionMessage;

                                              Navigator.of(context).pop();
                                              createQuickSession();
                                              showToast(AppString.started_new_session);
                                          },

                                          child: Container(
                                            width: 85.0,
                                            margin: EdgeInsets.all(2),
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                                color: Colors.amber,
                                                borderRadius: BorderRadius.circular(15)
                                            ),
                                            child: Column(
                                              children: [
                                                Align(
                                                    alignment: Alignment.center,
                                                    child: Text("Depressed",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.italic,
                                                        fontSize: 15,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),





                                        GestureDetector(
                                          onTap: (){
                                            String quickSessionMessage = "Dear Claire,\n"
                                                " I'm feeling upside down today!\n"
                                                " Like... The up side is down... I repeat... The up side is down!";
                                            String quickSessionTitle = "Up Side Is Down!";
                                            mood = 13;
                                            sessionTitleController.text = quickSessionTitle;
                                            sessionTextEditingController.text = quickSessionMessage;

                                              Navigator.of(context).pop();
                                              createQuickSession();
                                              showToast(AppString.started_new_session);
                                          },

                                          child: Container(
                                            width: 105.0,
                                            margin: EdgeInsets.all(2),
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.circular(15)
                                            ),
                                            child: Column(
                                              children: [
                                                Align(
                                                    alignment: Alignment.center,
                                                    child: Text("Upside down",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle: FontStyle.italic,
                                                        fontSize: 15,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ),


                        recordFile != null
                            ? _recordFileWidget()
                            : SizedBox.shrink(),

                        Align(
                            alignment: Alignment.center,
                            child: _imagesGridView()
                        ),

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
                      height: 20.h,
                      width: 25.w,
                      child: IconButton(
                        icon: Icon(Icons.emoji_emotions_outlined,
                            color: Pallet.colorWhite),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext subcontext) {
                              return Container(
                                // height: 250.h,
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: 10),
                                    child: EmojiChooser(
                                      onSelected: (emoji) {
                                        appendEmojiToText(emoji);
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
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
                          var data = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => SoundRecorderWidget(
                                        onRecordComplete: (recordFile) {},
                                      )));
                          if (data != null) {
                            recordFile = data;
                            setState(() {});
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
      ),
    );
  }

  Widget _recordFileWidget() {
    return Container(
      height: 60.h,
      //width: 60.w,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
              child: CustomPlaySoundWidget(filePath: recordFile?.path)
          ),
          Positioned(
              right: 25,
              top: 3,
              child: IconButton(
                  icon: Icon(
                    Icons.cancel,
                    color: Colors.red,
                    size: 24.r,
                  ),
                  onPressed: () => setState(() {
                        recordFile = null;
                      })))
        ],
      ),
    );
  }

  Future<void> loadAssets() async {
    String error = 'No Error Detected';
    try {
      imageList = await MultiImagePicker.pickImages(
        maxImages: 10,
        enableCamera: true,
        selectedAssets: c.images,
        cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
        materialOptions: MaterialOptions(
          actionBarColor: "#abcdef",
          actionBarTitle: "To Dear Claire",
          allViewTitle: "All Photos",
          useDetailsView: false,
          selectCircleStrokeColor: "#000000",
        ),
      );
    } on Exception catch (e) {
      error = e.toString();
    }

    if (!mounted) return;
    setState(() {
      c.images = imageList;
    });
  }

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
          Asset asset = c.images[index];
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              AssetThumb(
                asset: asset,
                width: 200,
                height: 300,
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
                          })))
            ],
          );
        }),
      ),
    );
  }


  Future<String> startAiChat(CreateSessionModel session, String input) async {
    try {
      final body = jsonEncode({
        'prompt': input,
      });

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };

      final uri = Uri.https('api.openai.com', '/v1/engines/davinci/completions');
      final response = await http.post(uri, headers: headers, body: body);
      print('Response body: ${response.body}');
      print('Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print("RESPONSE BODY IS: ${response.body}");
        print(response.statusCode);
        sendAiAdvise(session, response.body);

        return response.body;
      } else {
        throw Exception('Failed to get advice. Error: ${response.statusCode}');
      }
    } catch (e) {
      print(e);
      throw Exception('Failed to get advice. Please check your internet connection');
    }
  }



  void sendAiAdvise(CreateSessionModel session, String response) async {
    if (!await firebaseServices.isUserSignIn(context)) return;


    CollectionReference ref =
    FirebaseFirestore.instance
        .collection("sessions")
        .doc(session.sessionId!)
        .collection("comments");

    String docId = ref.doc().id;

    final _userModel = await firebaseServices.getUserInfo();
    final _commentModel = CommentSessionModel(
        alterEgoId: 'ClaireAI',
        audioUrl: '',
        commentId: docId,
        flagged: session.flagged!,
        imageUrls: [],
        image1: '',
        image2: '',
        thanks: [],
        numberOfThanks: 0,
        isUserAdmin: true,
        message: response,
        timeCreated: Timestamp.now(),
        userAvatarUrl: _userModel.avatarUrl,
        userId: 'ClaireAi',
        userNickname: 'ClaireAi',
        originalAdviseCategory: session.category1);

    await ref.doc(docId).set(_commentModel.toJson());


    firebaseServices.addCommentNotification(
      title: session.title ?? '',
      docId: session.sessionId!,
      sender: 'ClaireAI',
    );

    updateSessionTimeLastActivity(session);
    saveAlterEgoCommentActivity();
  }


  /// Save alter ego comment activity

  Future<void> saveAlterEgoCommentActivity() async {
    final Session? theSession = featuredSessionModel;
    final dateCreated = FieldValue.serverTimestamp();
    final sessionId = theSession?.sessionId;
    final sessionOwnerId = theSession?.userId;
    final sessionOwnerAvatar = theSession?.userAvatarUrl.toString();
    final sessionOwnerNickname = theSession?.userNickname.toString();
    final sessionVisitorId = 'ClaireAI';
    final sessionVisitorNickname = 'ClaireAI';
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

    if (imageList != null) {
      List<String> imageDownloadUrls = <String>[];
      for (var image in imageList) {
        imageDownloadUrls.add(await _firebaseServices.uploadImage(image));
      }
      sessionObject.imageUrls = imageDownloadUrls;
    }

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

    Future.delayed(Duration(seconds: 4), () {
      _showQuickInterstitialAd();
    });

    _firebaseServices.subscribeToYourSession(userModel.nickname.toString(), sessionObject);

    startAiChat(sessionObject, sessionTextEditingController.text);

  }





  /// CREATE NEW SESSION METHOD IS HERE


  createSession() async {
    setState(() {
      isLoading = true;
    });

    userModel = await _firebaseServices.getUserInfo();
    CreateSessionModel sessionObject = CreateSessionModel();
    if (recordFile != null) {
      sessionObject.audioUrl = await _firebaseServices.uploadSound(recordFile!);
      sessionObject.containsAudio = true;
    }

    if (imageList != null) {
      List<String> imageDownloadUrls = <String>[];
      for (var image in imageList) {
        imageDownloadUrls.add(await _firebaseServices.uploadImage(image));
      }
      sessionObject.imageUrls = imageDownloadUrls;
    }

    if (videoFile != null) {
      sessionObject.videoUrl = videoFile;
      sessionObject.containsVideo = true;
    }

    /// Adding a category tag to every session created.

    if (sessionTextEditingController.text.contains('love'))
    {
      sessionObject.category1 = 'love and relationship';
      sessionObject.category2 = 'sex and dating';
      sessionObject.category3 = 'boyfriend and girlfriend';
      sessionObject.category4 = 'birthdays and anniversary';
    }

    if (sessionTextEditingController.text.contains('relationship'))
    {
      sessionObject.category1 = 'love and relationship';
      sessionObject.category2 = 'sex and dating';
      sessionObject.category3 = 'boyfriend and girlfriend';
      sessionObject.category4 = 'birthdays and anniversary';
    }

    if (sessionTextEditingController.text.contains('marriage'))
    {
      sessionObject.category1 = 'marriage and family';
      sessionObject.category2 = 'husband and wife';
      sessionObject.category3 = 'birthdays and anniversary';
    }

    if (sessionTextEditingController.text.contains('family'))
    {
      sessionObject.category1 = 'marriage and family';
      sessionObject.category2 = 'husband and wife';
      sessionObject.category3 = 'birthdays and anniversary';
    }


    if (sessionTextEditingController.text.contains('sex'))
    {
      sessionObject.category1 = 'sex and dating';
      sessionObject.category2 = 'love and relationship';
      sessionObject.category3 = 'boyfriend and girlfriend';
    }

    if (sessionTextEditingController.text.contains('dating'))
    {
      sessionObject.category1 = 'sex and dating';
      sessionObject.category2 = 'love and relationship';
      sessionObject.category3 = 'boyfriend and girlfriend';
    }

    if (sessionTextEditingController.text.contains('school'))
    {
      sessionObject.category1 = 'school and education';
      sessionObject.category2 = 'work and career';
    }

    if (sessionTextEditingController.text.contains('education'))
    {
      sessionObject.category1 = 'school and education';
      sessionObject.category2 = 'work and career';
    }

    if (sessionTextEditingController.text.contains('work'))
    {
      sessionObject.category1 = 'work and career';
      sessionObject.category2 = 'business and entrepreneur';
    }

    if (sessionTextEditingController.text.contains('career'))
    {
      sessionObject.category1 = 'work and career';
      sessionObject.category2 = 'business and entrepreneur';
    }

    if (sessionTextEditingController.text.contains('office'))
    {
      sessionObject.category1 = 'work and career';
      sessionObject.category2 = 'business and entrepreneur';
    }

    if (sessionTextEditingController.text.contains('job'))
    {
      sessionObject.category1 = 'work and career';
      sessionObject.category2 = 'business and entrepreneur';
    }

    if (sessionTextEditingController.text.contains('boss'))
    {
      sessionObject.category1 = 'work and career';
      sessionObject.category2 = 'business and entrepreneur';
    }

    if (sessionTextEditingController.text.contains('madam'))
    {
      sessionObject.category1 = 'work and career';
      sessionObject.category2 = 'business and entrepreneur';
    }


    if (sessionTextEditingController.text.contains('hate'))
    {
      sessionObject.category1 = 'hate and abuse';
      sessionObject.category2 = 'depression and anxiety';
      sessionObject.category3 = 'sad and depressed';
    }

    if (sessionTextEditingController.text.contains('abuse'))
    {
      sessionObject.category1 = 'hate and abuse';
      sessionObject.category2 = 'depression and anxiety';
      sessionObject.category3 = 'sad and depressed';
    }

    if (sessionTextEditingController.text.contains('pain'))
    {
      sessionObject.category1 = 'hate and abuse';
      sessionObject.category2 = 'depression and anxiety';
      sessionObject.category3 = 'sad and depressed';
    }

    if (sessionTextEditingController.text.contains('trauma'))
    {
      sessionObject.category1 = 'hate and abuse';
      sessionObject.category2 = 'depression and anxiety';
      sessionObject.category3 = 'sad and depressed';
    }

    if (sessionTextEditingController.text.contains('slap'))
    {
      sessionObject.category1 = 'hate and abuse';
      sessionObject.category2 = 'depression and anxiety';
      sessionObject.category3 = 'sad and depressed';
    }

    if (sessionTextEditingController.text.contains('punch'))
    {
      sessionObject.category1 = 'hate and abuse';
      sessionObject.category2 = 'depression and anxiety';
      sessionObject.category3 = 'sad and depressed';
    }

    if (sessionTextEditingController.text.contains('friends'))
    {
      sessionObject.category1 = 'friends and fun';
      sessionObject.category2 = 'life and living';
    }

    if (sessionTextEditingController.text.contains('fun'))
    {
      sessionObject.category1 = 'friends and fun';
      sessionObject.category2 = 'life and living';
    }

    if (sessionTextEditingController.text.contains('depression'))
    {
      sessionObject.category1 = 'depression and anxiety';
      sessionObject.category2 = 'sad and depressed';
      sessionObject.category3 = 'single and lonely';
    }

    if (sessionTextEditingController.text.contains('anxiety'))
    {
      sessionObject.category1 = 'depression and anxiety';
      sessionObject.category2 = 'sad and depressed';
      sessionObject.category3 = 'single and lonely';
    }

    if (sessionTextEditingController.text.contains('help'))
    {
      sessionObject.category1 = 'help and charity';
      sessionObject.category2 = 'life and living';
    }

    if (sessionTextEditingController.text.contains('charity'))
    {
      sessionObject.category1 = 'help and charity';
      sessionObject.category2 = 'life and living';
    }

    if (sessionTextEditingController.text.contains('sick'))
    {
      sessionObject.category1 = 'health and fitness';
      sessionObject.category2 = 'life and living';
      sessionObject.category3 = 'food and drink';
    }

    if (sessionTextEditingController.text.contains('health'))
    {
      sessionObject.category1 = 'health and fitness';
      sessionObject.category2 = 'life and living';
      sessionObject.category3 = 'food and drink';
    }

    if (sessionTextEditingController.text.contains('fitness'))
    {
      sessionObject.category1 = 'health and fitness';
      sessionObject.category2 = 'life and living';
      sessionObject.category3 = 'food and drink';
    }

    if (sessionTextEditingController.text.contains('husband'))
    {
      sessionObject.category1 = 'husband and wife';
      sessionObject.category2 = 'marriage and family';
      sessionObject.category3 = 'life and living';
      sessionObject.category4 = 'birthdays and anniversary';
    }

    if (sessionTextEditingController.text.contains('wife'))
    {
      sessionObject.category1 = 'husband and wife';
      sessionObject.category2 = 'marriage and family';
      sessionObject.category3 = 'life and living';
      sessionObject.category4 = 'birthdays and anniversary';
    }

    if (sessionTextEditingController.text.contains('married'))
    {
      sessionObject.category1 = 'husband and wife';
      sessionObject.category2 = 'marriage and family';
      sessionObject.category3 = 'life and living';
      sessionObject.category4 = 'birthdays and anniversary';
    }

    if (sessionTextEditingController.text.contains('inlaw'))
    {
      sessionObject.category1 = 'husband and wife';
      sessionObject.category2 = 'marriage and family';
      sessionObject.category3 = 'life and living';
      sessionObject.category4 = 'birthdays and anniversary';
    }

    if (sessionTextEditingController.text.contains('boyfriend'))
    {
      sessionObject.category1 = 'love and relationship';
      sessionObject.category2 = 'sex and dating';
      sessionObject.category3 = 'birthdays and anniversary';
      sessionObject.category4 = 'boyfriend and girlfriend';
    }

    if (sessionTextEditingController.text.contains('girlfriend'))
    {
      sessionObject.category1 = 'love and relationship';
      sessionObject.category2 = 'sex and dating';
      sessionObject.category3 = 'birthdays and anniversary';
      sessionObject.category4 = 'boyfriend and girlfriend';
    }

    if (sessionTextEditingController.text.contains('bf'))
    {
      sessionObject.category1 = 'love and relationship';
      sessionObject.category2 = 'sex and dating';
      sessionObject.category3 = 'birthdays and anniversary';
      sessionObject.category4 = 'boyfriend and girlfriend';
    }

    if (sessionTextEditingController.text.contains('gf'))
    {
      sessionObject.category1 = 'love and relationship';
      sessionObject.category2 = 'sex and dating';
      sessionObject.category3 = 'birthdays and anniversary';
      sessionObject.category4 = 'boyfriend and girlfriend';
    }

    if (sessionTextEditingController.text.contains('food'))
    {
      sessionObject.category1 = 'food and drink';
      sessionObject.category2 = 'health and fitness';
      sessionObject.category3 = 'friends and fun';
    }

    if (sessionTextEditingController.text.contains('drink'))
    {
      sessionObject.category1 = 'food and drink';
      sessionObject.category2 = 'health and fitness';
      sessionObject.category3 = 'friends and fun';
    }

    if (sessionTextEditingController.text.contains('birthday'))
    {
      sessionObject.category1 = 'birthday and anniversary';
      sessionObject.category2 = 'love and relationship';
      sessionObject.category3 = 'marriage and family';
      sessionObject.category4 = 'friends and fun';
    }

    if (sessionTextEditingController.text.contains('anniversary'))
    {
      sessionObject.category1 = 'birthday and anniversary';
      sessionObject.category2 = 'love and relationship';
      sessionObject.category3 = 'marriage and family';
      sessionObject.category4 = 'friends and fun';
    }

    if (sessionTextEditingController.text.contains('pray'))
    {
      sessionObject.category1 = 'prayer and thanksgiving';
      sessionObject.category2 = 'life and living';
    }

    if (sessionTextEditingController.text.contains('God'))
    {
      sessionObject.category1 = 'prayer and thanksgiving';
      sessionObject.category2 = 'life and living';
    }

    if (sessionTextEditingController.text.contains('church'))
    {
      sessionObject.category1 = 'prayer and thanksgiving';
      sessionObject.category2 = 'life and living';
    }

    if (sessionTextEditingController.text.contains('prayer'))
    {
      sessionObject.category1 = 'prayer and thanksgiving';
      sessionObject.category2 = 'life and living';
    }

    if (sessionTextEditingController.text.contains('praises'))
    {
      sessionObject.category1 = 'prayer and thanksgiving';
      sessionObject.category2 = 'life and living';
    }

    if (sessionTextEditingController.text.contains('childhood'))
    {
      sessionObject.category1 = 'childhood and memory';
      sessionObject.category2 = 'life and living';
      sessionObject.category3 = 'marriage and family';
      sessionObject.category4 = 'parents and children';
    }

    if (sessionTextEditingController.text.contains('memory'))
    {
      sessionObject.category1 = 'childhood and memory';
      sessionObject.category2 = 'life and living';
      sessionObject.category3 = 'marriage and family';
      sessionObject.category4 = 'parents and children';
    }


    if (sessionTextEditingController.text.contains('old'))
    {
      sessionObject.category1 = 'childhood and memory';
      sessionObject.category2 = 'life and living';
      sessionObject.category3 = 'marriage and family';
      sessionObject.category4 = 'parents and children';
    }

    if (sessionTextEditingController.text.contains('parents'))
    {
      sessionObject.category1 = 'parents and children';
      sessionObject.category2 = 'marriage and family';
      sessionObject.category3 = 'husband and wife';
      sessionObject.category4 = 'childhood and memory';
    }

    if (sessionTextEditingController.text.contains('children'))
    {
      sessionObject.category1 = 'parents and children';
      sessionObject.category2 = 'marriage and family';
      sessionObject.category3 = 'husband and wife';
      sessionObject.category4 = 'childhood and memory';
    }

    if (sessionTextEditingController.text.contains('father'))
    {
      sessionObject.category1 = 'parents and children';
      sessionObject.category2 = 'marriage and family';
      sessionObject.category3 = 'husband and wife';
      sessionObject.category4 = 'childhood and memory';
    }

    if (sessionTextEditingController.text.contains('mother'))
    {
      sessionObject.category1 = 'parents and children';
      sessionObject.category2 = 'marriage and family';
      sessionObject.category3 = 'husband and wife';
      sessionObject.category4 = 'childhood and memory';
    }

    if (sessionTextEditingController.text.contains('dad'))
    {
      sessionObject.category1 = 'parents and children';
      sessionObject.category2 = 'marriage and family';
      sessionObject.category3 = 'husband and wife';
      sessionObject.category4 = 'childhood and memory';
    }

    if (sessionTextEditingController.text.contains('mom'))
    {
      sessionObject.category1 = 'parents and children';
      sessionObject.category2 = 'marriage and family';
      sessionObject.category3 = 'husband and wife';
      sessionObject.category4 = 'childhood and memory';
    }

    if (sessionTextEditingController.text.contains('stepmom'))
    {
      sessionObject.category1 = 'parents and children';
      sessionObject.category2 = 'marriage and family';
      sessionObject.category3 = 'husband and wife';
      sessionObject.category4 = 'childhood and memory';
    }

    if (sessionTextEditingController.text.contains('stepdad'))
    {
      sessionObject.category1 = 'parents and children';
      sessionObject.category2 = 'marriage and family';
      sessionObject.category3 = 'husband and wife';
      sessionObject.category4 = 'childhood and memory';
    }

    if (sessionTextEditingController.text.contains('business'))
    {
      sessionObject.category1 = 'business and entrepreneur';
      sessionObject.category2 = 'work and career';
      sessionObject.category3 = 'school and education';
    }

    if (sessionTextEditingController.text.contains('entrepreneur'))
    {
      sessionObject.category1 = 'business and entrepreneur';
      sessionObject.category2 = 'work and career';
      sessionObject.category3 = 'school and education';
    }


    if (sessionTextEditingController.text.contains('startup'))
    {
      sessionObject.category1 = 'business and entrepreneur';
      sessionObject.category2 = 'work and career';
      sessionObject.category3 = 'school and education';
    }


    if (sessionTextEditingController.text.contains('sales'))
    {
      sessionObject.category1 = 'business and entrepreneur';
      sessionObject.category2 = 'work and career';
      sessionObject.category3 = 'school and education';
    }

    if (sessionTextEditingController.text.contains('art'))
    {
      sessionObject.category1 = 'arts and photography';
      sessionObject.category2 = 'work and career';
      sessionObject.category3 = 'business and entrepreneur';
    }

    if (sessionTextEditingController.text.contains('photography'))
    {
      sessionObject.category1 = 'arts and photography';
      sessionObject.category2 = 'work and career';
      sessionObject.category3 = 'business and entrepreneur';
    }

    if (sessionTextEditingController.text.contains('studio'))
    {
      sessionObject.category1 = 'arts and photography';
      sessionObject.category2 = 'work and career';
      sessionObject.category3 = 'business and entrepreneur';
    }

    if (sessionTextEditingController.text.contains('camera'))
    {
      sessionObject.category1 = 'arts and photography';
      sessionObject.category2 = 'work and career';
      sessionObject.category3 = 'business and entrepreneur';
    }

    if (sessionTextEditingController.text.contains('music'))
    {
      sessionObject.category1 = 'music and videos';
      sessionObject.category2 = 'arts and photography';
      sessionObject.category3 = 'work and career';
      sessionObject.category4 = 'comedy and entertainment';
    }

    if (sessionTextEditingController.text.contains('video'))
    {
      sessionObject.category1 = 'music and videos';
      sessionObject.category2 = 'arts and photography';
      sessionObject.category3 = 'work and career';
      sessionObject.category4 = 'comedy and entertainment';
    }

    if (sessionTextEditingController.text.contains('riddles'))
    {
      sessionObject.category1 = 'riddles and jokes';
      sessionObject.category2 = 'friends Aad fun';
      sessionObject.category3 = 'comedy and entertainment';
    }

    if (sessionTextEditingController.text.contains('joke'))
    {
      sessionObject.category1 = 'riddles and jokes';
      sessionObject.category2 = 'friends Aad fun';
      sessionObject.category3 = 'comedy and entertainment';
    }

    if (sessionTextEditingController.text.contains('comedy'))
    {
      sessionObject.category1 = 'riddles and jokes';
      sessionObject.category2 = 'friends Aad fun';
      sessionObject.category3 = 'comedy and entertainment';
    }

    if (sessionTextEditingController.text.contains('laugh'))
    {
      sessionObject.category1 = 'riddles and jokes';
      sessionObject.category2 = 'friends Aad fun';
      sessionObject.category3 = 'comedy and entertainment';
    }

    if (sessionTextEditingController.text.contains('television'))
    {
      sessionObject.category1 = 'television and movies';
      sessionObject.category2 = 'music Aad videos';
      sessionObject.category3 = 'arts and photography';
      sessionObject.category4 = 'comedy and entertainment';
    }

    if (sessionTextEditingController.text.contains('movie'))
    {
      sessionObject.category1 = 'television and movies';
      sessionObject.category2 = 'music Aad videos';
      sessionObject.category3 = 'arts and photography';
      sessionObject.category4 = 'comedy and entertainment';
    }

    if (sessionTextEditingController.text.contains('cinema'))
    {
      sessionObject.category1 = 'television and movies';
      sessionObject.category2 = 'music Aad videos';
      sessionObject.category3 = 'arts and photography';
      sessionObject.category4 = 'comedy and entertainment';
    }

    if (sessionTextEditingController.text.contains('puzzle'))
    {
      sessionObject.category1 = 'puzzles and games';
      sessionObject.category2 = 'riddles Aad jokes';
      sessionObject.category3 = 'comedy and entertainment';
    }

    if (sessionTextEditingController.text.contains('games'))
    {
      sessionObject.category1 = 'puzzles and games';
      sessionObject.category2 = 'riddles Aad jokes';
      sessionObject.category3 = 'comedy and entertainment';
    }

    if (sessionTextEditingController.text.contains('life'))
    {
      sessionObject.category1 = 'life and living';
      sessionObject.category2 = 'happy and blessed';
      sessionObject.category3 = 'childhood and memory';
      sessionObject.category4 = 'work and career';
    }

    if (sessionTextEditingController.text.contains('living'))
    {
      sessionObject.category1 = 'life and living';
      sessionObject.category2 = 'happy and blessed';
      sessionObject.category3 = 'childhood and memory';
      sessionObject.category4 = 'work and career';
    }

    if (sessionTextEditingController.text.contains('house'))
    {
      sessionObject.category1 = 'life and living';
      sessionObject.category2 = 'happy and blessed';
      sessionObject.category3 = 'childhood and memory';
      sessionObject.category4 = 'work and career';
    }


    if (sessionTextEditingController.text.contains('bedroom'))
    {
      sessionObject.category1 = 'life and living';
      sessionObject.category2 = 'happy and blessed';
      sessionObject.category3 = 'childhood and memory';
      sessionObject.category4 = 'work and career';
    }

    if (sessionTextEditingController.text.contains('single'))
    {
      sessionObject.category1 = 'single and lonely';
      sessionObject.category2 = 'sad Aad depressed';
      sessionObject.category3 = 'love and relationship';
    }

    if (sessionTextEditingController.text.contains('lonely'))
    {
      sessionObject.category1 = 'single and lonely';
      sessionObject.category2 = 'sad Aad depressed';
      sessionObject.category3 = 'love and relationship';
    }

    if (sessionTextEditingController.text.contains('alone'))
    {
      sessionObject.category1 = 'single and lonely';
      sessionObject.category2 = 'sad Aad depressed';
      sessionObject.category3 = 'love and relationship';
    }

    if (sessionTextEditingController.text.contains('mingle'))
    {
      sessionObject.category1 = 'single and lonely';
      sessionObject.category2 = 'sad Aad depressed';
      sessionObject.category3 = 'love and relationship';
    }

    if (sessionTextEditingController.text.contains('sad'))
    {
      sessionObject.category1 = 'sad and depressed';
      sessionObject.category2 = 'single and lonely';
      sessionObject.category3 = 'life and living';
    }

    if (sessionTextEditingController.text.contains('depressed'))
    {
      sessionObject.category1 = 'sad and depressed';
      sessionObject.category2 = 'single and lonely';
      sessionObject.category3 = 'life and living';
    }


    if (sessionTextEditingController.text.contains('suicide'))
    {
      sessionObject.category1 = 'sad and depressed';
      sessionObject.category2 = 'single and lonely';
      sessionObject.category3 = 'life and living';
    }


    if (sessionTextEditingController.text.contains('die'))
    {
      sessionObject.category1 = 'sad and depressed';
      sessionObject.category2 = 'single and lonely';
      sessionObject.category3 = 'life and living';
    }

    if (sessionTextEditingController.text.contains('brother'))
    {
      sessionObject.category1 = 'brothers and sisters';
      sessionObject.category2 = 'marriage and family';
      sessionObject.category3 = 'husband and wife';
    }

    if (sessionTextEditingController.text.contains('sister'))
    {
      sessionObject.category1 = 'brothers and sisters';
      sessionObject.category2 = 'marriage and family';
      sessionObject.category3 = 'husband and wife';
    }

    if (sessionTextEditingController.text.contains('my bro'))
    {
      sessionObject.category1 = 'brothers and sisters';
      sessionObject.category2 = 'marriage and family';
      sessionObject.category3 = 'husband and wife';
    }

    if (sessionTextEditingController.text.contains('my sis'))
    {
      sessionObject.category1 = 'brothers and sisters';
      sessionObject.category2 = 'marriage and family';
      sessionObject.category3 = 'husband and wife';
    }

    if (sessionTextEditingController.text.contains('comedy'))
    {
      sessionObject.category1 = 'comedy and entertainment';
      sessionObject.category2 = 'music Aad videos';
      sessionObject.category3 = 'riddles and jokes';
    }

    if (sessionTextEditingController.text.contains('entertainment'))
    {
      sessionObject.category1 = 'comedy and entertainment';
      sessionObject.category2 = 'music Aad videos';
      sessionObject.category3 = 'riddles and jokes';
    }

    if (sessionTextEditingController.text.contains('happy'))
    {
      sessionObject.category1 = 'happy and blessed';
      sessionObject.category2 = 'life Aad living';
      sessionObject.category3 = 'love and relationship';
      sessionObject.category4 = 'marriage and family';
    }

    if (sessionTextEditingController.text.contains('blessed'))
    {
      sessionObject.category1 = 'happy and blessed';
      sessionObject.category2 = 'life Aad living';
      sessionObject.category3 = 'love and relationship';
      sessionObject.category4 = 'marriage and family';
    }

    if (sessionTextEditingController.text.contains('excited'))
    {
      sessionObject.category1 = 'happy and blessed';
      sessionObject.category2 = 'life Aad living';
      sessionObject.category3 = 'love and relationship';
      sessionObject.category4 = 'marriage and family';
    }

    if (sessionTextEditingController.text.contains('grateful'))
    {
      sessionObject.category1 = 'happy and blessed';
      sessionObject.category2 = 'life Aad living';
      sessionObject.category3 = 'love and relationship';
      sessionObject.category4 = 'marriage and family';
    }

    if (sessionTextEditingController.text.contains('joyful'))
    {
      sessionObject.category1 = 'happy and blessed';
      sessionObject.category2 = 'life Aad living';
      sessionObject.category3 = 'love and relationship';
      sessionObject.category4 = 'marriage and family';
    }

    if (sessionTextEditingController.text.contains('dance'))
    {
      sessionObject.category1 = 'happy and blessed';
      sessionObject.category2 = 'life Aad living';
      sessionObject.category3 = 'love and relationship';
      sessionObject.category4 = 'marriage and family';
    }

    if (sessionTextEditingController.text.contains('dancing'))
    {
      sessionObject.category1 = 'happy and blessed';
      sessionObject.category2 = 'life Aad living';
      sessionObject.category3 = 'love and relationship';
      sessionObject.category4 = 'marriage and family';
    }

    if (sessionTextEditingController.text.contains('beach'))
    {
      sessionObject.category1 = 'happy and blessed';
      sessionObject.category2 = 'life Aad living';
      sessionObject.category3 = 'love and relationship';
      sessionObject.category4 = 'marriage and family';
    }

    sessionObject.userAvatarUrl = userModel.avatarUrl;
    sessionObject.userNickname = userModel.nickname;
    sessionObject.title = sessionTitleController.text;
    sessionObject.private = c.acceptReplies.value;
    sessionObject.repliesEnabled = c.acceptReplies.value;
    sessionObject.message = sessionTextEditingController.text;
    sessionObject.colorHex =
        Constant.DIARY_COLORS_HEXCODE[c.selectedBackgroundColor.value];
    sessionObject.sessionId = uuid.v1();
    sessionObject.userId = userModel.userId;
    sessionObject.moodId =
        Constant.USER_SESSION_MOODS.indexOf(c.sessionMood.value);
    sessionObject.location = _location;
    sessionObject.timeLastActivity = Timestamp.now();

    bool isSuccessfull =
        await _firebaseServices.createSession(session: sessionObject);

    Hive.box("draft").clear();

    categorize(sessionObject);

    isOriginalSession(sessionTextEditingController.text);

    ascertainCurrentLoveCount();

    Future.delayed(Duration(seconds: 4), () {
      _showInterstitialAd();
    });

    _firebaseServices.subscribeToYourSession(userModel.nickname.toString(), sessionObject);

    navigateToNewSession(await _firebaseServices.getSingleSession(
        sessionId: sessionObject.sessionId));
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
