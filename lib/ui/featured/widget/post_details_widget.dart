import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/featured/model/session.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/utils/mood.dart';
import 'package:dear_claire/widgets/follow_button.dart';
import 'package:dear_claire/widgets/metoo_button.dart';
import 'package:dear_claire/widgets/share_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PostDetailsWidget extends StatelessWidget {
  final String? sessionId;

  const PostDetailsWidget({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return StreamBuilder(
      stream: firebaseServices.getSingleDocument(id: sessionId),
      builder: (
        context,
        AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot,
      ) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final session = Session.fromJson(snapshot.data!.data()!);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 5),
          decoration: BoxDecoration(color: HexColor.fromHex(session.colorHex)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _UserInfo(session: session),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  session.title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  style: GoogleFonts.lato(
                    fontSize: 20.0,
                    color: Pallet.colorWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _MessageContent(session: session),
              const SizedBox(height: 10),
              _ActionButtons(session: session, currentUser: currentUser),
            ],
          ),
        );
      },
    );
  }
}

class _UserInfo extends StatelessWidget {
  final Session session;

  const _UserInfo({required this.session});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _UserAvatar(avatarUrl: session.userAvatarUrl),
        const SizedBox(width: 8),
        _UserDetails(session: session),
        _MoodDetails(session: session),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String avatarUrl;

  const _UserAvatar({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      width: 48,
      height: 48,
      imageUrl: avatarUrl,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.fill,
          ),
        ),
      ),
      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) => Image.asset(
        "assets/images/brown_boy_mask.png",
        width: 48,
        height: 48,
      ),
    );
  }
}

class _UserDetails extends StatelessWidget {
  final Session session;

  const _UserDetails({required this.session});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.userNickname,
            textAlign: TextAlign.start,
            maxLines: 1,
            style: GoogleFonts.lato(
              fontSize: 18.0,
              color: Pallet.colorWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            timeConverter(session.timeCreated!),
            textAlign: TextAlign.start,
            maxLines: 1,
            style: GoogleFonts.lato(
              fontSize: 13.0,
              color: Pallet.colorWhite,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodDetails extends StatelessWidget {
  final Session session;

  const _MoodDetails({required this.session});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Mood.getMood(session.moodId).toString(),
            textAlign: TextAlign.end,
            maxLines: 1,
            style: GoogleFonts.lato(
              fontSize: 13.0,
              color: Pallet.colorWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          FutureBuilder<Widget>(
            future: firebaseServices.showUserLocation(),
            builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
              return snapshot.hasData
                  ? snapshot.data!
                  : Text(
                      '',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      style: GoogleFonts.lato(
                        fontSize: 12.0,
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    );
            },
          ),
        ],
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  final Session session;

  const _MessageContent({required this.session});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            session.message,
            textAlign: TextAlign.left,
            style: GoogleFonts.lato(
              fontSize: 17.0,
              color: Pallet.colorWhite,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        if (session.imageUrls.isNotEmpty)
          _MessageImage(imageUrl: session.imageUrls.first),
      ],
    );
  }
}

class _MessageImage extends StatelessWidget {
  final String imageUrl;

  const _MessageImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      height: 73,
      width: 73,
      imageUrl: imageUrl,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.fill,
          ),
        ),
      ),
      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) => Image.asset(
        "assets/images/brown_boy_mask.png",
        width: 48,
        height: 48,
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Session session;
  final User? currentUser;

  const _ActionButtons({required this.session, this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MetooButton(
          cheers: session.meToos.length,
          thanks: session.meLove.length,
          sorry: session.meHiFive.length,
          me2: session.meFlower.length,
          onReactionChanged: (reaction, index) async {
            if (await firebaseServices.isUserSignIn(context)) {
              final userModel = await firebaseServices.getUserInfo();
              firebaseServices.addUsersReactionToASession(
                context,
                index,
                session: session,
                sender: userModel.nickname ?? '',
              );
            }
          },
          color: Pallet.colorWhite,
        ),
        const Spacer(),
        FollowButton(
          text: session.followers.contains(currentUser?.uid) ? 'Unfollow' : 'Follow',
          onPressed: () async {
            if (await firebaseServices.isUserSignIn(context)) {
              firebaseServices.followThisSession(context, session: session);
            }
          },
          count: session.followers.length,
        ),
        const Spacer(),
        ShareButton(
          onPressed: () => firebaseServices.user?.alterEgoId == 'claire'
              ? shareMessage(session.message)
              : null,
          color: firebaseServices.user?.alterEgoId == 'claire'
              ? Pallet.colorWhite
              : Pallet.colorWhite,
        ),
      ],
    );
  }
}
