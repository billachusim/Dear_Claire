import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/ui/Categories/archive_category_stream.dart';
import 'package:clairediary/ui/Categories/category_streams2.dart';
import 'package:clairediary/ui/create_session/sound/status_stream_audio_player.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/ui/splash_screen/rotate_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/hidden_posts_service.dart';
import '../../services/user_model.dart';
import '../../utils/global_app_state.dart';
import '../../utils/strings.dart';
import '../Search/custom_search_card.dart';
import '../featured/model/session.dart';
import '../../widgets/ego_mode_session_card.dart';


/// First class is the featured sessions
class TheFeaturedSessions extends StatefulWidget {
  final ScrollController? scrollController;
  final Future<void> Function() onRefresh; // Add this line

  const TheFeaturedSessions({
    Key? key,
    this.scrollController,
    required this.onRefresh, // Add this line
  }) : super(key: key);


  @override
  State<TheFeaturedSessions> createState() => _TheFeaturedSessionsState();
}

class _TheFeaturedSessionsState extends State<TheFeaturedSessions> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final HiddenPostsService _hiddenPostsService = HiddenPostsService();
  StreamSubscription<bool>? _refreshSubscription;
  UserModel? _currentUserModel;
  List<String> _hiddenPostIds = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    // --- START: LISTEN FOR REFRESH EVENTS ---
    // Listen to the global refresh stream.
    _refreshSubscription = App.refreshFeed.stream.listen((_) {
      // When an event is received, reload all data and trigger a rebuild.
      _loadInitialData();
    });
    // --- END: LISTEN FOR REFRESH EVENTS ---
  }

  @override
  void dispose() {
    // --- START: CANCEL THE SUBSCRIPTION ---
    // Clean up the stream subscription to prevent memory leaks.
    _refreshSubscription?.cancel();
    // --- END: CANCEL THE SUBSCRIPTION ---
    super.dispose();
  }

  // A single method to load hidden posts and blocked users.
  Future<void> _loadInitialData() async {
    if (currentUser != null) {
      final hiddenIds = await _hiddenPostsService.getHiddenPostIds();
      final userModel = await firebaseServices.getUserInfo();

      if (mounted) {
        setState(() {
          _hiddenPostIds = hiddenIds;
          _currentUserModel = userModel;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder(
        stream: firebaseServices.getFeaturedSession(),
        builder: (context, AsyncSnapshot<QuerySnapshot> session) {
          if (session.connectionState == ConnectionState.waiting) {
            return RotateImage(70, 70);
          }
          if (!session.hasData || session.data!.docs.isEmpty) {
            return Center(
              child: Text("No Session data",
                  style: GoogleFonts.lato(
                      fontSize: 15.0,
                      color: Pallet.colorBlack,
                      fontWeight: FontWeight.w600)),
            );
          }

          // --- UPDATED FILTERING LOGIC ---
          final allSessions = session.data!.docs.map((e) {
            return Session.fromJson(e.data() as Map<String, dynamic>);
          }).toList();

          // Get the list of blocked user IDs from the current user model.
          final blockedUserIds = _currentUserModel?.blockedUsers ?? [];

          final filteredSessions = allSessions.where((s) {
            // Check if the post is hidden OR the author is blocked.
            final isHidden = _hiddenPostIds.contains(s.sessionId);
            final isBlocked = blockedUserIds.contains(s.userId);
            // Return true only if the post is NOT hidden AND the user is NOT blocked.
            return !isHidden && !isBlocked;
          }).toList();
          // --- END UPDATED FILTERING LOGIC ---

          if (filteredSessions.isEmpty) {
            return Center(
              child: Text("No new sessions to show.",
                  style: GoogleFonts.lato(
                      fontSize: 15.0,
                      color: Pallet.colorBlack,
                      fontWeight: FontWeight.w600)),
            );
          }

          return RefreshIndicator(
            onRefresh: widget.onRefresh,
            color: Pallet.colorPrimary,
            child: Scrollbar(
              child: ListView.builder(
                controller: widget.scrollController,
                itemCount: filteredSessions.length,
                itemBuilder: (context, index) {
                  return EgoModeSessionCard(
                    element: filteredSessions[index],
                    visitedUsersID: '',
                    visitedEgoName: '',
                  );
                },
              ),
            ),
          );
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
                    child: SizedBox(
                      height: 50,
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
class UsersArchiveCategories extends StatefulWidget {
  UsersArchiveCategories({Key? key}) : super(key: key);

  @override
  State<UsersArchiveCategories> createState() => _UsersArchiveCategoriesState();
}

class _UsersArchiveCategoriesState extends State<UsersArchiveCategories> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _categoryStream;
  final List<Session> _sessionList = [];

  @override
  void initState() {
    super.initState();
    _categoryStream = _getArchiveCategoryCards();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getArchiveCategoryCards() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Stream.empty(); // Return an empty stream if no user
    }
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("userId", isEqualTo: currentUser.uid)
        .where("category1", isNotEqualTo: null)
        .limit(100)
        .orderBy('timeLastActivity', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40, // Set a fixed height for the horizontal list
      child: StreamBuilder<QuerySnapshot>(
        stream: _categoryStream,
        builder: (context, AsyncSnapshot<QuerySnapshot> session) {
          if (session.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink(); // Show nothing while loading
          }
          if (!session.hasData || session.data!.docs.isEmpty) {
            return const SizedBox.shrink(); // Or a message like "No categories found"
          }

          _sessionList.clear();
          session.data!.docs.forEach((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data != null) {
              _sessionList.add(Session.fromJson(data));
            }
          });

          // Use a Set to store unique category names
          final uniqueCategoryNames = <String>{};
          final uniqueSessions = <Session>[];

          for (var sess in _sessionList) {
            if (sess.category1 != null && !uniqueCategoryNames.contains(sess.category1)) {
              uniqueCategoryNames.add(sess.category1!);
              uniqueSessions.add(sess);
            }
          }

          if (uniqueSessions.isEmpty) {
            return const SizedBox.shrink();
          }

          return Scrollbar(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: uniqueSessions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(left: (index == 0) ? 16.0 : 8.0, right: (index == uniqueSessions.length - 1) ? 16.0 : 0),
                  // IMPORTANT: You will likely need to create this new widget in the next step
                  child: ArchiveCategoryStream(element: uniqueSessions[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}






/// This is a stream class showing status stream


class FeaturedStatusStreams extends StatelessWidget {

  FeaturedStatusStreams({Key? key}) : super(key: key);

  final List<Session>? _sessionList = [];


  /// Get Featured sessions with audio
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> showAudioSessions() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("containsAudio", isEqualTo: true)
        .where("repliesEnabled", isEqualTo: true)
        .where("featured", isEqualTo: true)
        .where("archived", isEqualTo: false)
        .where("flagged", isEqualTo: false)
        .limit(100)
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
                    child: SizedBox(height: 64,
                      child: ListView(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._sessionList!
                              .map((element) =>
                              StatusSoundPlayWidget(element: element))
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