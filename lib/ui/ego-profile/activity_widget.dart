import 'package:clairediary/services/user_activity_model.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/ui/splash_screen/rotate_logo.dart';
import 'package:clairediary/utils/mood.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constant.dart';
import '../../widgets/toast.dart';
import '../chats/data/chatroompodo.dart';
import '../chats/inside_chatroom.dart';
import '../featured/notified_session_details.dart';
import '../visited_user_ego_page/visited_user_ego_page.dart';

class ActivityWidget extends StatefulWidget {
  final String userId;
  const ActivityWidget({Key? key, required this.userId}) : super(key: key);

  @override
  State<ActivityWidget> createState() => _ActivityWidgetState();
}

class _ActivityWidgetState extends State<ActivityWidget> {
  // --- STATE FOR PAGINATION ---
  List<UserActivityModel> _activities = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final int _limit = 20; // Fetch 20 activities at a time

  // --- STATE FOR ANALYSIS ---
  String _currentMood = 'Not Available';
  String _popularMood = 'Not Available';
  String _currentActivity = 'Not Available';
  String _popularActivity = 'Not Available';
  Map<String, int> _activityCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  // --- NEW DATA FETCHING LOGIC WITH PAGINATION ---

  Future<void> _fetchInitialData() async {
    if (mounted) setState(() => _isLoading = true);

    // Fetch only the first page of activities
    final activityData = await firebaseServices.getActivityForUser(
      userId: widget.userId,
      limit: _limit,
    );

    // Save the state for the next page
    _lastDocument = activityData.lastDocument;
    _activities = activityData.activities;
    _hasMore = _activities.length >= _limit;

    // Run analysis on the first batch to populate stats quickly
    await _runAnalysisOnData(_activities);

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    if (mounted) setState(() => _isLoadingMore = true);

    // Fetch the next page using the last document as a starting point
    final activityData = await firebaseServices.getActivityForUser(
      userId: widget.userId,
      limit: _limit,
      startAfter: _lastDocument,
    );

    _lastDocument = activityData.lastDocument;
    final newActivities = activityData.activities;
    _hasMore = newActivities.length >= _limit;

    // Add the new activities to our existing list
    _activities.addAll(newActivities);

    // Re-run analysis to keep stats updated (optional, can be removed for performance)
    await _runAnalysisOnData(_activities);

    if (mounted) setState(() => _isLoadingMore = false);
  }

  // --- SIMPLIFIED & RELIABLE ANALYSIS LOGIC ---

  Future<void> _runAnalysisOnData(List<UserActivityModel> activities) async {
    if (activities.isEmpty) {
      _currentActivity = 'Not Available';
      _popularActivity = 'Not Available';
      _currentMood = 'Not Available';
      _popularMood = 'Not Available';
      _activityCounts = {};
      return;
    }

    // --- Analyze Activities ---
// First, sort all activities to find the absolute most recent one for the "Current Activity" card.
    activities.sort((a, b) => b.dateCreated!.compareTo(a.dateCreated!));
    _currentActivity = _formatActivityType(activities.first.activityType);

// Create a new list containing ONLY the activities performed by the current user.
    final userPerformedActivities = activities
        .where((act) => act.clientId == widget.userId)
        .toList();

// Now, build the chart data (_activityCounts) and popular activity from this filtered list.
    _activityCounts =
        groupBy(userPerformedActivities, (UserActivityModel act) => act.activityType!)
            .map((key, value) => MapEntry(_formatActivityType(key), value.length));

    if (_activityCounts.isNotEmpty) {
      _popularActivity =
          _activityCounts.entries.sortedBy<num>((e) => -e.value).first.key;
    } else {
      // If the user has not performed any actions themselves, set popular activity to N/A.
      _popularActivity = 'Not Available';
    }

    // Analyze Moods (Simplified logic)
    final mostRecentSessionActivity = activities.firstWhereOrNull(
          (act) => act.activityType == 'session' && act.sessionId != null,
    );

    if (mostRecentSessionActivity != null) {
      final sessions = await firebaseServices.getSessionsByIds([mostRecentSessionActivity.sessionId!]);
      if (sessions.isNotEmpty) {
        final session = sessions.first;
        if (session.moodId != null) {
          _currentMood = Mood.getMood(session.moodId) ?? 'Unknown';
          _popularMood = _currentMood; // Simple and reliable
        }
      }
    } else {
      _currentMood = 'Not Available';
      _popularMood = 'Not Available';
    }
  }

