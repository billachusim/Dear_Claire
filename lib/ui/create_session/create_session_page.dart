import 'dart:io';
import 'dart:math';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:dear_claire/Admob/ad_state.dart';
import 'package:dear_claire/data/models/session_model.dart';
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
import 'package:flutter/material.dart';
import 'package:dear_claire/widgets/toast.dart';
import 'package:hive/hive.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'create_session_controller.dart';
import 'sound/sound_widget.dart';

class CreateSessionPage extends StatefulWidget {
  const CreateSessionPage({super.key});

  @override
  _CreateSessionPageState createState() => _CreateSessionPageState();
}

const int maxFailedLoadAttempts = 3;

class _CreateSessionPageState extends State<CreateSessionPage> {
  final TextEditingController _sessionTitleController = TextEditingController();
  final FirebaseServices _firebaseServices = FirebaseServices();

  late final Box _box;

  final User? _currentUser = FirebaseAuth.instance.currentUser;
  UserModel _userModel = UserModel();

  final Uuid _uuid = const Uuid();

  final _sessionTextEditingController = TextEditingController();
  late FocusNode _sessionTextFocusNode;

  void _appendEmojiToText(EmojiData emoji) {
    final newText = _sessionTextEditingController.text + emoji.char;
    _sessionTextEditingController.text = newText;
  }

  File? _recordFile;
  final List<XFile> _imageList = <XFile>[];

  bool _isLoading = false;
  String? _location = '';

  void _randomizeBackgroundColor() {
    final random = Random();
    final randomNumber = random.nextInt(Constant.DIARY_COLORS.length);
    context.read<CreateSessionController>().selectedBackgroundColor = randomNumber;
  }

  @override
  void initState() {
    super.initState();
    _randomizeBackgroundColor();
    _initializeDatabaseObject();
    _sessionTextFocusNode = FocusNode();
    _createInterstitialAd();
  }

  void _initializeDatabaseObject() async {
    _box = await Hive.openBox('draft');
    final text = _box.get("text");
    if (text != null && text.isNotEmpty) {
      _sessionTextEditingController.text = text;
    }
  }

