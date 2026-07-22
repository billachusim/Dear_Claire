import 'dart:async';

import 'package:clairediary/ui/alter_ego/alter_ego_calls_page.dart';
import 'package:clairediary/ui/call/companion_call_page.dart';
import 'package:clairediary/ui/call/live_call_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/color.dart';
import '../../utils/constant.dart';
import '../../widgets/pre_call_dialog.dart';
import '../splash_screen/rotate_logo.dart';

class IncomingCallPage extends StatefulWidget {
  final IncomingCall call;

  const IncomingCallPage({Key? key, required this.call}) : super(key: key);

  @override
  _IncomingCallPageState createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends State<IncomingCallPage> {
  late final Stream<DocumentSnapshot> _callStream;
  StreamSubscription? _callStreamSubscription;

  @override
  void initState() {
    super.initState();
    // Start ringing as soon as the page loads
    RingtoneService.playRingtone();
    _listenToCallStatus();
  }

  void _listenToCallStatus() {
    final collectionName =
    widget.call.isVideoCall ? 'live_sessions' : 'companion_calls';
    _callStream = FirebaseFirestore.instance
        .collection(collectionName)
        .doc(widget.call.doc.id)
        .snapshots();

    // Listen for changes to the call document (e.g., if the admin cancels)
    _callStreamSubscription = _callStream.listen((snapshot) {
      if (!mounted) return;
      if (!snapshot.exists ||
          (snapshot.data() as Map<String, dynamic>)['status'] != 'dialing') {
        // If the call document is gone or the status is no longer 'dialing',
        // it means the admin cancelled. Close the page.
        _closePage();
      }
    });
  }

  @override
  void dispose() {
    RingtoneService.stopRingtone();
    _callStreamSubscription?.cancel();
    super.dispose();
  }

  void _closePage() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _acceptCall() {
    RingtoneService.stopRingtone();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final collectionName =
    widget.call.isVideoCall ? 'live_sessions' : 'companion_calls';

    // Update the status to 'connecting' to signal acceptance
    FirebaseFirestore.instance
        .collection(collectionName)
        .doc(widget.call.doc.id)
        .update({'status': 'connecting'});

    // The user needs a CallSetupDetails object. We'll create one from the incoming call.
    final callDetails = CallSetupDetails(
      title: widget.call.title,
      moodId: widget.call.moodId,
      isPrivate: (widget.call.doc.data()
      as Map<String, dynamic>)['isPrivate'] ?? true,
      repliesEnabled: (widget.call.doc.data()
      as Map<String, dynamic>)['repliesEnabled'] ?? false,
      locationEnabled: (widget.call.doc.data()
      as Map<String, dynamic>)['locationEnabled'] ?? false,
      locationData: widget.call.locationData,
    );

    // Navigate to the correct call page
    if (widget.call.isVideoCall) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LiveCallPage(
            user: currentUser,
            callDetails: callDetails,
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CompanionCallPage(
            user: currentUser,
            callDetails: callDetails,
          ),
        ),
      );
    }
  }

  void _declineCall() {
    RingtoneService.stopRingtone();
    final collectionName =
    widget.call.isVideoCall ? 'live_sessions' : 'companion_calls';

    FirebaseFirestore.instance
        .collection(collectionName)
        .doc(widget.call.doc.id)
        .update({
      'status': 'rejected',
      'endedAt': FieldValue.serverTimestamp(),
    });
    _closePage();
  }


  @override
  Widget build(BuildContext context) {
    final moodIcon = AppConstants.USER_SESSION_MOODS[widget.call.moodId];
    final hasLocation = widget.call.locationData.isNotEmpty;
    final callType =
    widget.call.isVideoCall ? "Incoming Video Call" : "Incoming Audio Call";
    final icon = widget.call.isVideoCall ? Icons.videocam : Icons.call;

    return Scaffold(
      backgroundColor: Pallet.colorSecondary,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Pallet.colorPrimary.withValues(alpha: 0.7), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Caller Info Section
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    callType,
                    style:
                    GoogleFonts.lato(color: Colors.white70, fontSize: 20),
                  ),
                  const SizedBox(height: 30),
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.white24,
                    child: RotateImage(60, 60), // Claire's rotating logo
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Claire is calling...",
                    style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // Display call details from admin
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.call.title,
                          style: GoogleFonts.lato(
                              color: Colors.white, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(moodIcon,
                                style: const TextStyle(fontSize: 20)),
                            if (hasLocation) const SizedBox(width: 12),
                            if (hasLocation)
                              Icon(Icons.location_on,
                                  color: Colors.grey.shade300, size: 16),
                            if (hasLocation) const SizedBox(width: 4),
                            if (hasLocation)
                              Text(
                                widget.call.locationData,
                                style: TextStyle(
                                    color: Colors.grey.shade300,
                                    fontSize: 14),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Action Buttons Section
            Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.call_end,
                    label: "Decline",
                    color: Colors.red.shade800,
                    onPressed: _declineCall,
                  ),
                  _buildActionButton(
                    icon: Icons.call,
                    label: "Accept",
                    color: Colors.green.shade800,
                    onPressed: _acceptCall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
        required String label,
        required Color color,
        required VoidCallback onPressed}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: CircleAvatar(
            radius: 35,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
