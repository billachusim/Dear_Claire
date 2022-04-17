import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/featured/model/session.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/utils/mood.dart';
import 'package:dear_claire/widgets/follow_button.dart';
import 'package:dear_claire/widgets/metoo_button.dart';
import 'package:dear_claire/widgets/share_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:full_screen_image/full_screen_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../utils/strings.dart';
import '../../create_session/sound/custom_play_sound_widget.dart';
import '../../create_session/sound/play_sound_widget.dart';
import '../../routes/page_router_animation.dart';
import '../../visited_user_ego_page/visited_user_ego_page.dart';

class PostDetailsWidget extends StatefulWidget {
  PostDetailsWidget({Key? key, required this.sessionId}) : super(key: key);
  String? sessionId;

  @override
  _PostDetailsWidgetState createState() => _PostDetailsWidgetState();
}

class _PostDetailsWidgetState extends State<PostDetailsWidget> {
  final screenshotController = ScreenshotController();

  late String visitedUsersID;
  late String visitedEgoName;

  //initialize the audio record file that stores user audio record. null by default
  String? recordFile;

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    return Screenshot(
      controller: screenshotController,
      child: Material(
        child: SafeArea(
          child: StreamBuilder(
              stream: firebaseServices.getSingleDocument(id: widget.sessionId),
              builder: (context,
                  AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snaps) {
                if (snaps.hasData) {
                  final _session = Session.fromJson(snaps.data!.data()!);
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6.0, vertical: 5),
                    decoration: BoxDecoration(
                        color: HexColor.fromHex(_session.colorHex!)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                visitedUsersID = _session.userId!;
                                visitedEgoName = _session.userNickname!;
                                String thisEgoName =
                                    _session.userNickname.toString();
                                String thisUser = _session.userId.toString();
                                PageRouter.gotoWidget(
                                    VisitedUserEgoProfilePage(
                                        visitedUsersID: thisUser,
                                        visitedEgoName: thisEgoName),
                                    context);
                                print("Visited User ID::: $thisEgoName");
                              },
                              child: CachedNetworkImage(
                                  width: 48,
                                  height: 48,
                                  imageUrl: _session.userAvatarUrl!,
                                  imageBuilder: (context, imageProvider) =>
                                      Container(
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: imageProvider,
                                            fit: BoxFit.fill,
                                          ),
                                        ),
                                      ),
                                  placeholder: (context, url) =>
                                      Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                      Image.asset(
                                        "assets/images/brown_boy_mask.png",
                                        width: 48,
                                        height: 48,
                                      ) //Icon(Icons.error),
                                  ),
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      visitedUsersID = _session.userId!;
                                      visitedEgoName = _session.userNickname!;
                                      String thisEgoName =
                                          _session.userNickname.toString();
                                      String thisUser =
                                          _session.userId.toString();
                                      PageRouter.gotoWidget(
                                          VisitedUserEgoProfilePage(
                                              visitedUsersID: thisUser,
                                              visitedEgoName: thisEgoName),
                                          context);
                                      print("Visited User ID::: $thisEgoName");
                                    },
                                    child: Text(_session.userNickname!,
                                        textAlign: TextAlign.start,
                                        maxLines: 1,
                                        style: GoogleFonts.lato(
                                            fontSize: 18.0,
                                            color: Pallet.colorWhite,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Text(timeConverter(_session.timeCreated!),
                                      textAlign: TextAlign.start,
                                      maxLines: 1,
                                      style: GoogleFonts.lato(
                                          fontSize: 13.0,
                                          color: Pallet.colorWhite,
                                          fontWeight: FontWeight.normal)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(Mood.getMood(_session.moodId).toString(),
                                      textAlign: TextAlign.end,
                                      maxLines: 1,
                                      style: GoogleFonts.lato(
                                          fontSize: 13.0,
                                          color: Pallet.colorWhite,
                                          fontWeight: FontWeight.w700)),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Text(_session.location ?? '',
                                      textAlign: TextAlign.end,
                                      maxLines: 1,
                                      style: GoogleFonts.lato(
                                          fontSize: 12.0,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w700)
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        SizedBox(
                          height: 14,
                        ),
                        Center(
                          child: Text(_session.title!,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              style: GoogleFonts.lato(
                                  fontSize: 20.0,
                                  color: Pallet.colorWhite,
                                  fontWeight: FontWeight.w700)),
                        ),
                        SizedBox(
                          height: 12,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _session.message!,
                                textAlign: TextAlign.left,
                                style: GoogleFonts.lato(
                                    fontSize: 17.0,
                                    color: Pallet.colorWhite,
                                    fontWeight: FontWeight.normal),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                _session.audioUrl!.isNotEmpty
                                    ? CustomPlaySoundWidget(filePath: _session.audioUrl)
                              : SizedBox.shrink(),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Row(
                              children: [
                                Visibility(
                                    visible: _session.imageUrls!.isNotEmpty,
                                    child: FullScreenWidget(
                                      child: CachedNetworkImage(
                                          height: 120,
                                          width: 120,
                                          imageUrl: _session.imageUrls!.isNotEmpty
                                              ? _session.imageUrls!.first
                                              : '',
                                          imageBuilder: (context, imageProvider) =>
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(25),
                                                  image: DecorationImage(
                                                    image: imageProvider,
                                                    fit: BoxFit.fill,
                                                  ),
                                                ),
                                              ),
                                          placeholder: (context, url) => Center(
                                              child: CircularProgressIndicator()),
                                          errorWidget: (context, url, error) =>
                                              Image.asset(
                                                "assets/images/brown_boy_mask.png",
                                                width: 48,
                                                height: 48,
                                              ) //Icon(Icons.error),
                                          ),
                                    )),
                                SizedBox(width: 5,),
                                Visibility(
                                    visible: _session.imageUrls!.isNotEmpty,
                                    child: FullScreenWidget(
                                      child: CachedNetworkImage(
                                          height: 120,
                                          width: 120,
                                          imageUrl: _session.imageUrls!.isNotEmpty
                                              ? _session.imageUrls!.last
                                              : '',
                                          imageBuilder: (context, imageProvider) =>
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(25),
                                                  image: DecorationImage(
                                                    image: imageProvider,
                                                    fit: BoxFit.fill,
                                                  ),
                                                ),
                                              ),
                                          placeholder: (context, url) => Center(
                                              child: CircularProgressIndicator()),
                                          errorWidget: (context, url, error) =>
                                              Image.asset(
                                                "assets/images/brown_boy_mask.png",
                                                width: 48,
                                                height: 48,
                                              ) //Icon(Icons.error),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            MetooButton(
                              cheers: _session.meToos!.length,
                              thanks: _session.meLove!.length,
                              sorry: _session.meHiFive!.length,
                              me2: _session.meFlower!.length,
                              onReactionChanged: (reaction, index) async {
                                if (await firebaseServices
                                    .isUserSignIn(context)) {
                                  final _userModel =
                                      await firebaseServices.getUserInfo();

                                  firebaseServices.addUsersReactionToASession(
                                      context, index,
                                      session: _session,
                                      sender: _userModel.nickname ?? '');
                                }
                              },
                              color: Pallet.colorWhite,
                            ),
                            new Spacer(),
                            FollowButton(
                              text: _session.followers!.contains(currentUser?.uid)
                                  ? 'Unfollow'
                                  : 'Follow',
                              onPressed: () async {
                                if (await firebaseServices.isUserSignIn(context))
                                  firebaseServices.followThisSession(context,
                                      session: _session);
                              },
                              count: _session.followers!.length,
                            ),

                            new Spacer(),

                            CupertinoButton(
                                padding: EdgeInsets.zero,
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 2.5, horizontal: 5),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Pallet.colorWhite,
                                      )),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.share_rounded,
                                        size: 15,
                                        color: Pallet.colorWhite,
                                      ),
                                      Text(
                                        'Share',
                                        style: GoogleFonts.lato(
                                            fontSize: 13.0,
                                            color: Pallet.colorWhite,
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                ),
                                onPressed: () async {
                                  final image =
                                      await screenshotController.capture();
                                  if (image == null) return;
                                  await saveImage(image);
                                  saveAndShare(image);
                                }
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                }
                return Container();
              }),
        ),
      ),
    );
  }
  

  _shareSession(String? message) {
    String _message = '''
    
     $message  
    ''';
    shareMessage(_message);
  }

  Future<String> saveImage(Uint8List bytes) async {
    await [Permission.storage].request();
    final time = DateTime.now()
    .toIso8601String()
    .replaceAll('.', '-')
    .replaceAll(':', '-');
    final name = 'ClaireShot_$time';
    final result = await ImageGallerySaver.saveImage(bytes, name: name);
    return result['filepath'];
  }

  Future saveAndShare(Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final image = File('${directory.path}/diary_session.png');
    image.writeAsBytesSync(bytes);
    final text = '${AppString.shareHeader}\n\n${AppString.shareLink}';
    await Share.shareFiles([image.path], text: text);
  }

}
