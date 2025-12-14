import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/ui/love_store/product_model.dart';
import 'package:clairediary/ui/love_store/shopping_cart_page.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/widgets/empty_state_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Placeholder for the card we will create in the next step
import '../routes/page_router_animation.dart';
import '../routes/routes.dart';
import 'love_store_item_card.dart';

class LoveStorePage extends StatefulWidget {
  const LoveStorePage({Key? key}) : super(key: key);

  @override
  _LoveStorePageState createState() => _LoveStorePageState();
}

class _LoveStorePageState extends State<LoveStorePage> {
  final FirebaseServices _firebaseServices = FirebaseServices();

  // In _LoveStorePageState, REPLACE the existing build method

  @override
  Widget build(BuildContext context) {
    // Get the current user to pass to the stream
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Pallet.colorSecondary, // Corrected for consistency
      appBar: AppBar(
        title: Text('The Love Store'),
        backgroundColor: Pallet.colorSecondary,
        elevation: 0,
        centerTitle: true,
        actions: [
          StreamBuilder<int>(
            stream: currentUser != null
                ? _firebaseServices.getCartItemCount(currentUser.uid)
                : Stream.value(0), // Default to 0 if not logged in
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Badge(
                  label: Text(count.toString()),
                  isLabelVisible: count > 0,
                  child: IconButton(
                    icon: Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      PageRouter.gotoWidget(ShoppingCartPage(), context);
                    },
                    tooltip: 'My Cart',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: _firebaseServices.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyStateWidget(
              message: "The Love Store is currently empty.\nCheck back soon!",
              icon: Icons.storefront,
              title: 'No Items',
              buttonText: '',
              onButtonPressed: () {},
            );
          }

          final products = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return LoveStoreItemCard(product: product);
            },
          );
        },
      ),
    );
  }

}
