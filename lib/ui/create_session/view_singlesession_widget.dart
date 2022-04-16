

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/create_session/session_details_widget.dart';
import 'package:dear_claire/ui/create_session/session_model.dart';
import 'package:dear_claire/ui/featured/model/comment_session_model.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:dear_claire/widgets/chat_edit_field.dart';
import 'package:dear_claire/widgets/comment_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';



class SessionPostDetailsScreen extends StatefulWidget {

  CreateSessionModel? sessionModel;

   SessionPostDetailsScreen({Key? key, required this.sessionModel}) : super(key: key);

  @override
  _SessionPostDetailsScreenState createState() => _SessionPostDetailsScreenState(sessionModel);
}

class _SessionPostDetailsScreenState extends State<SessionPostDetailsScreen> {

  CreateSessionModel? sessionModel;

  _SessionPostDetailsScreenState(this.sessionModel);

  List<CommentSessionModel> _commentSessionList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: HexColor.fromHex(sessionModel!.colorHex!),
        title: Text(sessionModel!.title ?? ""),
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
              SessionDetailsWidget(singleSessionModel: sessionModel,),
              StreamBuilder(
                  stream: firebaseServices.getFeaturedSessionsComments(sessionModel!.sessionId!),
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

          ChatEditField(
            onTap: (String message, String voiceNote){
            },
          )
        ],
      ),
    );
  }
}
