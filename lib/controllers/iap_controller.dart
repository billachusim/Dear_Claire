import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../services/firebase_services.dart';
import '../data/models/transaction_model.dart' as t_model;
import '../services/transaction_service.dart';

class IAPController extends GetxController {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  User? currentUser = FirebaseAuth.instance.currentUser;

  final RxList<ProductDetails> products = <ProductDetails>[].obs;
  final RxBool isAvailable = false.obs;
  final RxBool isLoading = true.obs;

  // Product IDs defined in Play Store / App Store
  static const Set<String> _kIds = {
    'loves_1000',
    'loves_5000',
    'loves_10000',
    'loves_donate',
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
    print("IAP_DEBUG: Starting delivery for ProductID: ${purchase.productID}");

    final firebaseServices = FirebaseServices();
    final userId = currentUser?.uid;

    if (userId == null) {
      print("IAP_DEBUG: User ID is null. Cannot deliver.");
      return false;
    }

    int amount = 0;
    if (purchase.productID.contains('loves_10000')) {
      amount = 10000;
    } else if (purchase.productID.contains('loves_5000')) {
      amount = 5000;
    } else if (purchase.productID.contains('loves_1000')) {
      amount = 1000;
    } else if (purchase.productID == 'loves_donate') {
      amount = 50000;
    }

    if (amount == 0) {
      print("IAP_DEBUG: Failed to map ProductID ${purchase.productID} to an amount.");
      // Log this failure as a pending transaction so you have a record of the error
      await Get.find<TransactionService>().recordTransaction(
        userId: userId,
        amount: 0,
        type: t_model.TransactionType.credit,
        description: "ERROR: Unrecognized Product ID: ${purchase.productID}",
        status: t_model.TransactionStatus.pending,
      );
      return false;
    }

    print("IAP_DEBUG: Calling Firebase to credit $amount loves...");

    try {
      bool result = await firebaseServices.updateTreasuryAndUser(
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
      print("IAP_DEBUG: Firebase update result: $result");
      return result;
    } catch (e) {
      print("IAP_DEBUG: Exception during Firebase update: $e");
      return false;
    }
  }


  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }
}
