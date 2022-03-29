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
import 'package:google_fonts/google_fonts.dart';

class PostDetailsWidget extends StatelessWidget {
  String? sessionId;

  PostDetailsWidget({Key? key, required this.sessionId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    return Material(
      child: SafeArea(
        child: StreamBuilder(
            stream: firebaseServices.getSingleDocument(id: sessionId),
            builder: (context,
                AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snaps) {
              if (snaps.hasData) {
                final _session = Session.fromJson(snaps.data!.data()!);
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6.0, vertical: 5),
                  decoration:
                      BoxDecoration(color: HexColor.fromHex(_session.colorHex!)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CachedNetworkImage(
                              width: 48,
                              height: 48,
                              imageUrl: _session.userAvatarUrl!,
                              imageBuilder: (context, imageProvider) => Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ),
                              placeholder: (context, url) =>
                                  Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => Image.asset(
                                    "assets/images/brown_boy_mask.png",
                                    width: 48,
                                    height: 48,
                                  ) //Icon(Icons.error),
                              ),
                          SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_session.userNickname!,
                                    textAlign: TextAlign.start,
                                    maxLines: 1,
                                    style: GoogleFonts.lato(
                                        fontSize: 18.0,
                                        color: Pallet.colorWhite,
                                        fontWeight: FontWeight.w700)),
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
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Row(
                                children: [
                                  Visibility(
                                      visible: _session.imageUrls!.isNotEmpty,
                                      child: CachedNetworkImage(
                                          height: 73,
                                          width: 73,
                                          imageUrl: _session.imageUrls!.isNotEmpty
                                              ? _session.imageUrls!.first
                                              : '',
                                          imageBuilder: (context, imageProvider) =>
                                              Container(
                                                decoration: BoxDecoration(
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
                              if (await firebaseServices.isUserSignIn(context)) {
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
                            onPressed: () =>
                                firebaseServices.user?.alterEgoId == 'claire'
                                    ? shareMessage(_session.message!)
                                    : null,
                            color: firebaseServices.user?.alterEgoId == 'claire'
                                ? Pallet.colorWhite
                                : Pallet.colorWhite,
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
    );
  }
}
