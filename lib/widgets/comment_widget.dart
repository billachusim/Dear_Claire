import 'package:cached_network_image/cached_network_image.dart';
import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/ui/featured/model/comment_session_model.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/enums.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/widgets/share_button.dart';
import 'package:dear_claire/widgets/thanks_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ui/routes/page_router_animation.dart';
import '../ui/visited_user_ego_page/visited_user_ego_page.dart';

class CommentWidget extends StatelessWidget {
  CommentSessionModel? commentSessionModel;
  final Function()? onPressed;
  final Function()? onShare;
  late String visitedUsersID;
  late String visitedEgoName;

  User? currentUser = FirebaseAuth.instance.currentUser;

  CommentWidget(
      {Key? key,
      this.onPressed,
      this.onShare,
      required this.commentSessionModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30), color: Pallet.colorWhite),
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
                  visitedUsersID = commentSessionModel!.userId!;
                  visitedEgoName = commentSessionModel!.userNickname!;
                  String thisEgoName =
                      commentSessionModel!.userNickname.toString();
                  String thisUser = commentSessionModel!.userId.toString();
                  PageRouter.gotoWidget(
                      VisitedUserEgoProfilePage(
                          visitedUsersID: thisUser,
                          visitedEgoName: thisEgoName),
                      context);
                  print("Visited User ID::: $thisEgoName");
                },
                child: CachedNetworkImage(
                    width: 40,
                    height: 40,
                    imageUrl: commentSessionModel?.isUserAdmin == true
                        ? "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fclaire_icon.png?alt=media&token=5e14455d-0402-453d-80d0-63b55890f691"
                        : commentSessionModel!.userAvatarUrl ?? '',
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
                          width: 40,
                          height: 40,
                        ) //Icon(Icons.error),
                    ),
              ),
              SizedBox(
                width: 4,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (commentSessionModel?.isUserAdmin == true)
                          visitedUsersID = commentSessionModel!.userId!;
                        visitedEgoName = commentSessionModel!.userNickname!;
                        String thisEgoName =
                            commentSessionModel!.userNickname.toString();
                        String thisUser =
                            commentSessionModel!.userId.toString();
                        PageRouter.gotoWidget(
                            VisitedUserEgoProfilePage(
                                visitedUsersID: thisUser,
                                visitedEgoName: thisEgoName),
                            context);
                        print("Visited User ID::: $thisEgoName");
                      },
                      child: Text(
                          commentSessionModel?.isUserAdmin == true
                              ? "Claire"
                              : commentSessionModel!.userNickname ?? '',
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          style: GoogleFonts.lato(
                              fontSize: 14.0,
                              color: Pallet.colorBlack,
                              fontWeight: FontWeight.w800)),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                        timeConverter(commentSessionModel!.timeCreated!,
                            time: TimeConverterEnum.Comment),
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        style: GoogleFonts.lato(
                            fontSize: 11.0,
                            color: Pallet.colorGrey,
                            fontWeight: FontWeight.normal)),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ThanksButton(
                    count: commentSessionModel!.thanks!.length,
                    onPressed: onPressed,
                    color: 1 == 2 ? Pallet.colorPink : Pallet.colorTextGray,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            height: 1,
          ),
          Text(
            commentSessionModel!.message!,
            textAlign: TextAlign.start,
            style: GoogleFonts.lato(
                fontSize: 15.0,
                color: Pallet.colorBlack,
                fontWeight: FontWeight.normal),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Visibility(
              visible: currentUser?.email == "thesocialfaculty@gmail.com",
              child: Align(
                alignment: Alignment.bottomRight,
                child: Text(commentSessionModel!.alterEgoId!,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    style: GoogleFonts.lato(
                        fontSize: 12.0,
                        color: Pallet.colorBlack,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            if (commentSessionModel!.isUserAdmin)
              CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 2.5, horizontal: 5),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Pallet.colorSecondary,
                        )),
                    child: Row(
                      children: [
                        Icon(
                          Icons.share_rounded,
                          size: 15,
                          color: Pallet.colorSecondary,
                        ),
                        Text(
                          'Share',
                          style: GoogleFonts.lato(
                              fontSize: 13.0,
                              color: Pallet.colorSecondary,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  onPressed: onShare)
          ]),
        ],
      ),
    );
  }
}
