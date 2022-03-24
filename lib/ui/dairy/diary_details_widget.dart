import 'package:cached_network_image/cached_network_image.dart';
import 'package:dear_claire/ui/featured/model/featured_session_model.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/widgets/edit_button.dart';
import 'package:dear_claire/widgets/follow_button.dart';
import 'package:dear_claire/widgets/metoo_button.dart';
import 'package:dear_claire/widgets/share_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DiaryDetailsWidget extends StatelessWidget {
  FeaturedSessionModel? featuredSessionModel;

  DiaryDetailsWidget({Key? key, required this.featuredSessionModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      decoration: BoxDecoration(
          color: HexColor.fromHex(featuredSessionModel!.colorHex!)),
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
                  imageUrl: featuredSessionModel!.userAvatarUrl!,
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
                    Text(featuredSessionModel!.userNickname!,
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        style: GoogleFonts.lato(
                            fontSize: 16.0,
                            color: Pallet.colorWhite,
                            fontWeight: FontWeight.w700)),
                    SizedBox(
                      height: 5,
                    ),
                    Text(timeConverter(featuredSessionModel!.timeCreated!),
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
                    Text('Feeling Sad',
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        style: GoogleFonts.lato(
                            fontSize: 15.0,
                            color: Pallet.colorWhite,
                            fontWeight: FontWeight.w700)),
                    SizedBox(
                      height: 5,
                    ),
                    Text('Lagos, Nigeria',
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
            child: Text(featuredSessionModel!.title!,
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
                  featuredSessionModel!.message!,
                  textAlign: TextAlign.justify,
                  style: GoogleFonts.lato(
                      fontSize: 16.0,
                      color: Pallet.colorWhite,
                      fontWeight: FontWeight.normal),
                ),
              ),
              Visibility(
                  visible: featuredSessionModel!.imageUrls!.isNotEmpty,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 10,
                      ),
                      CachedNetworkImage(
                          height: 73,
                          width: 73,
                          imageUrl: featuredSessionModel!.imageUrls!.isNotEmpty
                              ? featuredSessionModel!.imageUrls!.first
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
              EditButton(onPressed: () {}),
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
