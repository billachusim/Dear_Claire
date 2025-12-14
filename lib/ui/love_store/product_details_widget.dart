import 'package:cached_network_image/cached_network_image.dart';
import 'package:clairediary/ui/love_store/product_model.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/widgets/unified_media_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

class ProductDetailsWidget extends StatelessWidget {
  final Product product;

  const ProductDetailsWidget({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = HexColor.fromHex(product.colorHex ?? '#4A4A4A');
    final Color textColor =
    backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final Color secondaryTextColor =
    backgroundColor.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7),
      decoration: BoxDecoration(color: backgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Header ---
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                backgroundImage: (product.sellerAvatarUrl != null &&
                    product.sellerAvatarUrl!.isNotEmpty)
                    ? CachedNetworkImageProvider(product.sellerAvatarUrl!)
                    : null,
                child: (product.sellerAvatarUrl == null ||
                    product.sellerAvatarUrl!.isEmpty)
                    ? Icon(Icons.storefront, color: textColor, size: 28)
                    : null,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.sellerNickname ?? 'Claire',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: textColor),
                    ),
                    if (product.timeCreated != null)
                      Text(
                        'Listed ${timeago.format(product.timeCreated!.toDate())}',
                        style: TextStyle(fontSize: 13, color: secondaryTextColor),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 15),

          // --- Media ---
          // In product_details_widget.dart, inside the build method, REPLACE the UnifiedMediaViewer

          // --- Media ---
          if ((product.mediaUrls?.isNotEmpty ?? false) ||
              (product.videoUrls?.isNotEmpty ?? false))
            UnifiedMediaViewer(
              // CORRECTED: Build the mediaItems list
              mediaItems: [
                ...(product.mediaUrls ?? []).map((url) =>
                    MediaItem(networkUrl: url, type: MediaType.image)),
                ...(product.videoUrls ?? []).asMap().entries.map((entry) {
                  int idx = entry.key;
                  String url = entry.value;
                  return MediaItem(
                    networkUrl: url,
                    type: MediaType.video,
                    thumbnailUrl: (product.videoThumbnailUrls != null &&
                        idx < product.videoThumbnailUrls!.length)
                        ? product.videoThumbnailUrls![idx]
                        : null,
                  );
                }),
              ],
              aspectRatio: 16 / 9,
            ),


          SizedBox(height: 15),

          // --- Product Description ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Linkify(
              onOpen: (link) async {
                if (await canLaunchUrl(Uri.parse(link.url))) {
                  await launchUrl(Uri.parse(link.url));
                }
              },
              text: product.description ?? 'No description provided.',
              style: TextStyle(fontSize: 17, color: textColor, height: 1.5),
              linkStyle: TextStyle(
                  color: Pallet.colorBlue, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
