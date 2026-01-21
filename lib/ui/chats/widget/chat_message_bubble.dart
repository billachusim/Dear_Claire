import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clairediary/ui/chats/data/chats.dart'; // Import ChatModel
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/widgets/custom_image_widget.dart'; // Import for full-screen view
import 'package:clairediary/widgets/play_advise_voice_note.dart'; // Import your voice player
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';

import '../../../services/firebase_services.dart';
import '../../../services/user_model.dart';
import '../../../utils/constant.dart'; // For PageRouter

class ChatMessageBubble extends StatefulWidget {
  final ChatModel chatModel;
  final String senderName;
  final String senderAvatarUrl;
  final String timeAgo;
  final bool isMe;
  final VoidCallback onAvatarTap;
  final bool showAdminSecret;
  final VoidCallback? onDelete;

  const ChatMessageBubble({
    Key? key,
    required this.chatModel,
    required this.senderName,
    required this.senderAvatarUrl,
    required this.timeAgo,
    required this.isMe,
    required this.onAvatarTap,
    this.showAdminSecret = false,
    this.onDelete, // Initialize here
  }) : super(key: key);

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  UserModel? _currentUserModel;
  UserModel userModel = UserModel();

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }


  Future<void> _fetchCurrentUser() async {
    if (currentUser != null) {
      // 1. Fetch user data from Firestore
      var userModel = await firebaseServices.getUserInfo();

      // 2. Check if language preference is missing (for existing users)
      if (userModel.languagePreference == null || userModel.languagePreference!.isEmpty) {
        // Get device language
        final deviceLanguageCode = Platform.localeName.split('_').first;

        // Update the model in memory immediately for the UI
        userModel.languagePreference = deviceLanguageCode;

        // Asynchronously update Firestore in the background
        FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update({'languagePreference': deviceLanguageCode});

        logger.d("Updated language preference for existing user: $deviceLanguageCode");
      }

      // 3. Update the state to rebuild the widget with the correct language
      if (mounted) {
        setState(() {
          _currentUserModel = userModel;
          // Also update the existing userModel variable to ensure compatibility elsewhere in the widget
          this.userModel = userModel;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    // ... (alignment and color logic remains the same)
    final alignment = widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = widget.isMe ? Pallet.colorPrimary.withValues(alpha: 0.9) : Colors.white;
    final textColor = widget.isMe ? Colors.white : Colors.black87;
    final linkColor = widget.isMe ? Colors.yellow.shade200 : Pallet.colorPrimary;

    // --- Check for media content ---
    final bool hasAudio = widget.chatModel.audioUrl != null && widget.chatModel.audioUrl!.isNotEmpty;
    final bool hasImage1 = widget.chatModel.image1 != null && widget.chatModel.image1!.isNotEmpty;
    final bool hasImage2 = widget.chatModel.image2 != null && widget.chatModel.image2!.isNotEmpty;
    final bool hasText = widget.chatModel.message != null && widget.chatModel.message!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        // ... (Row logic with avatar remains the same)
        mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.isMe) GestureDetector(onTap: widget.onAvatarTap, child: _buildAvatar()),
          if (!widget.isMe) const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: alignment,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
                  child: Wrap( // Using wrap in case the ID makes the name too long
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        widget.senderName,
                        style: GoogleFonts.lato(fontSize: 13.0, color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                      if (widget.showAdminSecret)
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(
                            "${widget.chatModel.alterEgoId ?? ''}",
                            style: GoogleFonts.lato(fontSize: 10.0, color: Colors.white70, fontWeight: FontWeight.w400),
                          ),
                        ),
                    ],
                  ),
                ),
                // The main message bubble
                Container(
                  padding: const EdgeInsets.all(10), // Consistent padding
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: widget.isMe ? const Radius.circular(20) : const Radius.circular(0),
                      bottomRight: widget.isMe ? const Radius.circular(0) : const Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- WIDGET 1: TEXT MESSAGE ---
                      if (hasText)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                          child: Linkify(
                            onOpen: (link) async {
                              if (await canLaunchUrl(Uri.parse(link.url))) {
                                await launchUrl(Uri.parse(link.url));
                              }
                            },
                            style: GoogleFonts.lato(fontSize: 15.0, color: textColor),
                            linkStyle: TextStyle(color: linkColor, fontWeight: FontWeight.bold),
                            text: (_currentUserModel?.languagePreference != null &&
                                widget.chatModel.translatedMessage != null &&
                                widget.chatModel.translatedMessage!
                                    .containsKey(_currentUserModel!.languagePreference))
                                ? widget.chatModel.translatedMessage![_currentUserModel!.languagePreference]!
                                : widget.chatModel.message!,
                            textAlign: TextAlign.start,
                          ),
                        ),
                      // --- WIDGET 2: IMAGE DISPLAY ---
                      if (hasImage1 || hasImage2)
                        _buildImageGrid(context, hasImage1, hasImage2),

                      // --- WIDGET 2: AUDIO PLAYER ---
                      if (hasAudio)
                        PlayAdviseVoiceNote(filePath: widget.chatModel.audioUrl!),
                    ],
                  ),
                ),
                // Time ago and Delete button (Mod mode)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.timeAgo,
                          style: GoogleFonts.lato(fontSize: 11.0, color: Colors.white70)),
                      if (widget.onDelete != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: widget.onDelete,
                          child: const Icon(
                            Icons.delete_forever_rounded,
                            color: Colors.yellowAccent, // Distinct color for Mod
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Mod',
                          style: GoogleFonts.lato(
                              fontSize: 12.0,
                              color: Colors.yellowAccent,
                              fontWeight: FontWeight.w800),
                        ),
                      ]
                    ],
                  ),
                ),

              ],
            ),
          ),
          if (widget.isMe) const SizedBox(width: 10),
          if (widget.isMe) GestureDetector(onTap: widget.onAvatarTap, child: _buildAvatar()),
        ],
      ),
    );
  }

  // --- NEW: Helper widget to build the image display ---
  Widget _buildImageGrid(BuildContext context, bool hasImage1, bool hasImage2) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Make the row only as wide as its children
        children: [
          if (hasImage1)
            Expanded(child: _buildClickableImage(context, widget.chatModel.image1!)),
          if (hasImage1 && hasImage2)
            const SizedBox(width: 8),
          if (hasImage2)
            Expanded(child: _buildClickableImage(context, widget.chatModel.image2!)),
        ],
      ),
    );
  }

  Widget _buildClickableImage(BuildContext context, String imageUrl) {
    return GestureDetector(
      onTap: () {
        // Use your existing PageRouter to show the full-screen image
        PageRouter.gotoWidget(CustomImageWidget(imageUrl: imageUrl), context);
      },
      child: SizedBox(
        height: 150,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(child: CupertinoActivityIndicator()),
            errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  // Helper widget to build the user avatar
  Widget _buildAvatar() {
    // ... (This method remains exactly the same)
    return CachedNetworkImage(
      width: 40,
      height: 40,
      imageUrl: widget.senderAvatarUrl,
      imageBuilder: (context, imageProvider) => CircleAvatar(backgroundImage: imageProvider),
      placeholder: (context, url) => const CircleAvatar(child: CupertinoActivityIndicator()),
      errorWidget: (context, url, error) => const CircleAvatar(child: Icon(Icons.person)),
    );
  }
}
