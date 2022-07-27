import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/Categories/archive_category_stream.dart';
import 'package:dear_claire/ui/Categories/category_streams2.dart';
import 'package:dear_claire/ui/featured/widget/status_stream.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/strings.dart';
import '../Search/custom_search_card.dart';
import '../featured/model/session.dart';
import '../../widgets/ego_mode_session_card.dart';


/// First class is the paid featured sessions

class TheFeaturedSessions extends StatelessWidget {

  TheFeaturedSessions({Key? key}) : super(key: key);

  User? currentUser = FirebaseAuth.instance.currentUser;


  final List<Session>? _sessionList = [];


  @override
  Widget build(BuildContext context) {
    return
      Expanded(
        child: StreamBuilder(
          stream: firebaseServices.getFeaturedSession(),
          builder: (context, AsyncSnapshot<QuerySnapshot> session) {
            if (session.connectionState == ConnectionState.waiting) {
              return RotateImage(70, 70);
            }
            if (!session.hasData) {
              return Center(
                child: Text("No Session data",
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                        fontSize: 15.0,
                        color: Pallet.colorBlack,
                        //fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w600)),
              );
            }
            if (session.hasData) {
              // clear list
              _sessionList!.clear();

              session.data!.docs.map((e) {
                _sessionList!.add(Session.fromJson(e.data()));
              }).toList();

              return Scrollbar(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ..._sessionList!
                        .map((element) => EgoModeSessionCard(element: element, visitedUsersID: '', visitedEgoName: '',))
                        .toList(),
                  ],
                ),
              );
            }
            return Container();
          },
        ),
      );
  }


}

/// This shows a notice header about featured sessions.
class FeaturedSessionNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        child: Text(
          "Featured Sessions are selected from public diary sessions.\n"
              "Your diary session can NOT appear here if you made it private.\n"
              "Tap the spinning icon to start a new diary session.",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}



/// This is a stream class showing public sessions based on their categories.


class TrendingCategories extends StatelessWidget {

  TrendingCategories({Key? key}) : super(key: key);

  final List<Session>? _sessionList = [];


  /// Get Featured session for the trending category.
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> trendingCategoryCards() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("repliesEnabled", isEqualTo: true)
        .where("category1", isNotEqualTo: null)
        .where("archived", isEqualTo: false)
        .where("flagged", isEqualTo: false)
        .limit(25)
        .orderBy('timeLastActivity', descending: true)
        .snapshots();
  }




  @override
  Widget build(BuildContext context) {
    return
      Column(
        children: [
          Container(
            child: StreamBuilder(
              stream: trendingCategoryCards(),
              builder: (context, AsyncSnapshot<QuerySnapshot> session) {
                if (session.connectionState == ConnectionState.waiting) {
                  return Text("");
                }
                if (!session.hasData) {
                  return Center(
                    child: Text("No Session data",
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                            fontSize: 3.0,
                            color: Pallet.colorBlack,
                            //fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w600)),
                  );
                }
                if (session.hasData) {
                  // clear list
                  _sessionList!.clear();

                  session.data!.docs.map((e) {
                    _sessionList!.add(Session.fromJson(e.data()));
                  }).toList();

                  return Scrollbar(
                    child: SizedBox(height: 33,
                      child: ListView(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._sessionList!
                              .map((element) =>
                              CategoryStreams2(element: element))
                              .toList(),
                        ],
                      ),
                    ),
                  );
                }
                return Container();
              },
            ),
          ),
        ],
      );
  }

}




/// This is a stream class showing users' sessions based on their categories.


class UsersArchiveCategories extends StatelessWidget {

  UsersArchiveCategories({Key? key}) : super(key: key);

  final List<Session>? _sessionList = [];


