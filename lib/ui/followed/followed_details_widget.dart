import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/dairy/diary_details_widget.dart';
import 'package:dear_claire/ui/featured/model/comment_session_model.dart';
import 'package:dear_claire/ui/featured/model/featured_session_model.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:dear_claire/widgets/chat_edit_field.dart';
import 'package:dear_claire/widgets/comment_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class FollowedDetailsScreen extends StatefulWidget {

  FeaturedSessionModel? featuredSessionModel;

  FollowedDetailsScreen({Key? key, required this.featuredSessionModel}) : super(key: key);

  @override
  _FollowedDetailsScreenState createState() => _FollowedDetailsScreenState(featuredSessionModel);
}

class _FollowedDetailsScreenState extends State<FollowedDetailsScreen> {

  FeaturedSessionModel? featuredSessionModel;

  _FollowedDetailsScreenState(this.featuredSessionModel);

  List<CommentSessionModel> _commentSessionList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: HexColor.fromHex(featuredSessionModel!.colorHex!),
        title: Text(featuredSessionModel!.title!),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Image.asset(AppImages.appChatBg,
            height: getDeviceHeight(context),
            width: getDeviceWidth(context),
            fit: BoxFit.cover,
          ),
          ListView(
            children: [
              DiaryDetailsWidget(featuredSessionModel: featuredSessionModel,),
              StreamBuilder(
                  stream: firebaseServices.getDiarySessionsComments(featuredSessionModel!.sessionId!),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapShot){
                    if (snapShot.hasData) {
                      snapShot.data!.docs
                          .map((e) => _commentSessionList
                          .add(CommentSessionModel.fromJson(e)))
                          .toList();
                      return Column(
                        children: [
                          ..._commentSessionList
                              .map((element) => CommentWidget(commentSessionModel: element, sessionId: '',))
                              .toList(),
                        ],
                      );
                    }
                    return Container();
                  }
              ),
              SizedBox(height: 70,)
            ],
          ),

          ChatEditField(onTap: (message, voiceNote){},)
        ],
      ),
    );
  }
}
