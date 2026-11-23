import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/ui/Categories/archive_sessions_by_mood_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/strings.dart';
import '../featured/model/session.dart';

/// This is a stream class showing the current user's sessions based on their moods.
class ArchiveMoodStream extends StatefulWidget {
  const ArchiveMoodStream({Key? key}) : super(key: key);

  @override
  State<ArchiveMoodStream> createState() => _ArchiveMoodStreamState();
}

class _ArchiveMoodStreamState extends State<ArchiveMoodStream> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _moodsStream;
  final List<Session> _sessionList = [];

  @override
  void initState() {
    super.initState();
    _moodsStream = _getArchiveSessionsByMoods();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getArchiveSessionsByMoods() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Return an empty stream if no user is logged in
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("userId", isEqualTo: currentUser.uid)
        .where("moodId", isNotEqualTo: null)
        .orderBy('timeCreated', descending: true)
        .limit(50)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40, // Set a fixed height for the horizontal list
      child: StreamBuilder<QuerySnapshot>(
        stream: _moodsStream,
        builder: (context, AsyncSnapshot<QuerySnapshot> session) {
          if (session.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink(); // Show nothing while loading
          }
          if (!session.hasData || session.data!.docs.isEmpty) {
            return const SizedBox.shrink(); // Or a message like "No moods found"
          }

          // Clear the list and repopulate it with fresh data
          _sessionList.clear();
          session.data!.docs.forEach((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data != null) {
              _sessionList.add(Session.fromJson(data));
            }
          });

          // Use a Set to store unique mood IDs
          final uniqueMoodIds = <int>{};
          final uniqueSessions = <Session>[];

          for (var sess in _sessionList) {
            if (sess.moodId != null && !uniqueMoodIds.contains(sess.moodId)) {
              uniqueMoodIds.add(sess.moodId!);
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
                // Add padding to the items
                return Padding(
                  padding: EdgeInsets.only(left: (index == 0) ? 16.0 : 8.0, right: (index == uniqueSessions.length - 1) ? 16.0 : 0),
                  child: ArchiveMoodStreamWidget(element: uniqueSessions[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