  /// Get Featured session for the trending category.
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> archiveCategoryCards() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("repliesEnabled", isEqualTo: true)
        .where("category1", isNotEqualTo: null)
        .limit(25)
        .orderBy('timeLastActivity', descending: true)
        .snapshots();
  }




  @override
  Widget build(BuildContext context) {
    return
      Column(
        children: [
          Container(
            child: StreamBuilder(
              stream: archiveCategoryCards(),
              builder: (context, AsyncSnapshot<QuerySnapshot> session) {
                if (session.connectionState == ConnectionState.waiting) {
                  return Text("");
                }
                if (!session.hasData) {
                  return Center(
                    child: Text("No Session data",
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                            fontSize: 3.0,
                            color: Pallet.colorBlack,
                            //fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w600)),
                  );
                }
                if (session.hasData) {
                  // clear list
                  _sessionList!.clear();

                  session.data!.docs.map((e) {
                    _sessionList!.add(Session.fromJson(e.data()));
                  }).toList();

                  return Scrollbar(
                    child: SizedBox(height: 33,
                      child: ListView(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._sessionList!
                              .map((element) =>
                              ArchiveCategoryStream(element: element))
                              .toList(),
                        ],
                      ),
                    ),
                  );
                }
                return Container();
              },
            ),
          ),
        ],
      );
  }

}






/// This is a stream class showing status stream


class FeaturedStatusStreams extends StatelessWidget {

  FeaturedStatusStreams({Key? key}) : super(key: key);

  final List<Session>? _sessionList = [];


  /// Get Featured sessions for "love and relationship" search
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> showAudioSessions() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("repliesEnabled", isEqualTo: true)
        .where("audioUrl", isGreaterThanOrEqualTo: "https")
        .where("archived", isEqualTo: false)
        .where("flagged", isEqualTo: false)
        .limit(100)
        .orderBy('audioUrl', descending: true)
        .orderBy('timeLastActivity', descending: true)
        .snapshots();
  }




  @override
  Widget build(BuildContext context) {
    return
      Column(
        children: [
          Container(
            child: StreamBuilder(
              stream: showAudioSessions(),
              builder: (context, AsyncSnapshot<QuerySnapshot> session) {
                if (session.connectionState == ConnectionState.waiting) {
                  return Text("");
                }
                if (!session.hasData) {
                  return Text("");
                }
                if (session.hasData) {
                  // clear list
                  _sessionList!.clear();

                  session.data!.docs.map((e) {
                    _sessionList!.add(Session.fromJson(e.data()));
                  }).toList();

                  return Scrollbar(
                    child: SizedBox(height: 82,
                      child: ListView(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._sessionList!
                              .map((element) =>
                              StatusStreamWidget(element: element))
                              .toList(),
                        ],
                      ),
                    ),
                  );
                }
                return Container();
              },
            ),
          ),
        ],
      );
  }

}



/// This is a stream class showing friends and fun public sessions


class FriendsAndFunSessions extends StatelessWidget {

  FriendsAndFunSessions({Key? key}) : super(key: key);

  final List<Session>? _sessionList = [];


  /// Get Featured sessions for "Make new friends" search
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> showMakeNewFriendsSearches() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("category1", isEqualTo: "friends and fun")
        .where("repliesEnabled", isEqualTo: true)
        .where("archived", isEqualTo: false)
        .where("flagged", isEqualTo: false)
        .limit(AppString.appSessionLength)
    // .orderBy('timeCreated', descending: true)
        .snapshots();
  }




  @override
  Widget build(BuildContext context) {
    return
      Column(
        children: [
          Container(
            child: StreamBuilder(
              stream: showMakeNewFriendsSearches(),
              builder: (context, AsyncSnapshot<QuerySnapshot> session) {
                if (session.connectionState == ConnectionState.waiting) {
                  return RotateImage(70, 70);
                }
                if (!session.hasData) {
                  return Center(
                    child: Text("No Session data",
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                            fontSize: 15.0,
                            color: Pallet.colorBlack,
                            //fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w600)),
                  );
                }
                if (session.hasData) {
                  // clear list
                  _sessionList!.clear();

                  session.data!.docs.map((e) {
                    _sessionList!.add(Session.fromJson(e.data()));
                  }).toList();

                  return Scrollbar(
                    child: SizedBox(height: 200,
                      child: ListView(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._sessionList!
                              .map((element) =>
                              CustomSearchCard(element: element, visitedUsersID: '', visitedEgoName: '',))
                              .toList(),
                        ],
                      ),
                    ),
                  );
                }
                return Container();
              },
            ),
          ),
        ],
      );
  }

}