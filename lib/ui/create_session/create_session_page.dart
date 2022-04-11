import 'dart:io';
import 'dart:math';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/services/user_model.dart';
import 'package:dear_claire/ui/create_session/session_model.dart';
import 'package:dear_claire/ui/create_session/sound/play_sound_widget.dart';
import 'package:dear_claire/ui/create_session/view_singlesession_widget.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:emoji_chooser/emoji_chooser.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:dear_claire/widgets/toast.dart';
import 'package:hive/hive.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'create_session_controller.dart';
import 'sound/sound_widget.dart';

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

  //object for hive database
  late final box;

//obtain user id, nickname and avatarUrl linked to this user
  var currentUser = FirebaseAuth.instance.currentUser;

  UserModel userModel = UserModel();

//used for generating random id for each session
  var uuid = Uuid();

  //input controller to access session message from user
  final sessionTextEditingController = TextEditingController();
  late FocusNode sessionTextFocusNode;

  ///this function is trigggered when user clicks on any emoji
  appendEmojiToText(EmojiData emoji) {
    var newText = sessionTextEditingController.text + emoji.char;
    sessionTextEditingController.text = newText;
  }

//initialize the audio record file that stores user audio record. null by default
  File? recordFile;

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
    randomizeBackgroundColor();
    initializeDatabaseObject();
    sessionTextFocusNode = FocusNode();
    _createInterstitialAd();
  }

  void initializeDatabaseObject() async {
    box = await Hive.openBox('draft');
    String text = box.get("text");
    print("text is:$text");
    if (text.isNotEmpty) {
      sessionTextEditingController.text = text;
    }
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    sessionTextFocusNode.dispose();
    sessionTextEditingController.dispose();
    sessionTitleController.dispose();
    super.dispose();
    _interstitialAd?.dispose();
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

  /// Increase current love count when user creates new session or comment.

  Future<void> incrementCurrentLoveCount() async {
    FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).set(
      {
        'currentLoveCount': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );
    logger.d('Successfully saved new nickname');
    print('Session Count is: $FieldValue');
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
                      Text(
                        "Dear Claire collects location data to enable you add or filter diary sessions based on location.",
                        style: TextStyle(
                            fontSize: 12,
                            color: Pallet.colorSecondary,
                            fontStyle: FontStyle.italic),
                      )
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
                          style: TextStyle(color: Pallet.colorSecondary))
                      : Text('Save',
                          style: TextStyle(color: Pallet.colorSecondary)),
                ),
                onPressed: () {
                  if (sessionTextEditingController.text.isNotEmpty &&
                      sessionTitleController.text.isNotEmpty) {
                    Navigator.of(context).pop();
                    createSession();
                    showToast(AppString.started_new_session);
                    incrementSessionCount();
                    incrementTotalLoveCount();
                    Future.delayed(Duration(seconds: 2), () {
                      _showInterstitialAd();
                    });
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
    // onTap: () => sessionTextFocusNode.requestFocus(),
    return Obx(
      () => SafeArea(
        child: Scaffold(
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
                          RotateImage(70, 70),
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
              : Container(
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
                            onChanged: (value) {
                              if (value != null) {
                                box.put("text", value);
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
                      recordFile != null
                          ? _recordFileWidget()
                          : SizedBox.shrink(),
                      Align(
                          alignment: Alignment.bottomCenter,
                          child: _imagesGridView()),
                      SizedBox(
                        height: 30.h,
                      )
                    ],
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
                      height: 20.h,
                      width: 25.w,
                      child: IconButton(
                        alignment: Alignment.topCenter,
                        icon: Icon(Icons.camera_enhance_rounded,
                            size: 35, color: Pallet.colorWhite),
                        onPressed: loadAssets,
                      )),
                  SizedBox(
                    width: 30.w,
                    height: 40,
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
                    width: 15.w,
                  ),
                  Container(
                      height: 20.h,
                      width: 25.w,
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
      width: 60.w,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
              child: IconButton(
                  icon: Icon(Icons.play_circle_fill_outlined,
                      color: Colors.white, size: 40.r),
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: false, // user must tap button!
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: PlaySoundWidget(
                            filePath: recordFile?.path,
                          ),
                        );
                      },
                    );
                  })),
          Positioned(
              right: -5,
              top: -9,
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
        maxImages: 2,
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
    return Column(
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
            .toList());
  }

  Widget _imagesGridView() {
    return Container(
      width: 500,
      alignment: Alignment.center,
      padding: EdgeInsets.all(20),
      child: GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        children: List.generate(c.images.length, (index) {
          Asset asset = c.images[index];
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              AssetThumb(
                asset: asset,
                width: 300,
                height: 400,
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

  createSession() async {
    setState(() {
      isLoading = true;
    });

    userModel = await _firebaseServices.getUserInfo();
    CreateSessionModel sessionObject = CreateSessionModel();
    if (recordFile != null) {
      sessionObject.audioUrl = await _firebaseServices.uploadSound(recordFile!);
    }

    if (imageList != null) {
      List<String> imageDownloadUrls = <String>[];
      for (var image in imageList) {
        imageDownloadUrls.add(await _firebaseServices.uploadImage(image));
      }
      sessionObject.imageUrls = imageDownloadUrls;
    }

    /// Adding a category tag to every session created.

    if (sessionTextEditingController.text.contains('love') &
        sessionTextEditingController.text.contains('relationship')) {
      sessionObject.category1 = 'love and relationship';
      sessionObject.category2 = 'sex and dating';
      sessionObject.category3 = 'boyfriend and girlfriend';
      sessionObject.category4 = 'birthdays and anniversary';
    }

    if (sessionTextEditingController.text.contains('marriage') &
        sessionTextEditingController.text.contains('family')) {
      sessionObject.category1 = 'marriage and family';
      sessionObject.category2 = 'husband and wife';
      sessionObject.category3 = 'birthdays and anniversary';
    }

    if (sessionTextEditingController.text.contains('sex') &
        sessionTextEditingController.text.contains('dating')) {
      sessionObject.category1 = 'sex and dating';
      sessionObject.category2 = 'love and relationship';
      sessionObject.category3 = 'boyfriend and girlfriend';
    }

    if (sessionTextEditingController.text.contains('school') &
        sessionTextEditingController.text.contains('education')) {
      sessionObject.category1 = 'school and education';
      sessionObject.category2 = 'work and career';
    }

    if (sessionTextEditingController.text.contains('work') &
        sessionTextEditingController.text.contains('career')) {
      sessionObject.category1 = 'work and career';
      sessionObject.category2 = 'business and entrepreneur';
    }

    if (sessionTextEditingController.text.contains('hate') &
        sessionTextEditingController.text.contains('abuse')) {
      sessionObject.category1 = 'hate and abuse';
      sessionObject.category2 = 'depression and anxiety';
      sessionObject.category3 = 'sad and depressed';
    }

    if (sessionTextEditingController.text.contains('friends') &
        sessionTextEditingController.text.contains('fun')) {
      sessionObject.category1 = 'friends and fun';
      sessionObject.category2 = 'life and living';
    }

    if (sessionTextEditingController.text.contains('depression') &
        sessionTextEditingController.text.contains('anxiety')) {
      sessionObject.category1 = 'depression and anxiety';
      sessionObject.category2 = 'sad and depressed';
      sessionObject.category3 = 'single and lonely';
    }

    if (sessionTextEditingController.text.contains('help') &
        sessionTextEditingController.text.contains('charity')) {
      sessionObject.category1 = 'help and charity';
      sessionObject.category2 = 'life and living';
    }

    if (sessionTextEditingController.text.contains('sick') &
        sessionTextEditingController.text.contains('health') &
        sessionTextEditingController.text.contains('fitness')) {
      sessionObject.category1 = 'health and fitness';
      sessionObject.category2 = 'life and living';
      sessionObject.category3 = 'food and drink';
    }

    if (sessionTextEditingController.text.contains('husband') &
        sessionTextEditingController.text.contains('wife')) {
      sessionObject.category1 = 'husband and wife';
      sessionObject.category2 = 'marriage and family';
      sessionObject.category3 = 'life and living';
      sessionObject.category4 = 'birthdays and anniversary';
    }

    if (sessionTextEditingController.text.contains('boyfriend') &
        sessionTextEditingController.text.contains('girlfriend')) {
      sessionObject.category1 = 'love and relationship';
      sessionObject.category2 = 'sex and dating';
      sessionObject.category3 = 'birthdays and anniversary';
      sessionObject.category4 = 'boyfriend and girlfriend';
    }

    if (sessionTextEditingController.text.contains('food') &
        sessionTextEditingController.text.contains('drink')) {
      sessionObject.category1 = 'food and drink';
      sessionObject.category2 = 'health and fitness';
      sessionObject.category3 = 'friends and fun';
    }

    if (sessionTextEditingController.text.contains('birthday') &
        sessionTextEditingController.text.contains('anniversary')) {
      sessionObject.category1 = 'birthday and anniversary';
      sessionObject.category2 = 'love and relationship';
      sessionObject.category3 = 'marriage and family';
      sessionObject.category4 = 'friends and fun';
    }

    if (sessionTextEditingController.text.contains('pray') &
        sessionTextEditingController.text.contains('God')) {
      sessionObject.category1 = 'prayer and thanksgiving';
      sessionObject.category2 = 'life and living';
    }

    if (sessionTextEditingController.text.contains('childhood') &
        sessionTextEditingController.text.contains('memory')) {
      sessionObject.category1 = 'childhood and memory';
      sessionObject.category2 = 'life and living';
      sessionObject.category3 = 'marriage and family';
      sessionObject.category4 = 'parents and children';
    }

    if (sessionTextEditingController.text.contains('parents') &
        sessionTextEditingController.text.contains('children')) {
      sessionObject.category1 = 'parents and children';
      sessionObject.category2 = 'marriage and family';
      sessionObject.category3 = 'husband and wife';
      sessionObject.category4 = 'childhood and memory';
    }

    if (sessionTextEditingController.text.contains('business') &
        sessionTextEditingController.text.contains('entrepreneur')) {
      sessionObject.category1 = 'business and entrepreneur';
      sessionObject.category2 = 'work and career';
      sessionObject.category3 = 'school and education';
    }

    if (sessionTextEditingController.text.contains('art') &
        sessionTextEditingController.text.contains('photography')) {
      sessionObject.category1 = 'arts and photography';
      sessionObject.category2 = 'work and career';
      sessionObject.category3 = 'business and entrepreneur';
    }

    if (sessionTextEditingController.text.contains('music') &
        sessionTextEditingController.text.contains('video')) {
      sessionObject.category1 = 'music and videos';
      sessionObject.category2 = 'arts and photography';
      sessionObject.category3 = 'work and career';
      sessionObject.category4 = 'comedy and entertainment';
    }

    if (sessionTextEditingController.text.contains('riddles') &
        sessionTextEditingController.text.contains('jokes')) {
      sessionObject.category1 = 'riddles and jokes';
      sessionObject.category2 = 'friends Aad fun';
      sessionObject.category3 = 'comedy and entertainment';
    }

    if (sessionTextEditingController.text.contains('television') &
        sessionTextEditingController.text.contains('movie')) {
      sessionObject.category1 = 'television and movies';
      sessionObject.category2 = 'music Aad videos';
      sessionObject.category3 = 'arts and photography';
      sessionObject.category4 = 'comedy and entertainment';
    }

    if (sessionTextEditingController.text.contains('puzzle') &
        sessionTextEditingController.text.contains('game')) {
      sessionObject.category1 = 'puzzles and games';
      sessionObject.category2 = 'riddles Aad jokes';
      sessionObject.category3 = 'comedy and entertainment';
    }

    if (sessionTextEditingController.text.contains('life') &
        sessionTextEditingController.text.contains('living')) {
      sessionObject.category1 = 'life and living';
      sessionObject.category2 = 'happy and blessed';
      sessionObject.category3 = 'childhood and memory';
      sessionObject.category4 = 'work and career';
    }

    if (sessionTextEditingController.text.contains('single') &
        sessionTextEditingController.text.contains('lonely')) {
      sessionObject.category1 = 'single and lonely';
      sessionObject.category2 = 'sad Aad depressed';
      sessionObject.category3 = 'love and relationship';
    }

    if (sessionTextEditingController.text.contains('sad') &
        sessionTextEditingController.text.contains('depressed')) {
      sessionObject.category1 = 'sad and depressed';
      sessionObject.category2 = 'single and lonely';
      sessionObject.category3 = 'life and living';
    }

    if (sessionTextEditingController.text.contains('brother') &
        sessionTextEditingController.text.contains('sister')) {
      sessionObject.category1 = 'brothers and sisters';
      sessionObject.category2 = 'marriage and family';
      sessionObject.category3 = 'husband and wife';
    }

    if (sessionTextEditingController.text.contains('comedy') &
        sessionTextEditingController.text.contains('entertainment')) {
      sessionObject.category1 = 'comedy and entertainment';
      sessionObject.category2 = 'music Aad videos';
      sessionObject.category3 = 'riddles and jokes';
    }

    if (sessionTextEditingController.text.contains('happy') &
        sessionTextEditingController.text.contains('blessed')) {
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

    navigateToNewSession(await _firebaseServices.getSingleSession(
        sessionId: sessionObject.sessionId));
  }

  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;
  CreateSessionModel sessionObject = CreateSessionModel();

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
