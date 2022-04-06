import 'dart:io';
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
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../../Admob/ad_state.dart';
import '../../create_session/sound/play_sound_widget.dart';
import '../../routes/page_router_animation.dart';
import '../../visited_user_ego_page/visited_user_ego_page.dart';

class CustomPostDetailsWidget extends StatefulWidget {
  CustomPostDetailsWidget({Key? key, required this.sessionId}) : super(key: key);
  String? sessionId;

  @override
  _CustomPostDetailsWidgetState createState() => _CustomPostDetailsWidgetState();
}

class _CustomPostDetailsWidgetState extends State<CustomPostDetailsWidget> {
  late String visitedUsersID;
  late String visitedEgoName;

  //initialize the audio record file that stores user audio record. null by default
  String? recordFile;


  // Admob Ad Units.
  late BannerAd customPostDetailTopBanner;
  late BannerAd customPostDetailBottomBanner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adState = Provider.of<AdState>(context);

    // Implement a top location banner ad unit.
    adState.initialization.then((status) {
      setState(() {
        customPostDetailTopBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.customPostDetailTopBannerAdUnitId,
            request: AdRequest(),
            listener: BannerAdListener(
              onAdFailedToLoad: (ad, error) {
                ad.dispose();
              },
            )
        )..load();
      });
    });

    // Implementing a bottom location banner ad unit.
    super.didChangeDependencies();
    adState.initialization.then((status) {
      setState(() {
        customPostDetailBottomBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.customPostDetailBottomBannerAdUnitId,
            request: AdRequest(),
            listener: BannerAdListener(
              onAdFailedToLoad: (ad, error) {
                ad.dispose();
              },
            )
        )..load();
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    return Material(
      child: SafeArea(
        child: StreamBuilder(
            stream: firebaseServices.getSingleDocument(id: widget.sessionId),
            builder: (context,
                AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snaps) {
              if (snaps.hasData) {
                final _session = Session.fromJson(snaps.data!.data()!);
                return Scaffold(
                  backgroundColor: HexColor.fromHex(_session.colorHex!),
                  appBar: AppBar(
                    centerTitle: true,
                    backgroundColor: HexColor.fromHex(_session.colorHex!),
                    title: Text(_session.title!,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 22,
                        color: Pallet.colorWhite,
                      ),
                    ),
                    elevation: 0,
                  ),
                  body: Container(
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
                                  FutureBuilder<Widget>(
                                      future: firebaseServices.showUserLocation(),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<Widget> snapshot) {
                                        if (snapshot.hasData) {
                                          print('Location: ${snapshot.hasData}');
                                          return snapshot.data!;
                                        } else {
                                          return Text('',
                                              textAlign: TextAlign.end,
                                              maxLines: 1,
                                              style: GoogleFonts.lato(
                                                  fontSize: 12.0,
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.w700));
                                        }
                                      }),
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
                            Container(
                              alignment: Alignment.centerLeft,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    _session.audioUrl!.isNotEmpty
                                        ? Container(
                                      height: 60.h,
                                      width: 60.w,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: <Widget>[
                                          Center(
                                              child: IconButton(
                                                  icon: Icon(
                                                      Icons
                                                          .play_circle_fill_outlined,
                                                      color: Colors.white,
                                                      size: 40.r),
                                                  onPressed: () {
                                                    recordFile = _session.audioUrl!.toString();
                                                    showDialog<void>(
                                                      context: context,
                                                      barrierDismissible:
                                                      false, // user must tap button!
                                                      builder: (BuildContext
                                                      context) {
                                                        return AlertDialog(
                                                          content:
                                                          PlaySoundWidget(
                                                            filePath:
                                                            recordFile,
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
                                                  onPressed: () =>
                                                      setState(() {
                                                        recordFile = null;
                                                      })))
                                        ],
                                      ),
                                    )
                                        : SizedBox.shrink(),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: Row(
                                  children: [
                                    Visibility(
                                        visible: _session.imageUrls!.isNotEmpty,
                                        child: CachedNetworkImage(
                                            height: 73,
                                            width: 73,
                                            imageUrl:
                                            _session.imageUrls!.isNotEmpty
                                                ? _session.imageUrls!.first
                                                : '',
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
                                            placeholder: (context, url) => Center(
                                                child:
                                                CircularProgressIndicator()),
                                            errorWidget: (context, url, error) =>
                                                Image.asset(
                                                  "assets/images/brown_boy_mask.png",
                                                  width: 48,
                                                  height: 48,
                                                ) //Icon(Icons.error),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
                            ShareButton(
                              onPressed: () => _shareSession(_session.message!),
                              color: Colors.white,
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              }
              return Container();
            }),
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
                            filePath: recordFile,
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

  _shareSession(String? message) {
    String _message = '''
    
     $message  
    ''';
    shareMessage(_message);
  }
}
