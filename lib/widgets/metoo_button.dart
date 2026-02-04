import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/widgets/toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:clairediary/utils/color.dart';
import '../services/notification_service.dart';
import '../ui/featured/model/session.dart';

// The Reaction class remains the same.
class Reaction {
  final String value;
  final Widget icon;

  Reaction({
    required this.value,
    required this.icon,
  });
}

class MetooButton extends StatefulWidget {
  // The constructor is the same as your original code. No changes needed in parent files.
  final Function(Reaction, int)? onReactionChanged;
  final int? cheers;
  final int? thanks;
  final int? sorry;
  final int? me2;
  final Color color;
  final Session session;

  const MetooButton({
    Key? key,
    this.onReactionChanged,
    this.cheers,
    this.thanks,
    this.sorry,
    this.me2,
    required this.color,
    required this.session,
  }) : super(key: key);

  @override
  State<MetooButton> createState() => _MetooButtonState();
}

// The State class will now contain ALL the logic.
class _MetooButtonState extends State<MetooButton>
    with SingleTickerProviderStateMixin {
  // Services and user instance are created inside the state.
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseServices _firebaseServices = FirebaseServices();

  // --- INTERNAL STATE MANAGEMENT (The button's "memory") ---
  late Reaction selectedReaction;
  late int cheersCount;
  late int loveCount;
  late int hiFiveCount;
  late int flowerCount;
  bool hasUserReacted = false;
  int? userReactionIndex;

  // Animation and Overlay variables
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeState(); // Initialize all state variables here.

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutBack,
        ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }



  // This method sets up the button's initial state from the data it receives.
  void _initializeState() {
    // Initialize counts from the widget's properties.
    cheersCount = widget.cheers ?? 0;
    loveCount = widget.thanks ?? 0;
    hiFiveCount = widget.sorry ?? 0;
    flowerCount = widget.me2 ?? 0;

    // --- CORRECTED LOGIC ---
    // Check if the current user has reacted before.
    if (currentUser != null) {
      // The order of checks MUST match the _buildReactions() list order
      if (widget.session.meToos?.contains(currentUser!.uid) ?? false) { // Cheers👍 is now index 0
        hasUserReacted = true;
        userReactionIndex = 0;
      } else if (widget.session.meLove?.contains(currentUser!.uid) ?? false) { // Thanks💕 is index 1
        hasUserReacted = true;
        userReactionIndex = 1;
      } else if (widget.session.meHiFive?.contains(currentUser!.uid) ?? false) { // Sorry🖐 is index 2
        hasUserReacted = true;
        userReactionIndex = 2;
      } else if (widget.session.meFlower?.contains(currentUser!.uid) ?? false) { // Me2🌺 is index 3
        hasUserReacted = true;
        userReactionIndex = 3;
      }
    }

    // Determine which reaction to display initially.
    if (hasUserReacted) {
      // Safety check to prevent RangeError if userReactionIndex is null
      if (userReactionIndex != null) {
        selectedReaction = _buildReactions()[userReactionIndex!];
      } else {
        // Fallback if something goes wrong
        selectedReaction = _reactionForMood(widget.session.moodId ?? 0);
      }
    } else {
      selectedReaction = _reactionForMood(widget.session.moodId ?? 0);
    }
  }


