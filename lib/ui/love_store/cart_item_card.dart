import 'package:cached_network_image/cached_network_image.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/ui/love_store/product_model.dart';
import 'package:clairediary/utils/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CartItemCard extends StatefulWidget {
  final Product product;
  final int quantity;
  final VoidCallback onCartUpdated; // Callback to refresh the parent page

  const CartItemCard({
    Key? key,
    required this.product,
    required this.quantity,
    required this.onCartUpdated,
  }) : super(key: key);

  @override
  _CartItemCardState createState() => _CartItemCardState();
}

class _CartItemCardState extends State<CartItemCard> {
  final FirebaseServices _firebaseServices = FirebaseServices();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  Future<void> _updateQuantity(int newQuantity) async {
    if (currentUser == null) return;
    setState(() => _isLoading = true);
    await _firebaseServices.updateCartItemQuantity(
      currentUser!.uid,
      widget.product.productId!,
      newQuantity,
    );
    // No need to set isLoading to false here, as the whole page will rebuild
    widget.onCartUpdated();
  }

  Future<void> _removeItem() async {
    if (currentUser == null) return;
    setState(() => _isLoading = true);
    await _firebaseServices.removeCartItem(
      currentUser!.uid,
      widget.product.productId!,
    );
    widget.onCartUpdated();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.product.mediaUrls?.isNotEmpty ?? false;
    final imageUrl = hasImage ? widget.product.mediaUrls!.first : null;

    return Card(
      color: Pallet.colorSecondaryDark,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.black26,
                    child: hasImage
                        ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          CupertinoActivityIndicator(),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.broken_image, color: Colors.white38),
                    )
                        : Icon(Icons.storefront, color: Colors.white38, size: 40),
                  ),
                ),
                SizedBox(width: 16),
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.title ?? 'No Title',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.favorite, color: Colors.red, size: 16),
                          SizedBox(width: 4),
                          Text(
                            widget.product.loveAmount?.toString() ?? '0',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Quantity Controls
                _buildQuantitySelector(),
              ],
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(child: CupertinoActivityIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(CupertinoIcons.minus, color: Colors.white, size: 16),
            onPressed: () => _updateQuantity(widget.quantity - 1),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
          SizedBox(
            width: 30,
            child: Text(
              widget.quantity.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            icon: Icon(CupertinoIcons.plus, color: Colors.white, size: 16),
            onPressed: () => _updateQuantity(widget.quantity + 1),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
