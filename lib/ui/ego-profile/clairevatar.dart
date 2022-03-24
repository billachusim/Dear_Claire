
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/services/user_model.dart';
import 'package:dear_claire/ui/ego-profile/profile.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../widgets/toast.dart';
import '../routes/routes.dart';



class EditClairevatar extends StatefulWidget {
  @override
  _EditClairevatarState createState() => _EditClairevatarState();
}

class _EditClairevatarState extends State<EditClairevatar> {

  User? currentUser = FirebaseAuth.instance.currentUser;
  late final String avatarUrl;


  /// Query Clairevatars from Firestore

  final Stream<QuerySnapshot> _clairevatarGrid = FirebaseFirestore.instance
      .collection('claire_vartar')
      .snapshots();



  /// Get user's Clairevatar

  Future<String> getUserClairevatar() async {
    DocumentSnapshot response = await FirebaseFirestore.instance
        .collection(AppString.users)
        .doc(currentUser?.uid)
        .get();

    var avatarUrl = UserModel.fromFirestore(response.data() as Map<String, dynamic>);
    logger.d('Successfully got the clairevatar');
    print('avatarUrl is: $avatarUrl');
    return avatarUrl.toString();
  }


  /// Change user's Clairevatar

  Future<void> changeClairevatar() async {
    final imageUrl = avatarUrl.toString();
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser?.uid)
        .update({
      "avatarUrl": imageUrl,
    },
    );
    logger.d('Successfully saved new clairevatar');

    getUserClairevatar();
  }

  @override
  Widget build (BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16, bottom: 16, top: 20,),
        child: Column(
          children: [
            Align(
              alignment:Alignment.topLeft,
              child: Container(
                padding:EdgeInsets.only(top:20, bottom: 10),
                child: GestureDetector(
                    onTap: (){
                      print("Clicking on X");
                      Navigator.pop(context);
                    },
                    child: SvgPicture.asset("assets/images/ic_close.svg",
                      width: 17.0,
                      height: 17.0,)
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Choose A New Clairevatar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Pallet.colorWhite,
                    ),
                    ),
                    Text('(Express your ego)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Pallet.colorWhite,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _clairevatarGrid,
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('Something went wrong');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text("Loading");
                  }

                  return GridView.count(
                    crossAxisCount: 5,
                    physics: AlwaysScrollableScrollPhysics(),
                    shrinkWrap: true,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,

                    children: snapshot.data!.docs.map<Widget>((DocumentSnapshot document) {
                      final dynamic data = document.data()!;

                      return GestureDetector(
                        onTap: () {
                          avatarUrl = data['imageUrl'];
                          changeClairevatar();
                          Navigator.of(context)
                              .pushReplacementNamed(AppRoutes.home);
                          showToast(AppString.nice_clairevatar);
                        },

                        child: ClipOval(
                          child: CachedNetworkImage(
                            width: 20,
                            height:20,
                            imageUrl: data['imageUrl'],
                            imageBuilder: (context, imageProvider) => Container(
                              height: 30,
                              width: 30,
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
                              "assets/images/brown_boy_mask.png",
                              width: 20,
                              height: 20,
                            ),
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
    );
  }

}
