import 'package:cached_network_image/cached_network_image.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/ui/love_store/product_detail_page.dart';
import 'package:clairediary/ui/love_store/product_model.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/widgets/unified_media_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../helpers/toast_helper.dart';

class LoveStoreItemCard extends StatefulWidget {
  final Product product;

  const LoveStoreItemCard({Key? key, required this.product}) : super(key: key);

  @override
  State<LoveStoreItemCard> createState() => _LoveStoreItemCardState();
}

class _LoveStoreItemCardState extends State<LoveStoreItemCard> {
  final FirebaseServices _firebaseServices = FirebaseServices();
  final GlobalKey<UnifiedMediaViewerState> _mediaViewerKey =
  GlobalKey<UnifiedMediaViewerState>();
  User? currentUser = FirebaseAuth.instance.currentUser;

  void _addToCart() {
    if (currentUser == null) {
      showToast(message: 'Please log in to add items to your cart.');
      return;
    }
    // For now, we add quantity 1. This can be expanded later.
    _firebaseServices.addToCart(currentUser!.uid, widget.product.productId!, 1);
  }

  void _followProduct() {
    if (currentUser == null) {
      showToast(message: 'Please log in to follow an item.');
      return;
    }
    // Placeholder for follow logic. This would typically update the 'followers' array in the product document.
    showToast(message: 'You are now following this item.');
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final Color backgroundColor = HexColor.fromHex(product.colorHex ?? '#4A4A4A');
    final Color textColor =
    backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final Color secondaryTextColor = backgroundColor.computeLuminance() > 0.5
        ? Colors.black54
        : Colors.white70;

    return GestureDetector(
      onTap: () {
        // Pause any playing video before navigating
        final bool didPause =
            _mediaViewerKey.currentState?.pauseAllVideos() ?? false;

        if (!didPause) {
          PageRouter.gotoWidget(
              ProductDetailPage(product: product), context);
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Header: Seller Info ---
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  backgroundImage: (product.sellerAvatarUrl != null &&
                      product.sellerAvatarUrl!.isNotEmpty)
                      ? CachedNetworkImageProvider(product.sellerAvatarUrl!)
                      : null,
                  child: (product.sellerAvatarUrl == null ||
                      product.sellerAvatarUrl!.isEmpty)
                      ? Icon(Icons.storefront, color: textColor)
                      : null,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.sellerNickname ?? 'Claire',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor),
                      ),
                      if (product.timeCreated != null)
                        Text(
                          timeago.format(product.timeCreated!.toDate()),
                          style:
                          TextStyle(fontSize: 12, color: secondaryTextColor),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // --- Body: Product Title & Media ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                product.title ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    color: textColor),
              ),
            ),
            // In the build method of _LoveStoreItemCardState, replace the UnifiedMediaViewer

            if ((product.mediaUrls?.isNotEmpty ?? false) ||
                (product.videoUrls?.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: UnifiedMediaViewer(
                  key: _mediaViewerKey,
                  // CORRECTED: Build the mediaItems list from the product's URLs
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
              ),


            // --- Footer: Actions ---
            Padding(
              padding: const EdgeInsets.only(top: 12.0, left: 4, right: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Love Amount Display
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite, color: Colors.red, size: 16),
                        SizedBox(width: 6),
                        Text(
                          product.loveAmount?.toString() ?? '0',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  Row(
                    children: [
                      _buildActionButton(
                          icon: Icons.notifications_active_outlined,
                          label: 'Follow',
                          onPressed: _followProduct,
                          textColor: textColor),
                      SizedBox(width: 8),
                      _buildActionButton(
                          icon: Icons.add_shopping_cart,
                          label: 'Add to Cart',
                          onPressed: _addToCart,
                          textColor: textColor,
                          isPrimary: true),
                    ],
                  )
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
        required VoidCallback onPressed,
        required Color textColor,
        bool isPrimary = false}) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: isPrimary ? Pallet.colorBlue : Colors.black.withValues(alpha: 0.15),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(
        label,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed,
    );
  }
}
