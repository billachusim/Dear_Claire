import 'dart:async';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:clairediary/services/user_activity_model.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/ui/splash_screen/rotate_logo.dart';
import 'package:clairediary/utils/mood.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get_utils/src/extensions/string_extensions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_model.dart';
import '../../utils/constant.dart';
import '../../widgets/toast.dart';
import '../chats/inside_chatroom.dart';
import '../featured/notified_session_details.dart';
import '../visited_user_ego_page/visited_user_ego_page.dart';
import 'package:clairediary/ui/chats/data/roomdata.dart';
import 'package:clairediary/ui/alter_ego/alter_ego_room_data.dart';
import 'package:clairediary/ui/chats/widget/inside_alter_ego_diaryroom.dart';

class ActivityWidget extends StatefulWidget {
  final String userId;
  const ActivityWidget({Key? key, required this.userId}) : super(key: key);

  @override
  State<ActivityWidget> createState() => _ActivityWidgetState();
}

class _ActivityWidgetState extends State<ActivityWidget> with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _moodPulseController;
  List<UserActivityModel> _activities = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final int _limit = 20;
  Timer? _vibeDebounce;

  // --- STATE FOR ANALYSIS ---
  String _currentMood = 'Not Available';
  String _popularMood = 'Not Available';
  String _currentActivity = 'Not Available';
  String _popularActivity = 'Not Available';
  Map<String, int> _activityCounts = {};
  late final AnimationController _chartPulseController;
  bool _isChartTapped = false;


  @override
  void initState() {
    super.initState();
    _fetchInitialData();

    _moodPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _chartPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _moodPulseController.dispose();
    _chartPulseController.dispose();
    _vibeDebounce?.cancel();
    super.dispose();
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

    // --- 1. Analyze Activities (Existing Logic) ---
    activities.sort((a, b) => b.dateCreated!.compareTo(a.dateCreated!));
    _currentActivity = _formatActivityType(activities.first.activityType);

    final userPerformedActivities = activities
        .where((act) => act.clientId == widget.userId)
        .toList();

    _activityCounts =
        groupBy(userPerformedActivities, (UserActivityModel act) => act.activityType!)
            .map((key, value) => MapEntry(_formatActivityType(key), value.length));

    if (_activityCounts.isNotEmpty) {
      _popularActivity =
          _activityCounts.entries.sortedBy<num>((e) => -e.value).first.key;
    } else {
      _popularActivity = 'Not Available';
    }

    // --- 2. NEW Mood Analysis Logic (Using UserModel moods array) ---
    try {
      // Fetch user info directly to get the persistent moods array
      UserModel? user = await firebaseServices.getUserInfo();

      if (user.moods.isNotEmpty) {
        // Current Mood: The most recently added mood (last item in the array)
        _currentMood = Mood.getMood(user.moods.last) ?? 'Not Available';

        // Popular Mood: The mode (most frequent) mood in the history
        var counts = <int, int>{};
        for (var moodId in user.moods) {
          counts[moodId] = (counts[moodId] ?? 0) + 1;
        }

        // Sort by frequency descending and pick the top one
        final popularMoodId = counts.entries
            .sortedBy<num>((e) => -e.value)
            .first.key;

        _popularMood = Mood.getMood(popularMoodId) ?? 'Not Available';
      } else {
        _currentMood = 'Not Available';
        _popularMood = 'Not Available';
      }
    } catch (e) {
      print("Error analyzing moods from user model: $e");
      _currentMood = 'Not Available';
      _popularMood = 'Not Available';
    }

    if (mounted) {
      setState(() {});
      // Trigger the emoji flood once analysis is complete and mood is set
      if (_currentMood != 'Not Available') {
        _triggerMoodConfetti();
      }
    }
  }

  // Your formatting function remains the same
  String _formatActivityType(String? type) {
    if (type == null) return 'Weird';
    switch (type) {
      case 'session': return 'Diary Session';
      case 'comment': return 'Advising';
      case 'react': return 'Reacting';
      case 'thank': return 'Thanksgiving';
      case 'follow': return 'Following';
      case 'game_win': return 'Winning Games';
      case 'room_join': return 'Joining Rooms';
      case 'visit_ego': return 'Visiting Ego';
      case 'send_love': return 'Sending Love';
      case 'cash_out': return 'Cashing Out';
      case 'mantra': return 'Whispering Mantra';
      case 'monitor': return 'Monitoring Spirit';
      case 'dm_reply': return 'Replying DMs';


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

  String _formatActivityTypeAsActor(String? type) {
    if (type == null) return 'Weird';
    // First, reverse the descriptive format to its original type if possible.
    // This makes the switch case simpler.
    String originalType = type;
    final formattedMap = {
      'Diary Session': 'session',
      'Advising': 'comment',
      'Reacting': 'react',
      'Thanksgiving': 'thank',
      'Following': 'follow',
      'Winning Games': 'game_win',
      'Joining Rooms': 'room_join',
      'Visiting Ego': 'visit_ego',
      'Sending Love': 'send_love',
      'Cashing Out': 'cash_out',
      'Whispering Mantra': 'mantra',
      'Monitoring Spirit': 'monitor',
      'Replying DMs': 'dm_reply',
    };

    // This lookup helps if the popular activity is already in descriptive format.
    if (formattedMap.containsKey(type)) {
      originalType = formattedMap[type]!;
    } else if (type.contains('👍') || type.contains('💕') || type.contains('🖐') || type.contains('🌺')) {
      originalType = 'react';
    }


    switch (originalType) {
      case 'session': return 'Writer';
      case 'comment': return 'Advisor';
      case 'react': return 'Reactor';
      case 'thank': return 'Thanker';
      case 'follow': return 'Follower';
      case 'game_win': return 'Winner';
      case 'room_join': return 'Socializer';
      case 'visit_ego': return 'Visitor';
      case 'send_love': return 'Admirer';
      case 'cash_out': return 'Earner';
      case 'mantra': return 'Whisperer';
      case 'monitor': return 'Spirit';
      case 'dm_reply': return 'Responder';
      default:
      // Fallback for any types not covered.
        return type.replaceAll('_', ' ').split(' ').map((str) => str.isNotEmpty ? str[0].toUpperCase() + str.substring(1) : '').join(' ');
    }
  }


  Map<String, String> _getCharacterStory(String actorType) {
    // Base path for character images
    const String basePath = 'assets/images/';

    switch (actorType) {
      case 'Writer':
        return {
          'title': 'The Chronicler',
          'story': 'In the quiet moments, you pick up your pen. You are the keeper of memories, the weaver of narratives. Each entry is a thread in the grand tapestry of your life, creating a legacy one word at a time.',
          'imagePath': '${basePath}alter_ego_slide_3.png',
        };
      case 'Advisor':
        return {
          'title': 'The Sage',
          'story': 'Wisdom flows from you. Others seek your counsel, and you provide it with grace and insight. You are a guiding light in the fog, helping others find their way with a steady hand and a thoughtful word.',
          'imagePath': '${basePath}herpower.png',
        };
      case 'Reactor':
        return {
          'title': 'The Empath',
          'story': 'You feel the world around you, connecting with others on a visceral level. A nod, a smile, a shared tear—you are the heartbeat of the community, reflecting its joys and sorrows and making everyone feel seen.',
          'imagePath': '${basePath}ic_two_ladies.png',
        };
      case 'Thanker':
        return {
          'title': 'The Grateful Heart',
          'story': 'You walk a path of gratitude, recognizing the light in others. Your thanks are not just words but affirmations, spreading warmth and encouraging kindness wherever you go. You are a beacon of positivity.',
          'imagePath': '${basePath}standgirls.png',
        };
      case 'Follower':
        return {
          'title': 'The Pathfinder',
          'story': 'Curiosity is your compass. You seek out new voices and stories, forging connections and broadening your horizons. By following others, you chart new territories for yourself and discover worlds unknown.',
          'imagePath': '${basePath}WalkGirls.jpeg',
        };
      case 'Winner':
        return {
          'title': 'The Champion',
          'story': 'You rise to the challenge, your spirit fueled by competition. Victory isn\'t just about the prize; it\'s about the thrill of the game and the discipline it takes to succeed. You are a testament to perseverance.',
          'imagePath': '${basePath}spaceShooter.png',
        };
      case 'Socializer':
        return {
          'title': 'The Gatherer',
          'story': 'You thrive in the company of others, a natural hub of connection. You enter new spaces with an open heart, bringing people together and turning strangers into friends. The world is your living room.',
          'imagePath': '${basePath}herpower.png',
        };
      case 'Visitor':
        return {
          'title': 'The Explorer',
          'story': 'Driven by a desire to understand, you journey into the lives of others. You are a respectful observer, learning from their worlds and leaving a quiet mark of connection. Every visit is a new discovery.',
          'imagePath': '${basePath}alter_ego_slide_3.png',
        };
      case 'Admirer':
        return {
          'title': 'The Beacon',
          'story': 'You see the good in others and reflect it back to them. Your admiration is a powerful force, a silent encouragement that uplifts and inspires. You spread light without needing a spotlight.',
          'imagePath': '${basePath}iconWhitePetal.png',
        };
      case 'Earner':
        return {
          'title': 'The Harvester',
          'story': 'You understand the value of effort and reward. With strategic thinking and patience, you turn your actions into tangible success. You are the architect of your own prosperity.',
          'imagePath': '${basePath}alter_ego_slide_2.png',
        };
      case 'Whisperer':
        return {
          'title': 'The Oracle',
          'story': 'You speak quiet truths to your own soul. Your mantras are seeds of intention, shaping your inner world with focus and power. You are the master of your own subconscious, whispering your destiny into existence.',
          'imagePath': '${basePath}alter_ego_slide_1.png',
        };
      case 'Spirit':
        return {
          'title': 'The Guardian',
          'story': 'You are a watchful presence, attuned to the subtle energies around you. You observe, you protect, and you understand the unseen forces that shape your journey. You are the silent keeper of your own peace.',
          'imagePath': '${basePath}alter_ego_slide_4.png',
        };
      case 'Responder':
        return {
          'title': 'The Bridge',
          'story': 'You close the distance between people. A thoughtful reply, a quick clarification—you are the essential link in the chain of conversation, ensuring no one is left unheard and every connection is valued.',
          'imagePath': '${basePath}Speak_No_Evil_Monkey_Emoji.png',
        };
      default:
        return {
          'title': 'The Enigma',
          'story': 'Your path is unique, marked by actions that defy simple labels. You are a mysterious and unpredictable force, constantly evolving. Your story is still being written.',
          'imagePath': '${basePath}icon.jpeg', // A default image
        };
    }
  }


  void _showCharacterStoryPopup(String actorType) {
    final storyData = _getCharacterStory(actorType);
    final String title = storyData['title']!;
    final String story = storyData['story']!;
    final String imagePath = storyData['imagePath']!;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: Pallet.colorBlack.withValues(alpha: 0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1),
            ),
            // We remove padding to let the image go to the edges
            titlePadding: const EdgeInsets.only(top: 24, bottom: 12),
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actionsPadding: const EdgeInsets.only(bottom: 12),

            title: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            content: SingleChildScrollView( // Added for safety on small screens
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Image.asset(
                      imagePath,
                      height: 180,
                      fit: BoxFit.cover,
                      // Error handling for missing assets
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: Colors.grey[800],
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    story,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'CLOSE',
                  style: GoogleFonts.plusJakartaSans(
                    color: Pallet.colorPink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
            actionsAlignment: MainAxisAlignment.center,
          ),
        );
      },
    );
  }



  Map<String, String> _getMoodStory(String popularMood) {
    // Clean the mood string to remove the "is " prefix and the emoji for matching.
    final cleanMood = popularMood.replaceAll(RegExp(r'is |\p{Emoji}', unicode: true), '').trim();

    switch (cleanMood) {
      case 'happy':
        return {
          'title': 'The Sunshine State',
          'story': 'Your predominant emotional state is one of contentment and brightness. This suggests a resilient and optimistic outlook, where you consistently find or create moments of joy. Your emotional center is anchored in positivity.'
        };
      case 'sad':
        return {
          'title': 'The Reflective Soul',
          'story': 'A tendency towards sadness indicates a deeply empathetic and reflective nature. You are in tune with life\'s poignant moments, suggesting a capacity for profound emotional depth and sensitivity. This is often the soil from which wisdom grows.'
        };
      case 'excited':
        return {
          'title': 'The Spark of Energy',
          'story': 'Excitement is your baseline, revealing a spirit charged with anticipation and enthusiasm. This pattern points to a forward-looking and passionate personality, one that thrives on new ideas and the promise of what\'s to come.'
        };
      case 'in love':
        return {
          'title': 'The Connected Heart',
          'story': 'A persistent state of love signifies a powerful capacity for connection, affection, and intimacy. Your emotional landscape is defined by warmth and a deep appreciation for others, making you a source of positive relational energy.'
        };
      case 'out of love':
        return {
          'title': 'The Healing Phase',
          'story': 'Frequently feeling out of love suggests you are in a period of emotional recalibration. This is a state of introspection and self-preservation, indicating a necessary process of healing and redefining personal boundaries.'
        };
      case 'depressed':
        return {
          'title': 'The Heavy Sky',
          'story': 'A recurring pattern of depressive feelings points to a significant emotional weight. This is a state of persistent low energy and introspection. Recognizing this pattern is the first, most crucial step toward seeking balance and light.'
        };
      case 'motivated':
        return {
          'title': 'The Inner Drive',
          'story': 'Motivation is your dominant emotional current. This reveals a goal-oriented and proactive mindset, where your energy is consistently channeled towards achievement and self-improvement. You are an engine of progress.'
        };
      case 'anxious':
        return {
          'title': 'The Vigilant Mind',
          'story': 'A recurring state of anxiety suggests a highly alert and forward-thinking mind, constantly scanning for future possibilities. While exhausting, this pattern also indicates a deep sense of responsibility and a desire to be prepared.'
        };
      case 'gingered':
        return {
          'title': 'The Fired-Up Spirit',
          'story': 'Your system is consistently charged with high-octane energy and zeal. This "gingered" state points to a passionate, driven personality that attacks goals with vigor and inspires action in others. Your default mode is "go".'
        };
      case 'so Claire':
        return {
          'title': 'A State of Grace',
          'story': 'To be "so Claire" is to exist in a state of self-aware harmony. This pattern suggests you are in tune with your core self, embracing your journey with authenticity, wisdom, and a touch of floral elegance. It is your unique state of being.'
        };
      default:
        return {
          'title': 'A Complex Pattern',
          'story': 'Your dominant mood, "${cleanMood.capitalizeFirst}", is a unique emotional signature. It reflects a complex inner world, and observing it is key to understanding the central themes of your current life chapter.'
        };
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
        SliverToBoxAdapter(child:
        _buildImmersiveChart()
        ),
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

    BoxDecoration glassDecoration() => BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Pallet.colorPrimary.withValues(alpha: 0.9),
          Pallet.colorSecondary.withValues(alpha: 0.1),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.2),
        width: 1.5,
      ),
    );

    // --- FALLBACK UI (Texts are already white) ---
    if (topActivities.length < 3) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: glassDecoration(),
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
                  if (topActivities.isEmpty)
                    Text(
                      "No activities with distinct types found yet.",
                      style: GoogleFonts.lato(color: Colors.white70, fontSize: 14),
                    )
                  else
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
            ),
          ),
        ),
      );
    }

    // --- ENHANCED IMMERSIVE RADAR CHART ---
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTapDown: (_) async {
          await _audioPlayer.play(AssetSource('audio/beep-329314.mp3'));
          HapticFeedback.lightImpact();
          setState(() => _isChartTapped = true);
        },
        onTapUp: (_) => Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _isChartTapped = false);
        }),
        onTapCancel: () => Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _isChartTapped = false);
        }),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: glassDecoration(),
              height: 250,
              child: AnimatedBuilder(
                animation: _chartPulseController,
                builder: (context, child) {
                  return RadarChart(
                    RadarChartData(
                      titleTextStyle: GoogleFonts.lato(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      dataSets: [
                        RadarDataSet(
                          dataEntries: topActivities
                              .map((entry) =>
                              RadarEntry(value: entry.value.toDouble()))
                              .toList(),
                          borderColor: _isChartTapped
                              ? Pallet.colorWhite.withValues(alpha: 0.8)
                              : Colors.white,
                          borderWidth: _isChartTapped ? 15 : 2.0,
                          fillColor: Colors.white.withValues(alpha:
                            0.2 + (_chartPulseController.value * 0.60),
                          ),
                        ),
                      ],
                      radarShape: RadarShape.circle,
                      radarBackgroundColor: Colors.transparent,
                      borderData: FlBorderData(show: false),
                      radarBorderData:
                      const BorderSide(color: Colors.white24, width: 1.5),
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
                      gridBorderData:
                      const BorderSide(color: Colors.white24, width: 1.5),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 400),
                  );
                },
              ),
            ),
          ),
        ),
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

  // Helper to separate text from emoji
  Map<String, String> _splitMood(String moodText) {
    if (moodText == 'Not Available' || moodText.isEmpty) {
      return {'text': moodText, 'emoji': ''};
    }

    // Emojis are usually at the end. This splits the string before the last emoji character.
    final regex = RegExp(r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])');
    final match = regex.allMatches(moodText).lastOrNull;

    if (match != null) {
      return {
        'text': moodText.substring(0, match.start).trim(),
        'emoji': moodText.substring(match.start).trim(),
      };
    }
    return {'text': moodText, 'emoji': ''};
  }


  Widget _buildStatsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                child: _statCard(
                  title: "Vibe Check",
                  value: _currentMood,
                  subtitle: "Current Mood",
                  icon: Icons.auto_awesome_outlined,
                  color: Colors.green,
                  pulseAnimation: _moodPulseController,
                  onTap: () async {
                    await _audioPlayer.play(AssetSource('audio/beep-329314.mp3'));
                    HapticFeedback.lightImpact();
                    _triggerMoodConfetti();
                    if (_vibeDebounce?.isActive ?? false) _vibeDebounce!.cancel();
                    _vibeDebounce = Timer(const Duration(seconds: 3), () {
                      if (mounted) {
                        _showMoodUpdateModal();
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  title: "Mood Swing",
                  value: _popularMood,
                  subtitle: "Observed Pattern",
                  icon: Icons.psychology_outlined,
                  color: Colors.green,
                  pulseAnimation: _moodPulseController,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showMoodSwingInfo(); // New Popup
                  },
                ),
              ),
            ],
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    title: "Latest Action",
                    value: _currentActivity,
                    subtitle: "Fresh Activity",
                    icon: Icons.bolt_rounded,
                    color: Colors.pinkAccent,
                    onTap: () async {
                      HapticFeedback.lightImpact();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    title: "Main Character",
                    value: _formatActivityTypeAsActor(_popularActivity),
                    subtitle: "Top Pursuit",
                    icon: Icons.star_outline_rounded,
                    color: Colors.pinkAccent,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      final actorType = _formatActivityTypeAsActor(_popularActivity);
                      _showCharacterStoryPopup(actorType);
                    },
                  ),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    Animation<double>? pulseAnimation,
    VoidCallback? onTap,
  }) {
    final moodParts = _splitMood(value);
    final bool hasEmoji = moodParts['emoji']!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Colors.white54,
                  ),
                ),
                Icon(icon, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.white, color.withValues(alpha: 0.5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      hasEmoji ? moodParts['text']! : value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, // Slightly larger
                        fontWeight: FontWeight.w800, // Extra bold for that premium look
                        color: Colors.white, // Required for ShaderMask
                      ),
                    ),
                  ),

                ),
                if (hasEmoji && pulseAnimation != null)
                  AnimatedBuilder(
                    animation: pulseAnimation,
                    builder: (context, child) {
                      // Map 0.0-1.0 to 0.9-1.2 for scale
                      double scale = 0.9 + (pulseAnimation.value * 0.3);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4 * pulseAnimation.value),
                                blurRadius: 15 * scale,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            moodParts['emoji']!,
                            style: const TextStyle(fontSize: 28), // Bigger emoji
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: color.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showMoodUpdateModal() {
    String localSelectedMood = AppConstants.USER_SESSION_MOODS.first;
    String currentMoodText = _splitMood(_currentMood)['text'] ?? 'Available';
    bool isUpdating = false; // State variable for loading

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Pallet.colorSecondary.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text("Update your Vibe", style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                "Your last vibe check $currentMoodText. Would you like to update your mood?",
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(color: Colors.white70),
              ),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white38)),
                child: DropdownButton<String>(
                  value: localSelectedMood,
                  isExpanded: true,
                  dropdownColor: Pallet.colorSecondary,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: GoogleFonts.lato(fontSize: 16, color: Colors.white),
                  items: AppConstants.USER_SESSION_MOODS.map((String v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                  onChanged: (v) => setModalState(() => localSelectedMood = v!),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Still $currentMoodText", style: GoogleFonts.lato(color: Colors.white60)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Pallet.colorPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: isUpdating ? null : () async {
                        setModalState(() => isUpdating = true); // Start loading

                        int moodId = AppConstants.USER_SESSION_MOODS.indexOf(localSelectedMood);
                        await firebaseServices.updateUserMoods(moodId);

                        if (mounted) {
                          Navigator.pop(context); // Close modal
                        }

                        await _fetchInitialData(); // Refresh data
                        showToast("Mood updated!");

                      },
                      child: isUpdating
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text("Update", style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showMoodSwingInfo() {
    // Get the story based on the most popular mood.
    final moodStoryData = _getMoodStory(_popularMood);
    final title = moodStoryData['title']!;
    final story = moodStoryData['story']!;

    // Use the helper to get the emoji from the popular mood string
    final moodParts = _splitMood(_popularMood);
    final emoji = moodParts['emoji']!.isNotEmpty ? moodParts['emoji'] : '✨'; // Fallback emoji

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Pallet.colorSecondary.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1),
          ),
          // Adjust padding to accommodate the new layout
          titlePadding: const EdgeInsets.only(top: 16),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          actionsPadding: const EdgeInsets.only(bottom: 12),

          title: Column(
            children: [
              // Glowing Emoji
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Pallet.colorPrimary.withValues(alpha: 0.7),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Text(
                  emoji!,
                  style: const TextStyle(fontSize: 60),
                ),
              ),
              const SizedBox(height: 16),
              // Original Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          content: Text(
            story,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "GOT IT",
                style: GoogleFonts.plusJakartaSans(
                  color: Pallet.colorPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
          actionsAlignment: MainAxisAlignment.center,
        ),
      ),
    );
  }





  void _triggerMoodConfetti() {
    final moodData = _splitMood(_currentMood);
    final emoji = moodData['emoji'] ?? '✨'; // Fallback if no emoji found

    if (emoji.isEmpty) return;

    // Configuration for "Flooding" from the bottom edges
    final options = ConfettiOptions(
      particleCount: 25,
      spread: 70,
      startVelocity: 40,
      gravity: 0.8, // Slightly heavy so they "settle" or fall back down
      ticks: 300,   // How long they stay on screen
      colors: [const Color(0xffffffff)], // Base color
    );

    // Launch from Bottom Left
    Confetti.launch(
      context,
      options: options.copyWith(x: 0.1, y: 1.0, angle: 60),
      // Use 'Emoji' class from the flutter_confetti package
      particleBuilder: (index) => Emoji(
        emoji: emoji,
        textStyle: const TextStyle(fontSize: 30),
      ),
    );

    // Launch from Bottom Right
    Confetti.launch(
      context,
      options: options.copyWith(x: 0.9, y: 1.0, angle: 120),
      // Use 'Emoji' class from the flutter_confetti package
      particleBuilder: (index) => Emoji(
        emoji: emoji,
        textStyle: const TextStyle(fontSize: 30),
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
      case 'self_reaction':
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
        return Icons.person;
      case 'send_love':
        return Icons.volunteer_activism_outlined;
      case 'cash_out':
        return Icons.price_check_outlined;
      case 'mantra':
        return Icons.record_voice_over_outlined;
      case 'monitor':
        return Icons.visibility_outlined;
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
          case 'monitor':
            if (element.sessionId != null && element.sessionId!.isNotEmpty) {
              PageRouter.gotoWidget(
                  NotifiedSessionDetails(sessionId: element.sessionId!), context);
            }
            break;

          case 'session':
          case 'comment':
          case 'react':
          case 'self_reaction':
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

        // --- FINAL, FULLY CORRECTED 'Join Room' activity ---
          case 'room_join':
            final roomIdString = element.sessionId;
            if (roomIdString != null && roomIdString.isNotEmpty) {
              showToast("Opening room...");

              final int? roomId = int.tryParse(roomIdString);
              if (roomId == null) {
                showToast("Invalid room ID.");
                break;
              }

              // --- NEW LOGIC: Differentiate based on the specific Alter Ego IDs ---
              if (roomId == 6 || roomId == 7 || roomId == 8) {
                // --- It's an ALTER EGO room ---
                // Search the static list for Alter Ego rooms
                final room = AlterEgoRoomData.room()
                    .firstWhereOrNull((r) => r.id == roomId);

                if (room != null) {
                  PageRouter.gotoWidget(
                      AlterEgoChatScreen(chatRoomPodo: room), context);
                } else {
                  showToast("Sorry, this Alter Ego room could not be found.");
                }

              } else {
                // --- It's a NORMAL (Ego Mode) room ---
                // Search the static list for normal rooms
                final room = RoomData.room()
                    .firstWhereOrNull((r) => r.id == roomId);

                if (room != null) {
                  PageRouter.gotoWidget(ChatScreen(chatRoomPodo: room), context);
                } else {
                  showToast("Sorry, this Diary Room could not be found.");
                }
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
          color: Pallet.colorSecondary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Pallet.colorSecondary.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Pallet.colorSecondary.withValues(alpha: 0.5),
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


