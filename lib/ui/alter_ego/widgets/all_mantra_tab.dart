import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/firebase_services.dart';
import '../../../utils/color.dart';
import '../../../utils/helper.dart';
import '../../../utils/strings.dart';
import '../../routes/page_router_animation.dart';
import '../../visited_user_ego_page/visited_user_ego_page.dart';

class AllMantraTab extends StatefulWidget {
  const AllMantraTab({ Key? key }) : super(key: key);

  @override
  _AllMantraTabState createState() => _AllMantraTabState();
}


/// Query Ego stream from Firestore

Stream<QuerySnapshot<Map<String, dynamic>>> getAllEgoStream() {

  return FirebaseFirestore.instance
      .collection('ego_stream')
      .limit(500)
      .orderBy('egoTime', descending: true)
      .snapshots();
}

/// Delete an ego message

Future<void> deleteEgoMessage(String egoMessage) async {
  final collection = FirebaseFirestore.instance
      .collection('ego_stream')
      .where("egoMessage", isEqualTo: egoMessage);
  collection.get().then((value) {
    value.docs.forEach((element) {
      element.reference.delete();
    });
  });
  logger.d('Successfully deleted an ego message');
}


class _AllMantraTabState extends State<AllMantraTab> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(child:
    Scaffold(
      backgroundColor: Pallet.colorSecondaryDark,
      body: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getAllEgoStream(),
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('Something went wrong');
                  }
                  if (!snapshot.hasData) {
                    return Text('Write a mantra that you wish to live by currently by tapping on this space',
                      style: TextStyle(color: Colors.white),);
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text("Loading");
                  }

                  return ListView(
                    shrinkWrap: true,
                    children: snapshot.data!.docs.map((DocumentSnapshot document) {
                      Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                      return ListTile(
                        leading: ClipOval(
                          child: GestureDetector(
                            onTap: (){
                              final String _mantraUserId = data['senderId'].toString();
                              final String _mantraEgoName = data['egoName'].toString();
                              PageRouter.gotoWidget(
                                  VisitedUserEgoProfilePage(visitedUsersID: _mantraUserId, visitedEgoName: _mantraEgoName),
                                  context);
                              print("Visited User ID::: $_mantraUserId");
                            },
                            child: CachedNetworkImage(
                              width: 40,
                              height: 40,
                              imageUrl: data['egoImage'],
                              imageBuilder: (context, imageProvider) => Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                              placeholder: (context, url) =>
                                  CircularProgressIndicator(),
                              errorWidget: (context, url, error) => Image.asset(
                                "assets/images/Speak_No_Evil_Monkey_Emoji.png",
                                width: 30,
                                height: 30,
                              ),
                            ),
                          ),
                        ),
                        title: Text(data['egoName'].toString(),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        subtitle: Text(data['egoMessage'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: GestureDetector(
                          onTap: () {
                            final String _egoMessage = data['egoMessage'];
                            showCustomDialog(context,
                                message: AppString.delete_mantra_alert_note,
                                onPressed: () {
                                  PageRouter.goBack(context);
                                  deleteEgoMessage(_egoMessage);
                                });
                          },
                          child: Icon(
                            Icons.delete_forever_rounded,
                            color: Colors.white70,
                            size: 15,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    )
    );

        }

}