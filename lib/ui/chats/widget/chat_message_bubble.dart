import 'package:cached_network_image/cached_network_image.dart';
import 'package:clairediary/ui/chats/data/chats.dart'; // Import ChatModel
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/widgets/custom_image_widget.dart'; // Import for full-screen view
import 'package:clairediary/widgets/play_advise_voice_note.dart'; // Import your voice player
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart'; // For PageRouter

class ChatMessageBubble extends StatelessWidget {
  final ChatModel chatModel;
  final String senderName;
  final String senderAvatarUrl;
  final String timeAgo;
  final bool isMe;
  final VoidCallback onAvatarTap;
  final bool showAdminSecret;
  final VoidCallback? onDelete; // Added optional delete callback

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
  Widget build(BuildContext context) {
    // ... (alignment and color logic remains the same)
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isMe ? Pallet.colorPrimary.withValues(alpha: 0.9) : Colors.white;
    final textColor = isMe ? Colors.white : Colors.black87;
    final linkColor = isMe ? Colors.yellow.shade200 : Pallet.colorPrimary;

    // --- Check for media content ---
    final bool hasAudio = chatModel.audioUrl != null && chatModel.audioUrl!.isNotEmpty;
    final bool hasImage1 = chatModel.image1 != null && chatModel.image1!.isNotEmpty;
    final bool hasImage2 = chatModel.image2 != null && chatModel.image2!.isNotEmpty;
    final bool hasText = chatModel.message != null && chatModel.message!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        // ... (Row logic with avatar remains the same)
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) GestureDetector(onTap: onAvatarTap, child: _buildAvatar()),
          if (!isMe) const SizedBox(width: 10),
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
                        senderName,
                        style: GoogleFonts.lato(fontSize: 13.0, color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                      if (showAdminSecret)
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(
                            "${chatModel.alterEgoId ?? ''}",
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
                      bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
                      bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
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
                            text: chatModel.message!,
                            style: GoogleFonts.lato(fontSize: 15.0, color: textColor),
                            linkStyle: TextStyle(color: linkColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      // --- WIDGET 2: IMAGE DISPLAY ---
                      if (hasImage1 || hasImage2)
                        _buildImageGrid(context, hasImage1, hasImage2),

                      // --- WIDGET 2: AUDIO PLAYER ---
                      if (hasAudio)
                        PlayAdviseVoiceNote(filePath: chatModel.audioUrl!),
                    ],
                  ),
                ),
                // Time ago and Delete button (Mod mode)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(timeAgo,
                          style: GoogleFonts.lato(fontSize: 11.0, color: Colors.white70)),
                      if (onDelete != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onDelete,
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
          if (isMe) const SizedBox(width: 10),
          if (isMe) GestureDetector(onTap: onAvatarTap, child: _buildAvatar()),
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
            Expanded(child: _buildClickableImage(context, chatModel.image1!)),
          if (hasImage1 && hasImage2)
            const SizedBox(width: 8),
          if (hasImage2)
            Expanded(child: _buildClickableImage(context, chatModel.image2!)),
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
      imageUrl: senderAvatarUrl,
      imageBuilder: (context, imageProvider) => CircleAvatar(backgroundImage: imageProvider),
      placeholder: (context, url) => const CircleAvatar(child: CupertinoActivityIndicator()),
      errorWidget: (context, url, error) => const CircleAvatar(child: Icon(Icons.person)),
    );
  }
}
