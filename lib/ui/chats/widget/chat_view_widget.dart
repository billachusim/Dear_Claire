import 'package:cached_network_image/cached_network_image.dart';
import 'package:dear_claire/ui/featured/model/comment_session_model.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/enums.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/widgets/share_button.dart';
import 'package:dear_claire/widgets/thanks_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatViewWidget extends StatelessWidget {
  CommentSessionModel? commentSessionModel;

  ChatViewWidget({Key? key, required this.commentSessionModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Pallet.colorWhite
      ),
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
                  imageUrl: commentSessionModel!.userAvatarUrl ?? '',
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  placeholder: (context, url) => Center(child: CircularProgressIndicator()),
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
                    Text(commentSessionModel!.userNickname!,
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        style: GoogleFonts.lato(
                            fontSize: 16.0,
                            color: Pallet.colorBlack,
                            fontWeight: FontWeight.w700)),
                    SizedBox(
                      height: 5,
                    ),
                    Text(timeConverter(commentSessionModel!.timeCreated!,
                        time: TimeConverterEnum.Comment
                    ),
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        style: GoogleFonts.lato(
                            fontSize: 13.0,
                            color: Pallet.colorGrey,
                            fontWeight: FontWeight.normal)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: 16,
          ),
          Text(
            commentSessionModel!.message!,
            textAlign: TextAlign.start,
            style: GoogleFonts.lato(
                fontSize: 16.0,
                color: Pallet.colorBlack,
                fontWeight: FontWeight.normal),
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Visibility(
                  visible: false,
                  child: ThanksButton(
                    count: 3,
                    onPressed: (){},
                    color: Pallet.colorTextGray,)),
              ThanksButton(
                count: 3,
                onPressed: (){},
                color: Pallet.colorPink,),
              ShareButton(
                onPressed: (){},
                color: Pallet.colorPink,),
            ],
          )
        ],
      ),
    );
  }
}