  // Your formatting function remains the same
  String _formatActivityType(String? type) {
    if (type == null) return 'Weird';
    switch (type) {
      case 'session': return 'Diary Session';
      case 'comment': return 'Advising';
      case 'react': return 'Reacting'; // Keep old 'react' for historical data
      case 'thank': return 'Thanksgiving';
      case 'follow': return 'Following';
      case 'game_win': return 'Winning Games';
      case 'room_join': return 'Joining Rooms';
      case 'visit_ego': return 'Visiting Ego';
      case 'send_love': return 'Sending Love';
      case 'cash_out': return 'Cashing Out';
      case 'mantra': return 'Whispering Mantra';

    // Add cases for the new raw reaction values
      case 'Cheers👍':
      case 'Thanks💕':
      case 'Sorry🖐':
      case 'Me2🌺':
        return type; // Return the raw value directly

      default:
        return type.replaceAll('_', ' ').split(' ').map((str) => str.isNotEmpty ? str[0].toUpperCase() + str.substring(1) : '').join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: RotateImage(70, 70));
    }

    if (_activities.isEmpty) {
      return Center(
        child: Text("There are no activities yet",
            style: GoogleFonts.lato(fontSize: 16.0, color: Colors.white70)),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildImmersiveChart()),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        _buildStatsSection(),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Recent Activities",
              style: GoogleFonts.lato(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: UserActivityCard(element: _activities[index]),
                  ),
                ),
              );
            },
            childCount: _activities.length,
          ),
        ),
        SliverToBoxAdapter(
          child: _buildLoadMoreButton(), // <-- The smart button
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }



  // --- NEW, COMPLETE, and CRASH-PROOF IMMERSIVE CHART ---
  Widget _buildImmersiveChart() {
    final topActivities = _activityCounts.entries
        .sortedBy<num>((e) => -e.value)
        .take(5)
        .toList();

    // --- FALLBACK UI ---
    // If there are fewer than 3 activity types, show a simple list instead of crashing.
    if (topActivities.length < 3) {
      return Container(
        width: double.infinity, // Ensure it takes full width
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Pallet.colorSecondary.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Activity Breakdown",
              style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 10),
            // Handle the case where there are no activities at all
            if (topActivities.isEmpty)
              Text(
                "No activities with distinct types found yet.",
                style: GoogleFonts.lato(color: Colors.white70, fontSize: 14),
              )
            else
            // If there are 1 or 2, list them
              for (var activity in topActivities)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    "• ${activity.key} (${activity.value} times)",
                    style: GoogleFonts.lato(color: Colors.white70, fontSize: 14),
                  ),
                ),
          ],
        ),
      );
    }

    // --- RADAR CHART UI ---
    // If we have 3 or more activities, build the full RadarChart.
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Pallet.colorSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      height: 250,
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              dataEntries: topActivities
                  .map((entry) => RadarEntry(value: entry.value.toDouble()))
                  .toList(),
              borderColor: Pallet.colorPrimary,
              fillColor: Pallet.colorPrimary.withOpacity(0.4),
            ),
          ],
          radarShape: RadarShape.circle,
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: const BorderSide(color: Colors.white24, width: 1.5),
          getTitle: (index, angle) {
            if (index < topActivities.length) {
              final entry = topActivities[index];
              return RadarChartTitle(
                text: entry.key,
                angle: angle,
              );
            }
            return RadarChartTitle(text: '');
          },
          tickCount: 4,
          ticksTextStyle: const TextStyle(color: Colors.transparent),
          tickBorderData: const BorderSide(color: Colors.white24),
          gridBorderData: const BorderSide(color: Colors.white24, width: 1.5),
        ),
        swapAnimationDuration: Duration(milliseconds: 400),
      ),
    );
  }


  // --- NEW: Smart "Load More" button ---
  Widget _buildLoadMoreButton() {
    if (_isLoadingMore) {
      return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: Pallet.colorPrimary),
          ));
    }
    if (_hasMore) {
      return Center(
        child: TextButton(
          onPressed: _loadMore,
          child: Text(
            'Load More',
            style: GoogleFonts.lato(
                color: Pallet.colorPrimary, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          "You've reached the end!",
          style: GoogleFonts.lato(color: Colors.white70),
        ),
      ),
    );
  }

  // Other UI widgets (_buildStatsSection, _buildStatCard, UserActivityCard) remain the same.
  // ... (Paste the rest of your unchanged UI methods here) ...

  Widget _buildStatsSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.5,
        ),
        delegate: SliverChildListDelegate([
          _buildStatCard(Icons.sentiment_satisfied_alt, "Current Mood", _currentMood),
          _buildStatCard(Icons.celebration, "Popular Mood", _popularMood),
          _buildStatCard(Icons.directions_run, "Current Activity", _currentActivity),
          _buildStatCard(Icons.whatshot, "Popular Activity", _popularActivity),
        ]),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Pallet.colorSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(icon, color: Pallet.colorPrimary, size: 28),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.lato(fontSize: 14, color: Colors.white70)),
          Text(value, style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}



