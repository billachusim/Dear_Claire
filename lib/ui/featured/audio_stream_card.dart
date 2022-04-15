import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:dear_claire/ui/featured/model/comment_session_model.dart';
import 'package:dear_claire/ui/featured/model/session.dart';
import 'package:dear_claire/ui/featured/ego_mode_session_detail.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/utils/mood.dart';
import 'package:dear_claire/widgets/comments_button.dart';
import 'package:dear_claire/widgets/metoo_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:full_screen_image/full_screen_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/strings.dart';
import '../../widgets/toast.dart';
import '../create_session/sound/custom_play_sound_widget.dart';
import '../visited_user_ego_page/visited_user_ego_page.dart';

class AudioStreamCard extends StatelessWidget {
  Session element;

  AudioStreamCard({Key? key, required this.element, required this.visitedUsersID, required this.visitedEgoName}) : super(key: key);
  late String visitedUsersID;
  late String visitedEgoName;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: () => PageRouter.gotoWidget(
          EgoModeSessionDetail(featuredSessionModel: element),
          context),
      padding: EdgeInsets.zero,
      child: Container(
        width: 250,
        height: 132,
        margin: EdgeInsets.symmetric(vertical: 1, horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: HexColor.fromHex(element.colorHex!)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: (){
                    visitedUsersID = element.userId!;
                    visitedEgoName = element.userNickname!;
                    String thisEgoName = visitedEgoName;
                    String thisUser = visitedUsersID;
                    PageRouter.gotoWidget(
                        VisitedUserEgoProfilePage(visitedUsersID: thisUser, visitedEgoName: thisEgoName),
                        context);
                    print("Visited User ID::: $visitedUsersID");
                  },
                  child: CachedNetworkImage(
                      width: 33,
                      height: 33,
                      imageUrl: element.userAvatarUrl!,
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                      placeholder: (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Image.asset(
                        "assets/images/brown_boy_mask.png",
                        width: 20,
                        height: 20,
                      ) //Icon(Icons.error),
                  ),
                ),
                SizedBox(
                  width: 6,
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: (){
                          visitedUsersID = element.userId!;
                          visitedEgoName = element.userNickname!;
                          String thisEgoName = visitedEgoName;
                          String thisUser = visitedUsersID;
                          PageRouter.gotoWidget(
                              VisitedUserEgoProfilePage(visitedUsersID: thisUser, visitedEgoName: thisEgoName),
                              context);
                          print("Visited User ID::: $visitedUsersID");
                        },
                        child: Text(element.userNickname!,
                            textAlign: TextAlign.start,
                            maxLines: 1,
                            style: GoogleFonts.lato(
                                fontSize: 14.0,
                                color: Pallet.colorWhite,
                                fontWeight: FontWeight.w700)),
                      ),
                      SizedBox(
                        height: 1,
                      ),
                      Text(timeConverter(element.timeCreated!),
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          style: GoogleFonts.lato(
                              fontSize: 10.0,
                              color: Colors.white70,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [

                      Text(Mood.getMood(element.moodId) ?? "${Mood.getMood(1)}",
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          style: GoogleFonts.lato(
                              fontSize: 10.0,
                              color: Pallet.colorWhite,
                              fontWeight: FontWeight.w700)),
                      SizedBox(
                        height: 1,
                      ),
                      Text(element.location ?? "",
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          style: GoogleFonts.lato(
                              fontSize: 10.0,
                              color: Colors.white70,
                              fontWeight: FontWeight.w700)
                      ),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(
              height: 4,
            ),
            Center(
              child: Text(element.title!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: GoogleFonts.lato(
                      fontSize: 13.0,
                      color: Pallet.colorWhite,
                      fontWeight: FontWeight.w800)),
            ),
            SizedBox(
              height: 3,
            ),
            Column(
              children: [

                Container(
                  alignment: Alignment.topLeft,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      children: [
                        CustomPlaySoundWidget(filePath: element.audioUrl)
                      ],
                    ),
                  ),
                ),

              ],
            ),

          ],
        ),
      ),
    );
  }

}
