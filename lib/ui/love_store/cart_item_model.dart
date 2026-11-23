import 'package:clairediary/ui/love_store/product_model.dart';

/// A helper class to pair a Product with its quantity in the cart.
class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});
}
