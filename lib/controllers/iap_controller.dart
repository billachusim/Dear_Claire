import 'dart:async';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../services/firebase_services.dart';
import '../data/models/transaction_model.dart' as t_model;

class IAPController extends GetxController {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  final RxList<ProductDetails> products = <ProductDetails>[].obs;
  final RxBool isAvailable = false.obs;
  final RxBool isLoading = true.obs;

  // Product IDs defined in Play Store / App Store
  static const Set<String> _kIds = {
    'loves_1000',
    'loves_5000',
    'loves_10000',
  };

  @override
  void onInit() {
    super.onInit();
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // Handle error
    });
    initStoreInfo();
  }

  Future<void> initStoreInfo() async {
    final bool available = await _inAppPurchase.isAvailable();
    isAvailable.value = available;

    if (!available) {
      isLoading.value = false;
      return;
    }

    final ProductDetailsResponse productDetailResponse =
    await _inAppPurchase.queryProductDetails(_kIds);

    if (productDetailResponse.error != null) {
      isLoading.value = false;
      return;
    }

    products.value = productDetailResponse.productDetails;
    // Sort by price or amount if needed
    products.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    isLoading.value = false;
  }

  void buyProduct(ProductDetails product) {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show loading or pending UI
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          Get.snackbar("Error", "Purchase failed: ${purchaseDetails.error?.message}");
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {

          // CRITICAL: Deliver the product
          bool delivered = await _deliverLoves(purchaseDetails);

          if (delivered) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
        }
      }
    }
  }

  Future<bool> _deliverLoves(PurchaseDetails purchase) async {
    final firebaseServices = Get.find<FirebaseServices>();
    final userId = firebaseServices.currentUser?.uid;
    if (userId == null) return false;

    // Map Product ID to Love Amount
    int amount = 0;
    switch (purchase.productID) {
      case 'loves_1000': amount = 1000; break;
      case 'loves_5000': amount = 5000; break;
      case 'loves_10000': amount = 10000; break;
    }

    if (amount == 0) return false;

    // Use your existing service to credit user
    return await firebaseServices.updateTreasuryAndUser(
      userId: userId,
      amount: amount,
      type: t_model.TransactionType.credit,
      userTransactionDescription: "Purchased $amount Loves from Store",
      metadata: {
        'source': 'in_app_purchase',
        'product_id': purchase.productID,
        'purchase_id': purchase.purchaseID,
        'transaction_date': purchase.transactionDate,
      },
    );
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }
}