  @override
  void dispose() {
    _sessionTextFocusNode.dispose();
    _sessionTextEditingController.dispose();
    _sessionTitleController.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  Future<void> _showCardDialog() async {
    final createSessionController = context.read<CreateSessionController>();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
          title: const Text('Enter Title', textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _sessionTitleController,
                    decoration: const InputDecoration(
                      hintText: 'What\'s this session about?     ️   💌',
                    ),
                  ),
                  Consumer<CreateSessionController>(
                    builder: (context, controller, child) {
                      return DropdownButton(
                        borderRadius: BorderRadius.circular(30.0),
                        isExpanded: true,
                        value: controller.sessionMood,
                        icon: const Icon(Icons.arrow_circle_down_rounded, color: Colors.pink),
                        items: Constant.USER_SESSION_MOODS.map((String items) {
                          return DropdownMenuItem(value: items, child: Text(items));
                        }).toList(),
                        onChanged: (val) => controller.changeMood(val.toString()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.lock),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          "Do you want other users to reply and follow this diary session?",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Consumer<CreateSessionController>(
                        builder: (context, controller, child) {
                          return Switch(
                            value: controller.acceptReplies,
                            onChanged: (value) => controller.acceptReplies = value,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.lock),
                      const SizedBox(width: 10),
                      const Flexible(
                        child: Text(
                          "Do you want Claire to reply and follow this diary session?",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Consumer<CreateSessionController>(
                        builder: (context, controller, child) {
                          return Switch(
                            value: controller.followClaire,
                            onChanged: (value) => controller.followClaire = value,
                            activeTrackColor: Colors.purpleAccent,
                            activeColor: Pallet.colorSecondary,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      const Icon(Icons.location_on_sharp),
                      const SizedBox(width: 9),
                      const Flexible(
                        child: Text(
                          "Do you want to tag your location?",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Consumer<CreateSessionController>(
                        builder: (context, controller, child) {
                          return Switch(
                            value: controller.location,
                            onChanged: (value) async {
                              controller.location = value;
                              if (value) {
                                await _firebaseServices.determinePosition();
                                _location = await _firebaseServices.getUsersLocation();
                                setState(() {});
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Consumer<CreateSessionController>(
                builder: (context, controller, child) {
                  return Text(
                    controller.acceptReplies ? "Share and Save" : 'Save',
                    style: const TextStyle(color: Pallet.colorSecondary),
                  );
                },
              ),
              onPressed: () {
                if (_sessionTextEditingController.text.isNotEmpty && _sessionTitleController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  _createSession();
                  showToast(AppString.started_new_session);
                  Future.delayed(const Duration(seconds: 1), () {
                    _showInterstitialAd();
                  });
                } else {
                  _interstitialAd?.dispose();
                  showToast(AppString.new_session_error);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final createSessionController = context.watch<CreateSessionController>();
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Constant.DIARY_COLORS[createSessionController.selectedBackgroundColor],
        body: _isLoading
            ? Center(
                child: SizedBox(
                  height: 200,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      RotateImage(70, 70),
                      SizedBox(height: 10),
                      Text(
                        "Please Wait",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SizedBox(
                height: screenHeight,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          child: AutoSizeTextField(
                            style: Constant.DIARY_FONT_STYLES[createSessionController.selectedFontIndex],
                            maxLines: null,
                            minLines: 1,
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                _box.put("text", value);
                              }
                            },
                            scrollPadding: const EdgeInsets.all(20.0),
                            controller: _sessionTextEditingController,
                            focusNode: _sessionTextFocusNode,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(10),
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              border: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              hintText: "Start your text or voice note with Dear Claire",
                              hintStyle: TextStyle(color: Pallet.colorWhite, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                      if (_recordFile != null) _recordFileWidget(),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _imagesGridView(),
                      ),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
        bottomSheet: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Constant.DIARY_COLORS[createSessionController.selectedBackgroundColor],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: 20,
                width: 25,
                child: IconButton(
                  alignment: Alignment.topCenter,
                  icon: const Icon(Icons.camera_enhance_rounded, size: 35, color: Pallet.colorWhite),
                  onPressed: _loadAssets,
                ),
              ),
              const SizedBox(width: 30, height: 40),
              SizedBox(
                height: 20,
                width: 25,
                child: IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined, color: Pallet.colorWhite),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext subcontext) {
                        return SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: EmojiChooser(
                              onSelected: (emoji) {
                                _appendEmojiToText(emoji);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                height: 20,
                width: 25,
                child: IconButton(
                  icon: const Icon(Icons.text_fields, color: Pallet.colorWhite),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Select Font'),
                          content: _showFontSelectionDialog(context),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                height: 20,
                width: 25,
                child: IconButton(
                  icon: const Icon(Icons.color_lens_rounded, color: Pallet.colorWhite),
                  onPressed: () => createSessionController.changeColor(),
                ),
              ),
              const SizedBox(width: 15),
              SizedBox(
                height: 20,
                width: 25,
                child: IconButton(
                  icon: const Icon(Icons.mic_rounded, size: 35, color: Pallet.colorWhite),
                  onPressed: () async {
                    final data = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SoundRecorderWidget(
                          onRecordComplete: (recordFile) {},
                        ),
                      ),
                    );
                    if (data != null) {
                      _recordFile = data;
                      setState(() {});
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Pallet.colorSplashScreen,
          onPressed: () {
            _showCardDialog();
          },
          tooltip: 'Send or Save',
          child: const RotateImage(45, 45),
        ),
      ),
    );
  }

  Widget _recordFileWidget() {
    return SizedBox(
      height: 60,
      width: 60,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
            child: IconButton(
              icon: const Icon(Icons.play_circle_fill_outlined, color: Colors.white, size: 40),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: PlaySoundWidget(
                        filePath: _recordFile?.path,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Positioned(
            right: -5,
            top: -9,
            child: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 24),
              onPressed: () => setState(() {
                _recordFile = null;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadAssets() async {
    final imagePicker = ImagePicker();
    final pickedFiles = await imagePicker.pickMultiImage();

    if (!mounted) return;

    setState(() {
      context.read<CreateSessionController>().images = pickedFiles;
    });
  }

  Widget _showFontSelectionDialog(BuildContext context) {
    final createSessionController = context.read<CreateSessionController>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: Constant.ALTER_EGO_FONT_STYLES.map((e) => ListTile(
        title: e,
        onTap: () {
          final index = Constant.ALTER_EGO_FONT_STYLES.indexOf(e);
          createSessionController.selectFont(index);
          Navigator.pop(context);
        },
      )).toList(),
    );
  }

  Widget _imagesGridView() {
    final createSessionController = context.watch<CreateSessionController>();
    return Container(
      width: 500,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        children: List.generate(createSessionController.images.length, (index) {
          final image = createSessionController.images[index];
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.file(File(image.path)),
              Positioned(
                right: -2,
                top: -9,
                child: IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                  onPressed: () => setState(() {
                    createSessionController.images.removeAt(index);
                  }),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _createSession() async {
    final createSessionController = context.read<CreateSessionController>();
    setState(() {
      _isLoading = true;
    });

    _userModel = await _firebaseServices.getUserInfo();
    final sessionObject = CreateSessionModel();
    if (_recordFile != null) {
      sessionObject.audioUrl = await _firebaseServices.uploadSound(_recordFile!);
    }

    final imageDownloadUrls = <String>[];
    for (final image in _imageList) {
      imageDownloadUrls.add(await _firebaseServices.uploadImage(image));
    }
    sessionObject.imageUrls = imageDownloadUrls;

    if (_sessionTextEditingController.text.contains('love') && _sessionTextEditingController.text.contains('relationship')) {
      sessionObject.category1 = 'love and relationship';
      sessionObject.category2 = 'sex and dating';
      sessionObject.category3 = 'boyfriend and girlfriend';
      sessionObject.category4 = 'birthdays and anniversary';
    }

    sessionObject.userAvatarUrl = _userModel.avatarUrl;
    sessionObject.userNickname = _userModel.nickname;
    sessionObject.title = _sessionTitleController.text;
    sessionObject.private = createSessionController.acceptReplies;
    sessionObject.repliesEnabled = createSessionController.acceptReplies;
    sessionObject.message = _sessionTextEditingController.text;
    sessionObject.colorHex = Constant.DIARY_COLORS_HEXCODE[createSessionController.selectedBackgroundColor];
    sessionObject.sessionId = _uuid.v1();
    sessionObject.userId = _currentUser!.uid;
    sessionObject.moodId = Constant.USER_SESSION_MOODS.indexOf(createSessionController.sessionMood);
    sessionObject.location = _location;

    final isSuccessful = await _firebaseServices.createSession(session: sessionObject);

    _box.remove("draft");
    _categorize(sessionObject);

    final newSession = await _firebaseServices.getSingleSession(sessionId: sessionObject.sessionId);
    _navigateToNewSession(newSession);
  }

  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;

  void _createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: "ca-app-pub-3940256099942544/1033173712",
      request: const AdRequest(),
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

  void _navigateToNewSession(CreateSessionModel? session) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SessionPostDetailsScreen(
          sessionModel: session,
        ),
      ),
    );
  }

  void _categorize(CreateSessionModel createSessionModel) {
    if (createSessionModel.message!.contains('love') && createSessionModel.message!.contains('relationship')) {
      _firebaseServices.addToCategory(AppString.loveAndRelationship, createSessionModel);
    }
  }
}
