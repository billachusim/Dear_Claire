import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/featured/ego_mode_session_detail.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/mood.dart';
import 'package:dear_claire/widgets/comments_button.dart';
import 'package:dear_claire/widgets/metoo_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:dear_claire/ui/featured/model/session.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:flutter/cupertino.dart';

class SessionCard extends StatelessWidget {
  Session element;

  SessionCard({Key? key, required this.element}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: () => PageRouter.gotoWidget(
          EgoModeSessionDetail(featuredSessionModel: element),
          context),
      padding: EdgeInsets.zero,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: HexColor.fromHex(element.colorHex!)),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        right: 14.0, left: 15.0, top: 15),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25.0),
                      child: CachedNetworkImage(
                          width: 48,
                          height: 48,
                          imageUrl: element.userAvatarUrl!,
                          //"${listOfCompanies[index].logo}",
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
                              CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              Image.asset(
                                "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                                width: 48,
                                height: 48,
                              ) //Icon(Icons.error),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(element.userNickname!,
                              textAlign: TextAlign.start,
                              style: GoogleFonts.lato(
                                  fontSize: 15.0,
                                  color: Pallet.colorWhite,
                                  //fontStyle: FontStyle.normal,
                                  fontWeight: FontWeight.w400)),
                        ),
                        SizedBox(
                          height: 4,
                        ),
                        Text(
                          timeConverter(element.timeCreated!),
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: GoogleFonts.lato(
                              fontSize: 9.0,
                              color: Pallet.colorWhite,
                              //fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(Mood.getMood(element.moodId) ?? "${Mood.MOODS.first}",
                              textAlign: TextAlign.end,
                              style: GoogleFonts.lato(
                                  fontSize: 12.0,
                                  color: Pallet.colorWhite,
                                  //fontStyle: FontStyle.normal,
                                  fontWeight: FontWeight.w500)),
                        ),
                        SizedBox(
                          height: 4,
                        ),
                       Text(element.location ?? "",
                           textAlign: TextAlign.start,
                           maxLines: 1,
                           style: GoogleFonts.lato(
                               fontSize: 13.0,
                               color: Pallet.colorWhite,
                               fontWeight: FontWeight.normal)),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 15.0, right: 15, bottom: 5),
                child: Container(
                  width: MediaQuery
                      .of(context)
                      .size
                      .width,
                  child: Text(element.title!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                          fontSize: 15.0,
                          color: Pallet.colorWhite,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 15.0, right: 15, bottom: 5),
                child: Container(
                  width: MediaQuery
                      .of(context)
                      .size
                     .width,
                  child: Text(
                      element.message!,
                      textAlign: TextAlign.start,
                      maxLines: element.imageUrls!.isNotEmpty ? 4 : 6,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                          fontSize: 12.0,
                          color: Pallet.colorWhite,
                          fontWeight: FontWeight.w400)),
                ),
              ),
              Visibility(
                visible: element.imageUrls!.isNotEmpty,
                child: Padding(
                  padding: EdgeInsets.only(
                      left: 15.0, right: 15, bottom: 5),
                  child: Container(
                    height: 70,
                    width: MediaQuery
                        .of(context)
                        .size.
                        width,
                    child: //Image.asset("assets/images/ic_two_ladies.png", height: 72,width: 72,),

                    ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: ScrollPhysics(),
                        itemCount: element.imageUrls!.length,
                        itemBuilder:
                            (BuildContext context, int index) {
                          return Container(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  right: 4.0),
                              child: CachedNetworkImage(
                                  height: 72,
                                  width: 72,
                                  imageUrl: element.imageUrls!.isNotEmpty
                                      ? element.imageUrls!.first
                                      : '',
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
                                    "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                                    width: 48,
                                    height: 48,
                                  ) //Icon(Icons.error),
                              ),
                            ),
                          );
                        }),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MetooButton(
                        me2: element.meToos!.length,
                        onReactionChanged: (reaction, int){},
                        color: Pallet.colorWhite,
                      session: element,),
                    StreamBuilder(
                        stream: firebaseServices.getFeaturedSessionsComments(
                            element.sessionId!),
                        builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                          if(snapShot.hasError){
                            return Container();
                          }
                          if (snapShot.hasData) {
                            return CommentsButton(count: snapShot.data!.docs.length, onPressed: () {});
                          }
                          return Container();
                        }),
                  ],
                ),
              ),
              // Padding(
              //   padding: const EdgeInsets.only(
              //     top: 8.0,
              //   ),
              //   child: Divider(
              //     height: 1,
              //     color: Pallet.colorWhite,
              //   ),
              // ),
              // Padding(
              //   padding: const EdgeInsets.only(
              //       left: 15.0, right: 15, bottom: 5),
              //   child: Container(
              //     width: MediaQuery
              //         .of(context)
              //         .size
              //         .width,
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         SizedBox(
              //           height: 6,
              //         ),
              //         Text("Claire",
              //             textAlign: TextAlign.start,
              //             maxLines: 2,
              //             overflow: TextOverflow.ellipsis,
              //             style: GoogleFonts.lato(
              //                 fontSize: 15.0,
              //                 color: Pallet.colorWhite,
              //                 fontWeight: FontWeight.w600)),
              //         SizedBox(
              //           height: 3,
              //         ),
              //         Text(
              //             "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin id rutrum eros. adipiscing elit. Proin id rutrum eros Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin id rutrum eros. adipiscing elit. Proin id rutrum eros Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin id rutrum eros. adipiscing elit. Proin id rutrum eros Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin id rutrum eros. adipiscing elit. Proin id rutrum eros ....",
              //             textAlign: TextAlign.start,
              //             maxLines: 2,
              //             overflow: TextOverflow.ellipsis,
              //             style: GoogleFonts.lato(
              //                 fontSize: 12.0,
              //                 color: Pallet.colorWhite,
              //                 fontWeight: FontWeight.w400)),
              //         SizedBox(
              //           height: 10,
              //         )
              //       ],
              //     ),
              //   ),
              // ),
            ]),
      ),
    );
  }
}
