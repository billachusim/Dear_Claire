import 'package:cached_network_image/cached_network_image.dart';
import 'package:dear_claire/ui/create_session/session_model.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/utils/mood.dart';
import 'package:dear_claire/widgets/follow_button.dart';
import 'package:dear_claire/widgets/metoo_button.dart';
import 'package:dear_claire/widgets/share_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SessionDetailsWidget extends StatelessWidget {
  CreateSessionModel? singleSessionModel;

  SessionDetailsWidget({Key? key, required this.singleSessionModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      decoration:
          BoxDecoration(color: HexColor.fromHex(singleSessionModel!.colorHex!)),
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
                  imageUrl: singleSessionModel!.userAvatarUrl!,
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
                    Text(singleSessionModel!.userNickname!,
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        style: GoogleFonts.lato(
                            fontSize: 16.0,
                            color: Pallet.colorWhite,
                            fontWeight: FontWeight.w700)),
                    SizedBox(
                      height: 5,
                    ),
                    Text(timeConverter(singleSessionModel!.timeCreated!),
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
                    Text(Mood.getMood(singleSessionModel?.moodId) ?? '',
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        style: GoogleFonts.lato(
                            fontSize: 15.0,
                            color: Pallet.colorWhite,
                            fontWeight: FontWeight.w700)),
                    SizedBox(
                      height: 5,
                    ),
                    Text(singleSessionModel?.location ?? '',
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        style: GoogleFonts.lato(
                            fontSize: 13.0,
                            color: Pallet.colorWhite,
                            fontWeight: FontWeight.normal)),
                  ],
                ),
              )
            ],
          ),
          SizedBox(
            height: 12,
          ),
          Center(
            child: Text(singleSessionModel!.title!,
                textAlign: TextAlign.start,
                maxLines: 1,
                style: GoogleFonts.lato(
                    fontSize: 18.0,
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
                  singleSessionModel!.message!,
                  textAlign: TextAlign.justify,
                  style: GoogleFonts.lato(
                      fontSize: 16.0,
                      color: Pallet.colorWhite,
                      fontWeight: FontWeight.normal),
                ),
              ),
              Visibility(
                  visible: singleSessionModel!.imageUrls!.isNotEmpty,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 10,
                      ),
                      CachedNetworkImage(
                          height: 73,
                          width: 73,
                          imageUrl: singleSessionModel!.imageUrls!.isNotEmpty
                              ? singleSessionModel!.imageUrls!.first
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
                                "assets/images/brown_boy_mask.png",
                                width: 48,
                                height: 48,
                              ) //Icon(Icons.error),
                          ),
                    ],
                  )),
              SizedBox(
                width: 23,
              ),
            ],
          ),
          SizedBox(
            height: 5,
          ),
          Row(
            children: [
              MetooButton(
                cheers: 0,
                onReactionChanged: (reaction, int) {},
                color: Pallet.colorWhite,
              ),
              new Spacer(),
              FollowButton(
                text: 'Follow',
                onPressed: () {},
                count: null,
              ),
              new Spacer(),
              ShareButton(
                onPressed: () {},
                color: Pallet.colorWhite,
              ),
            ],
          )
        ],
      ),
    );
  }
}
