import 'package:cached_network_image/cached_network_image.dart';
import 'package:clairediary/ui/create_session/session_model.dart';
import 'package:clairediary/ui/create_session/sound/custom_play_sound_widget.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/utils/mood.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/custom_image_widget.dart';
import '../routes/page_router_animation.dart';

class SessionDetailsWidget extends StatelessWidget {
  CreateSessionModel? singleSessionModel;

  SessionDetailsWidget({Key? key, required this.singleSessionModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      decoration:
          BoxDecoration(color: isDarkMode ? Pallet.colorSecondary : HexColor.fromHex(singleSessionModel!.colorHex!)),
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
                    "assets/images/Speak_No_Evil_Monkey_Emoji.png",
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
                            color: isDarkMode ? Pallet.colorWhite : Pallet.colorBlack,
                            fontWeight: FontWeight.w700)),
                    SizedBox(
                      height: 5,
                    ),
                    Text(timeConverter(singleSessionModel!.timeCreated!),
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        style: GoogleFonts.lato(
                            fontSize: 13.0,
                            color: isDarkMode ? Pallet.colorWhite : Pallet.colorBlack,
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
                            color: isDarkMode ? Pallet.colorWhite : Pallet.colorBlack,
                            fontWeight: FontWeight.w700)),
                    SizedBox(
                      height: 5,
                    ),
                    Text(singleSessionModel?.location ?? '',
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        style: GoogleFonts.lato(
                            fontSize: 13.0,
                            color: isDarkMode ? Pallet.colorWhite : Pallet.colorBlack,
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
                    color: isDarkMode ? Pallet.colorWhite : Pallet.colorBlack,
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
                      color: isDarkMode ? Pallet.colorWhite : Pallet.colorBlack,
                      fontWeight: FontWeight.normal),
                ),
              ),
            ],
          ),


          Visibility(
            visible: singleSessionModel!.audioUrl != null,
            child: Container(
              alignment: Alignment.centerLeft,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    singleSessionModel!.audioUrl != null
                        ? CustomPlaySoundWidget(filePath: singleSessionModel?.audioUrl)
                        : SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ),

          Container(
            child: Align(
              alignment: Alignment.topLeft,
              child: Row(
                children: [
                  Visibility(
                      visible: singleSessionModel!.imageUrls!.isNotEmpty,
                      child: GestureDetector(
                        onTap: () {
                          PageRouter.gotoWidget(CustomImageWidget(imageUrl: singleSessionModel!.imageUrls!.first.toString()), context);
                        },
                        child: CachedNetworkImage(
                            height: 120,
                            width: 100,
                            imageUrl: singleSessionModel!.imageUrls!.isNotEmpty
                                ? singleSessionModel!.imageUrls!.first
                                : '',
                            imageBuilder: (context, imageProvider) =>
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    image: DecorationImage(
                                      image: imageProvider,
                                    ),
                                  ),
                                ),
                            placeholder: (context, url) => Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                                Image.asset(
                                  "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                                  width: 48,
                                  height: 48,
                                ) //Icon(Icons.error),
                        ),
                      )),
                  SizedBox(width: 5,),
                  Visibility(
                      visible: singleSessionModel!.imageUrls!.isNotEmpty,
                      child: GestureDetector(
                        onTap: () {
                          PageRouter.gotoWidget(CustomImageWidget(imageUrl: singleSessionModel!.imageUrls!.last.toString()), context);
                        },
                        child: CachedNetworkImage(
                            height: 120,
                            width: 100,
                            imageUrl: singleSessionModel!.imageUrls!.isNotEmpty
                                ? singleSessionModel!.imageUrls!.last
                                : '',
                            imageBuilder: (context, imageProvider) =>
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    image: DecorationImage(
                                      image: imageProvider,
                                    ),
                                  ),
                                ),
                            placeholder: (context, url) => Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                                Image.asset(
                                  "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                                  width: 48,
                                  height: 48,
                                ) //Icon(Icons.error),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
