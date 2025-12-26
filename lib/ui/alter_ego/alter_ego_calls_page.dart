import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart' hide AudioPlayer;
import 'package:rxdart/rxdart.dart';
import 'package:vibration/vibration.dart';
import '../../utils/color.dart';
import '../../utils/constant.dart';
import '../../widgets/toast.dart';
import '../call/admin_call_page.dart';
import '../call/admin_live_call_page.dart';
import '../routes/routes.dart';
import '../splash_screen/rotate_logo.dart';

// A model to hold combined call data
class IncomingCall {
  final DocumentSnapshot doc;
  final bool isVideoCall;

  IncomingCall({required this.doc, required this.isVideoCall});

  String get title => (doc.data() as Map<String, dynamic>)['title'] ?? (isVideoCall ? "Live Session" : "Companion Call");
  String get callerId => (doc.data() as Map<String, dynamic>)['callerId'] ?? 'Unknown User';
  int get moodId => (doc.data() as Map<String, dynamic>)['moodId'] ?? 17; // Default to Claire mood
  String get locationData => (doc.data() as Map<String, dynamic>)['locationData'] ?? '';
  String get status => (doc.data() as Map<String, dynamic>)['status'] ?? 'unknown'; // Getter for status

  String get channelName => (doc.data() as Map<String, dynamic>)['channelName'];
  Timestamp get createdAt => (doc.data() as Map<String, dynamic>)['createdAt'];
}

class AlterEgoCallsPage extends StatefulWidget {
  const AlterEgoCallsPage({Key? key}) : super(key: key);

  @override
  _AlterEgoCallsPageState createState() => _AlterEgoCallsPageState();
}