class UserActivityCard extends StatelessWidget {
  final UserActivityModel element;
  const UserActivityCard({Key? key, required this.element}) : super(key: key);

  IconData _getIconForActivity(String? type) {
    // Add icons for the new reaction types
    switch (type) {
      case 'session':
        return Icons.article_outlined;
      case 'comment':
        return Icons.comment_outlined;
    // Make all reactions use the same favorite icon
      case 'react':
      case 'Cheers👍':
      case 'Thanks💕':
      case 'Sorry🖐':
      case 'Me2🌺':
        return Icons.favorite_border; // All reactions use the heart icon
      case 'thank':
        return Icons.card_giftcard;
      case 'follow':
        return Icons.notifications_active_outlined;
      case 'game_win':
        return Icons.emoji_events_outlined;
      case 'room_join':
        return Icons.meeting_room_outlined;
      case 'visit_ego':
        return Icons.visibility_outlined;
      case 'send_love':
        return Icons.volunteer_activism_outlined;
      case 'cash_out':
        return Icons.price_check_outlined;
      case 'mantra':
        return Icons.record_voice_over_outlined;
      default:
        return Icons.timeline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final activityType = element.activityType;

        switch (activityType) {
        // Session-related activities
          case 'session':
          case 'comment':
          case 'react':
          case 'thank':
          case 'follow':
          case 'Cheers👍':
          case 'Thanks💕':
          case 'Sorry🖐':
          case 'Me2🌺':
            if (element.sessionId != null && element.sessionId!.isNotEmpty) {
              PageRouter.gotoWidget(
                  NotifiedSessionDetails(sessionId: element.sessionId!), context);
            }
            break;

        // Visit Ego activity
          case 'visit_ego':
            if (element.userId != null && element.userId!.isNotEmpty) {
              final egoName = element.userNickname ?? 'Ego';
              PageRouter.gotoWidget(
                  VisitedUserEgoProfilePage(
                      visitedUsersID: element.userId!,
                      visitedEgoName: egoName),
                  context);
            }
            break;

        // Join Room activity
          case 'room_join':
            final roomId = element.sessionId;
            if (roomId != null && roomId.isNotEmpty) {
              try {
                showToast("Opening room...");
                DocumentSnapshot roomDoc = await FirebaseFirestore.instance
                    .collection('chats')
                    .doc(roomId)
                    .get();

                if (roomDoc.exists) {
                  final chatRoom = ChatRoomPodo.fromJson(roomDoc.data() as Map<String, dynamic>);
                  PageRouter.gotoWidget(ChatScreen(chatRoomPodo: chatRoom), context);
                } else {
                  showToast("Sorry, this room could not be found.");
                }
              } catch (e) {
                print("Error navigating to room: $e");
                showToast("Could not open the room.");
              }
            }
            break;

        // Wallet-related activities
          case 'send_love':
          case 'cash_out':
            Navigator.of(context).pushNamed(AppRoutes.egoPage);
            break;

            // Default case for all other activities
          default:
            Navigator.of(context).pushNamed(AppRoutes.egoPage);
            print("Navigating to Ego Profile for activity type '$activityType'.");
            break;
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Pallet.colorSecondary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Pallet.colorSecondary.withOpacity(0.4), width: 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Pallet.colorSecondary.withOpacity(0.5),
              child: Icon(_getIconForActivity(element.activityType),
                  color: Pallet.colorPrimary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    element.activityMessage.toString(),
                    style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeConverter(element.dateCreated!),
                    style: GoogleFonts.lato(
                        fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


