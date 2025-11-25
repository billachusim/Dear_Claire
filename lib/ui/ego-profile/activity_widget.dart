import 'package:clairediary/services/user_activity_model.dart';
import 'package:clairediary/ui/featured/model/session.dart';
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

import '../../services/firebase_services.dart';
import '../../utils/constant.dart';
import '../featured/notified_session_details.dart';

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

  // --- 1. SMART PAGINATION: Fetch initial data ---
  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);

    // Fetch the first page of activities using our new paginated method
    final activityData = await firebaseServices.getActivityForUser(
      userId: widget.userId,
      limit: _limit,
    );

    // Save the state for the next page
    _lastDocument = activityData.lastDocument;
    _activities = activityData.activities;
    _hasMore = _activities.length == _limit;

    // Run analysis on the first batch to populate stats quickly
    await _runAnalysisOnData(_activities);

    setState(() => _isLoading = false);
  }

  // --- 2. SMART PAGINATION: Fetch more data when "Load More" is pressed ---
  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    final activityData = await firebaseServices.getActivityForUser(
      userId: widget.userId,
      limit: _limit,
      startAfter: _lastDocument,
    );

    _lastDocument = activityData.lastDocument;
    final newActivities = activityData.activities;
    _hasMore = newActivities.length == _limit;

    setState(() {
      _activities.addAll(newActivities);
      // Re-run analysis with the newly added activities
      _runAnalysisOnData(_activities);
      _isLoadingMore = false;
    });
  }

  // --- MODIFIED: Analysis logic now runs on the current set of activities ---
  Future<void> _runAnalysisOnData(List<UserActivityModel> activities) async {
    if (activities.isEmpty) return;

    final sessionIds = activities
        .where((act) => act.sessionId != null && act.sessionId!.isNotEmpty)
        .map((act) => act.sessionId!)
        .toSet()
        .toList();

    // Use our new efficient method to get session details
    final sessions = await firebaseServices.getSessionsByIds(sessionIds);
    final sessionMap = {for (var s in sessions) s.sessionId!: s};

    // 1. Analyze Activities
    activities.sort((a, b) => b.dateCreated!.compareTo(a.dateCreated!));
    _currentActivity = _formatActivityType(activities.first.activityType);
    _activityCounts =
        groupBy(activities, (UserActivityModel act) => act.activityType!)
            .map((key, value) => MapEntry(_formatActivityType(key), value.length));

    if (_activityCounts.isNotEmpty) {
      _popularActivity =
          _activityCounts.entries.sortedBy<num>((e) => -e.value).first.key;
    }

    // 2. Analyze Moods
    final sessionActivities = activities
        .where((act) =>
    act.activityType == 'session' &&
        act.sessionId != null &&
        sessionMap.containsKey(act.sessionId))
        .toList();

    if (sessionActivities.isNotEmpty) {
      final currentSession = sessionMap[sessionActivities.first.sessionId];
      if (currentSession != null && currentSession.moodId != null) {
        _currentMood = Mood.getMood(currentSession.moodId) ?? 'Unknown';
      }

      final moodGroups =
      groupBy(sessionActivities, (act) => sessionMap[act.sessionId]?.moodId);

      Map<int, int> validMoodCounts = {};
      moodGroups.forEach((moodId, acts) {
        if (moodId != null) {
          validMoodCounts[moodId] = acts.length;
        }
      });

      if (validMoodCounts.isNotEmpty) {
        final popularMoodId =
            validMoodCounts.entries.sortedBy<num>((e) => -e.value).first.key;
        _popularMood = Mood.getMood(popularMoodId) ?? 'Unknown';
      }
    }
  }

  // This is your own excellent formatting function, unchanged
  String _formatActivityType(String? type) {
    if (type == null) return 'Unknown';
    switch (type) {
      case 'session':
        return 'Sharing Diary';
      case 'comment':
        return 'Advising';
      case 'react':
        return 'Reacting';
      case 'thank':
        return 'Giving Thanks';
      case 'follow':
        return 'Following';
      case 'game_win':
        return 'Winning Games';
      case 'room_join':
        return 'Joining Rooms';
      default:
        return type
            .replaceAll('_', ' ')
            .split(' ')
            .map((str) =>
        str.isNotEmpty ? str[0].toUpperCase() + str.substring(1) : '')
            .join(' ');
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
            style: GoogleFonts.lato(
                fontSize: 16.0, color: Colors.white70)),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildImmersiveChart()), // <-- NEW IMMERSIVE CHART
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
          child: _buildLoadMoreButton(), // <-- NEW PAGINATION BUTTON
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  // --- NEW: Immersive Radar Chart replacing the old Bar Chart ---
  Widget _buildImmersiveChart() {
    final top5Activities = _activityCounts.entries
        .sortedBy<num>((e) => -e.value)
        .take(5)
        .toList();

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
              dataEntries: top5Activities
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
            if (index < top5Activities.length) {
              final entry = top5Activities[index];
              return RadarChartTitle(
                text: entry.key, // FULL TEXT is displayed clearly
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

  // --- Unchanged Widgets (included for completeness) ---

  Widget _buildStatsSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
        ),
        delegate: SliverChildListDelegate([
          _buildStatCard(
              Icons.sentiment_satisfied_alt, "Current Mood", _currentMood),
          _buildStatCard(Icons.celebration, "Popular Mood", _popularMood),
          _buildStatCard(
              Icons.directions_run, "Current Activity", _currentActivity),
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
          Text(title,
              style: GoogleFonts.lato(fontSize: 14, color: Colors.white70)),
          Text(value,
              style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// Your UserActivityCard is already great, no changes needed here.
class UserActivityCard extends StatelessWidget {
  final UserActivityModel element;
  const UserActivityCard({Key? key, required this.element}) : super(key: key);

  IconData _getIconForActivity(String? type) {
    switch (type) {
      case 'session':
        return Icons.article_outlined;
      case 'comment':
        return Icons.comment_outlined;
      case 'react':
        return Icons.favorite_border;
      case 'thank':
        return Icons.card_giftcard;
      case 'follow':
        return Icons.notifications_active_outlined;
      case 'game_win':
        return Icons.emoji_events_outlined;
      case 'room_join':
        return Icons.meeting_room_outlined;
      default:
        return Icons.timeline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (element.sessionId != null && element.sessionId!.isNotEmpty) {
          PageRouter.gotoWidget(
              NotifiedSessionDetails(sessionId: element.sessionId), context);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Pallet.colorSecondary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
          border:
          Border.all(color: Pallet.colorSecondary.withOpacity(0.4), width: 1),
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