class _AlterEgoCallsPageState extends State<AlterEgoCallsPage> with AutomaticKeepAliveClientMixin {
  Stream<List<IncomingCall>>? _callsStream;
  Stream<List<IncomingCall>>? _recentCallsStream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _setupCallsStream();
  }

  void _setupCallsStream() {
    final adminId = "claire_admin";

    // --- Stream for ACTIVE calls ---
    List<String> activeStatuses = ['dialing', 'ringing', 'connecting'];

    Stream<List<IncomingCall>> audioCallsStream = FirebaseFirestore.instance
        .collection('companion_calls')
        .where('receiverId', isEqualTo: adminId)
        .where('status', whereIn: activeStatuses)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => IncomingCall(doc: doc, isVideoCall: false))
        .toList());

    Stream<List<IncomingCall>> videoCallsStream = FirebaseFirestore.instance
        .collection('live_sessions')
        .where('receiverId', isEqualTo: adminId)
        .where('status', whereIn: activeStatuses)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => IncomingCall(doc: doc, isVideoCall: true))
        .toList());

    // --- Stream for RECENT calls (Ended and Missed) ---
    Stream<List<IncomingCall>> recentAudioCallsStream = FirebaseFirestore
        .instance
        .collection('companion_calls')
        .where('receiverId', isEqualTo: adminId)
        .where('status', whereIn: ['ended', 'missed']) // FIX: Query for both statuses
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => IncomingCall(doc: doc, isVideoCall: false))
        .toList());

    Stream<List<IncomingCall>> recentVideoCallsStream = FirebaseFirestore
        .instance
        .collection('live_sessions')
        .where('receiverId', isEqualTo: adminId)
        .where('status', whereIn: ['ended', 'missed']) // FIX: Query for both statuses
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => IncomingCall(doc: doc, isVideoCall: true))
        .toList());

    // --- Combine and ASSIGN streams ---
    // This is now done in initState and only once.
    _callsStream = Rx.combineLatest2(
      audioCallsStream,
      videoCallsStream,
          (List<IncomingCall> audio, List<IncomingCall> video) {
        final allCalls = [...audio, ...video];
        allCalls.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return allCalls;
      },
    );

    _recentCallsStream = Rx.combineLatest2(
      recentAudioCallsStream,
      recentVideoCallsStream,
          (List<IncomingCall> audio, List<IncomingCall> video) {
        final allCalls = [...audio, ...video];
        allCalls.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return allCalls;
      },
    );
  }

  void _acceptCall(BuildContext context, IncomingCall call) {
    RingtoneService.stopRingtone();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      Fluttertoast.showToast(msg: "Authentication error. Please restart the app.");
      return;
    }

    final collectionName = call.isVideoCall ? 'live_sessions' : 'companion_calls';

    FirebaseFirestore.instance
        .collection(collectionName)
        .doc(call.doc.id)
        .update({'status': 'connecting'});

    if (call.isVideoCall) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AdminLiveCallPage(
            user: currentUser,
            call: call,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AdminCallPage(
            user: currentUser,
            call: call,
          ),
        ),
      );
    }
  }

  void _declineCall(IncomingCall call) {
    RingtoneService.stopRingtone();
    final collectionName = call.isVideoCall ? 'live_sessions' : 'companion_calls';
    FirebaseFirestore.instance
        .collection(collectionName)
        .doc(call.doc.id)
        .update({'status': 'ended'});
  }

  // In /lib/ui/alter_ego/alter_ego_calls_page.dart

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: (){
        Navigator.of(context)
            .pushReplacementNamed(AppRoutes.alterEgoHomepage);
        showToast("Shake device or use menu to switch back to Ego Mode.");
        return Future.value(false);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Pallet.colorSecondary,
        body: CustomScrollView(
          slivers: <Widget>[
            // --- INCOMING CALLS SECTION ---
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Text(
                  "Incoming Calls",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            StreamBuilder<List<IncomingCall>>(
              stream: _callsStream, // Correct stream
              builder: (context, snapshot) {
                // --- FIX: Ringtone logic is now in the correct place ---
                if (snapshot.hasData) {
                  if (snapshot.data!.isNotEmpty) {
                    RingtoneService.playRingtone();
                  } else {
                    RingtoneService.stopRingtone();
                  }
                } else if (snapshot.connectionState != ConnectionState.waiting) {
                  RingtoneService.stopRingtone();
                }
                // --- END FIX ---

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverToBoxAdapter(child: Center(child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: RotateImage(40, 40),
                  )));
                }
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(child: Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: Colors.red))));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Text("No incoming calls", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      ),
                    ),
                  );
                }
                final calls = snapshot.data!;
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      return _buildIncomingCallCard(calls[index]); // Correct builder
                    },
                    childCount: calls.length,
                  ),
                );
              },
            ),

            // --- RECENT CALLS SECTION ---
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 40, 16, 10),
                child: Text(
                  "Recent Calls",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            StreamBuilder<List<IncomingCall>>(
              stream: _recentCallsStream, // Correct stream
              builder: (context, snapshot) {
                // Ringtone logic has been correctly removed from here.

                if (snapshot.connectionState == ConnectionState.waiting && !(snapshot.hasData)) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(child: Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: Colors.red))));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Text("No recent calls", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      ),
                    ),
                  );
                }
                final calls = snapshot.data!;
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      return _buildRecentCallCard(calls[index]); // Correct builder
                    },
                    childCount: calls.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildIncomingCallCard(IncomingCall call) {
    final icon = call.isVideoCall ? Icons.videocam : Icons.call;
    final moodIcon = Constant.USER_SESSION_MOODS[call.moodId];
    final hasLocation = call.locationData.isNotEmpty;

    return Card(
      color: Pallet.colorBottomNav,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Pallet.colorSecondary, size: 40),
        title: Text(call.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(call.isVideoCall ? "Live Session Request" : "Companion Call", style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(moodIcon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                if (hasLocation) Icon(Icons.location_on, color: Colors.grey.shade400, size: 14),
                if (hasLocation) const SizedBox(width: 4),
                if (hasLocation)
                  Expanded(child: Text(call.locationData, style: TextStyle(color: Colors.grey.shade400, fontSize: 12), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.call_end, color: Colors.red), tooltip: 'Decline', onPressed: () => _declineCall(call)),
            IconButton(icon: const Icon(Icons.call, color: Colors.green), tooltip: 'Accept', onPressed: () => _acceptCall(context, call)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCallCard(IncomingCall call) {
    final icon = call.isVideoCall ? Icons.videocam : Icons.call;
    final moodIcon = Constant.USER_SESSION_MOODS[call.moodId];
    final hasLocation = call.locationData.isNotEmpty;

    // --- Differentiate between ended and missed calls ---
    final bool isMissed = call.status == 'missed';
    final subtitleText = isMissed ? "Missed call" : "Call ended";
    final subtitleColor = isMissed ? Colors.orange.shade300 : Colors.grey.shade600;

    return Opacity(
      opacity: 0.8,
      child: Card(
        color: Pallet.colorBottomNav,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ListTile(
          leading: Icon(icon, color: Colors.grey.shade500, size: 40),
          title: Text(
            call.title,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitleText,
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 12,
                  fontStyle: isMissed ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(moodIcon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  if (hasLocation) Icon(Icons.location_on, color: Colors.grey.shade500, size: 14),
                  if (hasLocation) const SizedBox(width: 4),
                  if (hasLocation)
                    Expanded(
                      child: Text(
                        call.locationData,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
          isThreeLine: true,
          // trailing: isMissed ? IconButton(
          //   icon: Icon(Icons.phone_forwarded, color: Pallet.colorSecondary),
          //   onPressed: () { /* TODO: Implement call back logic */ },
          // ) : null,
        ),
      ),
    );
  }
}


class RingtoneService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isPlaying = false;

  static Future<void> playRingtone() async {
    if (_isPlaying) return; // Don't start if already playing

    _isPlaying = true;
    // Set the release mode to loop so the sound repeats
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    // Assuming you have a ringing.mp3 in your assets/audio/ folder
    await _audioPlayer.play(AssetSource('audio/tictactoeWin.mp3'));

    // Vibrate in a loop
    if (await Vibration.hasVibrator() ?? false) {
      // Pattern: Vibrate for 500ms, wait 1000ms, repeat
      Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 0);
    }
  }

  static Future<void> stopRingtone() async {
    if (!_isPlaying) return; // Nothing to stop

    await _audioPlayer.stop();
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.cancel();
    }
    _isPlaying = false;
  }
}

