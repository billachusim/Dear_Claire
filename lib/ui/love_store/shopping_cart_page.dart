import 'package:clairediary/helpers/toast_helper.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/widgets/empty_state_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cart_item_card.dart';
import 'cart_item_model.dart';

class ShoppingCartPage extends StatefulWidget {
  const ShoppingCartPage({Key? key}) : super(key: key);

  @override
  _ShoppingCartPageState createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  final FirebaseServices _firebaseServices = FirebaseServices();
  late Future<List<CartItem>> _cartItemsFuture;
  User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isCheckingOut = false; // To manage loading state

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  void _loadCartItems() {
    if (currentUser != null) {
      setState(() {
        _cartItemsFuture = _firebaseServices.getCartItems(currentUser!.uid);
      });
    }
  }

  void _onCartUpdated() {
    _loadCartItems();
  }

  Future<void> _checkout() async {
    if (currentUser == null) return;

    setState(() {
      _isCheckingOut = true;
    });

    final result = await _firebaseServices.processCheckout(currentUser!.uid);

    if (mounted) {
      setState(() {
        _isCheckingOut = false;
      });
    }

    // Show the result from the backend
    showToast(message: result);

    // If checkout was successful, refresh the cart page to show it's empty
    if (result.contains("successful")) {
      _onCartUpdated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallet.colorSecondary,
      appBar: AppBar(
        title: Text('My Cart'),
        backgroundColor: Pallet.colorSecondary,
        elevation: 0,
        centerTitle: true,
      ),
      body: currentUser == null
          ? EmptyStateWidget(
        message: "Please log in to see your cart.",
        icon: Icons.person_off,
        title: '',
        buttonText: '',
        onButtonPressed: () {},
      )
          : FutureBuilder<List<CartItem>>(
        future: _cartItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading your cart.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyStateWidget(
              message: "Your cart is empty.",
              icon: Icons.shopping_cart_outlined,
              title: '',
              buttonText: '',
              onButtonPressed: () {},
            );
          }

          final cartItems = snapshot.data!;
          final totalLove = cartItems.fold<int>(
              0,
                  (sum, item) =>
              sum + (item.product.loveAmount ?? 0) * item.quantity);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final product = cartItems[index].product;
                    final quantity = cartItems[index].quantity;
                    return CartItemCard(
                      product: product,
                      quantity: quantity,
                      onCartUpdated: _onCartUpdated,
                    );
                  },
                ),
              ),
              _buildCheckoutSummary(totalLove),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCheckoutSummary(int totalLove) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Pallet.colorPrimary.withValues(alpha: 0.1),
        border:
        Border(top: BorderSide(color: Pallet.colorSecondary, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: GoogleFonts.outfit(fontSize: 18, color: Colors.white70),
              ),
              Row(
                children: [
                  Icon(Icons.favorite, color: Colors.red, size: 24),
                  SizedBox(width: 8),
                  Text(
                    totalLove.toString(),
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_isCheckingOut || totalLove == 0) ? null : _checkout,
              icon: _isCheckingOut
                  ? SizedBox(
                width: 20,
                height: 20,
                child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : Icon(Icons.lock_outline),
              label: Text(_isCheckingOut ? 'Processing...' : 'Proceed to Checkout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Pallet.colorBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade700,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