// This is the core logic that handles the transaction and state update.
  Future<void> _handleReactionTransaction(int index) async {
    // 1. If user has already reacted, stop everything.
    if (hasUserReacted) {
      showToast("You have already reacted to this session.");
      return;
    }

    // 2. Check login status.
    if (await _firebaseServices.isUserSignIn(context) == false) return;

    final reactingUser = await _firebaseServices.getUserInfo();
    final String reactingUserId = reactingUser.userId!;
    final String sessionOwnerId = widget.session.userId!;
    const int reactionCost = 1;

    // Get the specific reaction value, e.g., 'Cheers👍'
    final Reaction selectedReaction = _buildReactions()[index];
    final String reactionValue = selectedReaction.value;

    // 3. Prevent self-reaction transactions.
    if (reactingUserId == sessionOwnerId) {
      showToast("You reacted to your own session.");
      await _firebaseServices.addUsersReactionToASession(context, reactionValue,
          session: widget.session, sender: reactingUser.nickname ?? '');

      // *** SAVE USER ACTIVITY FOR SELF-REACTION ***
      await _firebaseServices.saveUserActivity(
        activityMessage: 'You reacted with $reactionValue to your own session: "${widget.session.title}"',
        activityType: 'Self-Reaction',
        recipientId: sessionOwnerId, // The recipient is still the session owner (oneself)
        sessionId: widget.session.sessionId!,
      );
      // *** END OF ACTIVITY LOGIC ***

      _updateLocalUiState(index); // Just update the UI, no love transfer.
      return;
    }

    // 4. Check if the user has enough love.
    if (reactingUser.currentLoveCount < reactionCost) {
      showToast("You need at least 1 ❤️ to react.");
      return;
    }

    // 5. Perform the love transaction.
    final bool success = await _firebaseServices.transferLoveBetweenUsers(
      senderId: reactingUserId,
      receiverId: sessionOwnerId,
      amountToSend: reactionCost,
      taxAmount: 0, // Reactions have 0 tax
      totalDebitAmount: reactionCost,
      senderTransactionDesc: "1❤️ for reacting '${reactionValue}' to a session.",
      receiverTransactionDesc: "1❤️ from a '${reactionValue}' reaction by ${reactingUser.nickname}.",
      claireTransactionDesc: "Tax from a session reaction.",
      forReactions: reactionCost,
      fromReactions: reactionCost,
      metadata: {'sessionId': widget.session.sessionId, 'reactionIndex': index},
    );

    // 6. If the transaction is successful, log activity, send notification, update DB, and update UI.
    if (success) {
      showToast("1❤️ sent to the session owner!");

      // --- START ACTIVITY AND NOTIFICATION LOGIC ---
      try {
        // *** SAVE USER ACTIVITY FOR THE REACTION ***
        final senderName = reactingUser.nickname ?? 'Someone';
        await _firebaseServices.saveUserActivity(
          activityMessage: '$senderName reacted with $reactionValue to your session: "${widget.session.title}"',
          activityType: reactionValue,
          recipientId: sessionOwnerId,
          sessionId: widget.session.sessionId!,
        );
        // *** END OF ACTIVITY LOGIC ***

        // Get session owner's doc to find their FCM token
        final receiverDoc = await FirebaseFirestore.instance.collection('users').doc(sessionOwnerId).get();
        if (receiverDoc.exists) {
          final receiverToken = receiverDoc.data()?['fcmId'] as String?;
          final senderName = reactingUser.nickname ?? 'Someone';
          final sessionTitle = widget.session.title ?? 'your session';
          final truncatedTitle = sessionTitle.length > 30 ? sessionTitle.substring(0, 30) + '...' : sessionTitle;

          if (receiverToken != null && receiverToken.isNotEmpty) {
            await notificationService.sendNotification({
              "token": receiverToken,
              "notification": {
                "title": "Someone reacted to your session!",
                "body": "$senderName reacted with '$reactionValue' to your session: \"$truncatedTitle\""
              },
              "data": { "route": widget.session.sessionId }
            });
          }
        }
      } catch (e) {
        print("Error during post-reaction logic (activity/notification): $e");
      }
      // --- END ACTIVITY AND NOTIFICATION LOGIC ---

      // Update the reaction list in Firestore.
      await _firebaseServices.addUsersReactionToASession(context, reactionValue,
          session: widget.session, sender: reactingUser.nickname ?? '');

      // Permanently update the local UI state.
      _updateLocalUiState(index);

      // Notify the parent widget if it provided a callback.
      widget.onReactionChanged?.call(selectedReaction, _countForReaction(reactionValue));
    }
  }


  // This method tells Flutter to redraw the widget with the new, permanent state.
  void _updateLocalUiState(int index) {
    if (mounted) {
      setState(() {
        hasUserReacted = true;
        userReactionIndex = index;
        // The order of checks MUST match the _buildReactions() list order
        if (index == 0) cheersCount++; // Cheers👍
        if (index == 1) loveCount++; // Thanks💕
        if (index == 2) hiFiveCount++; // Sorry🖐
        if (index == 3) flowerCount++; // Me2🌺
        // Update the displayed reaction to the one the user just selected.
        selectedReaction = _buildReactions()[index];
      });
    }
  }

  // Builds the list of reaction widgets, now using the internal state counts.
  List<Reaction> _buildReactions() {
    // IMPORTANT: The order here dictates the index for all other logic.
    return [
      Reaction(
        value: 'Cheers👍',
        icon: Text('$cheersCount Cheers👍',
            style: GoogleFonts.lato(
                fontSize: 16,
                color: (hasUserReacted && userReactionIndex == 0)
                    ? Pallet.colorPrimary
                    : Colors.amber,
                fontWeight: FontWeight.w900)),
      ),
      Reaction(
        value: 'Thanks💕',
        icon: Text('$loveCount Thanks💕',
            style: GoogleFonts.lato(
                fontSize: 16,
                color: (hasUserReacted && userReactionIndex == 1)
                    ? Pallet.colorPrimary
                    : Colors.red,
                fontWeight: FontWeight.w900)),
      ),
      Reaction(
        value: 'Sorry🖐',
        icon: Text('$hiFiveCount Sorry🖐',
            style: GoogleFonts.lato(
                fontSize: 16,
                color: (hasUserReacted && userReactionIndex == 2)
                    ? Pallet.colorPrimary
                    : Colors.deepPurple,
                fontWeight: FontWeight.w900)),
      ),
      Reaction(
        value: 'Me2🌺',
        icon: Text('$flowerCount Me2🌺',
            style: GoogleFonts.lato(
                fontSize: 16,
                color: (hasUserReacted && userReactionIndex == 3)
                    ? Pallet.colorPrimary
                    : Colors.black,
                fontWeight: FontWeight.w900)),
      ),
    ];
  }

  // Helper methods to get initial reaction and counts.
  Reaction _reactionForMood(int moodId) {
    switch (moodId) {
      case -1: case 0: case 1: case 11: case 17: return _buildReactions()[3];
      case 2: case 5: case 6: case 8: case 9: case 10: case 12: case 13: case 14: return _buildReactions()[2];
      case 3: case 4: case 7: case 16: return _buildReactions()[0];
      default: return _buildReactions()[3];
    }
  }

  int _countForReaction(String reactionValue) {
    switch (reactionValue) {
      case 'Cheers👍': return cheersCount;
      case 'Thanks💕': return loveCount;
      case 'Sorry🖐': return hiFiveCount;
      case 'Me2🌺': return flowerCount;
      default: return 0;
    }
  }

  // The popup logic now only shows if the user has NOT already reacted.
  void _showPopup() {
    if (hasUserReacted) {
      showToast("You have already reacted to this session.");
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final position = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
                onTap: () async {
                  await _animationController.reverse();
                  _overlayEntry?.remove();
                  _overlayEntry = null;
                },
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent)),
            Positioned(
              left: position.dx,
              top: position.dy - 80,
              child: Material(
                color: Colors.transparent,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8)
                        ],
                      ),
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            children: List.generate(_buildReactions().length, (index) {
                              return GestureDetector(
                                onTap: () async {
                                  await _animationController.reverse();
                                  _overlayEntry?.remove();
                                  _overlayEntry = null;
                                  // This now calls our powerful internal handler.
                                  _handleReactionTransaction(index);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: _buildReactions()[index].icon,
                                ),
                              );
                            })),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showPopup,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _countForReaction(selectedReaction.value).toString(),
            style: GoogleFonts.lato(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            selectedReaction.value,
            style: GoogleFonts.lato(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}
