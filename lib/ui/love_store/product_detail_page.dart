import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/services/user_model.dart';
import 'package:clairediary/ui/featured/model/comment_session_model.dart';
import 'package:clairediary/ui/love_store/product_model.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/widgets/chat_edit_field.dart';
import 'package:clairediary/widgets/comment_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

// Placeholder for the widget we will create next
import '../featured/model/session.dart';
import 'product_details_widget.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final FirebaseServices _firebaseServices = FirebaseServices();
  List<CommentSessionModel> _commentList = [];
  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final Color backgroundColor = HexColor.fromHex(product.colorHex ?? '#4A4A4A');
    final Color textColor =
    backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: backgroundColor,
        title: Text(product.title ?? 'Product Details', style: TextStyle(color: textColor)),
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              // This is the new widget we will create next
              ProductDetailsWidget(
                product: product,
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Bids & Comments",
                  style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              // In _ProductDetailPageState, in the build method, REPLACE the StreamBuilder for comments

              AnimationLimiter(
                child: StreamBuilder(
                  // CORRECTED: Manually build the stream path for product comments
                  stream: FirebaseFirestore.instance
                      .collection('products') // Point to the 'products' collection
                      .doc(product.productId.toString())
                      .collection('comments')
                      .orderBy('timeCreated', descending: false)
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                    if (snapShot.hasError) {
                      return Center(child: Text("Could not load comments.", style: TextStyle(color: textColor)));
                    }
                    if (!snapShot.hasData) {
                      return Container();
                    }

                    _commentList = snapShot.data!.docs
                        .map((e) =>
                        CommentSessionModel.fromJson(e.data() as Map<String, dynamic>))
                        .toList();

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: BouncingScrollPhysics(parent: NeverScrollableScrollPhysics()),
                      itemCount: _commentList.length,
                      itemBuilder: (BuildContext c, int i) {
                        return AnimationConfiguration.staggeredList(
                          position: i,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: CommentWidget(
                                commentSessionModel: _commentList[i],
                                // Using a temporary Session object as required by CommentWidget
                                featuredSessionModel: Session(
                                  userId: product.sellerId,
                                  sessionId: product.productId,
                                  flagged: false, // Default value
                                ),
                                userId: product.sellerId.toString(),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              SizedBox(height: 120), // Space for the input field
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ChatEditField(
              onTap: (String comment, voiceNote, image1, image2) =>
                  _sendComment(comment),
            ),
          ),
        ],
      ),
    );
  }

  void _sendComment(String comment) async {
    if (!await _firebaseServices.isUserSignIn(context)) return;

    if (comment.isEmpty) {
      return;
    }

    CollectionReference ref = FirebaseFirestore.instance
        .collection("products") // Use the 'products' collection
        .doc(widget.product.productId!)
        .collection("comments");

    String docId = ref.doc().id;

    final _userModel = await _firebaseServices.getUserInfo();
    final _commentModel = CommentSessionModel(
        alterEgoId: _userModel.alterEgoId,
        audioUrl: '', // Not supported for now
        commentId: docId,
        flagged: false,
        imageUrls: [], // Not supported for now
        image1: '',
        image2: '',
        thanks: [],
        numberOfThanks: 0,
        isUserAdmin: false,
        message: comment,
        timeCreated: Timestamp.now(),
        userAvatarUrl: _userModel.avatarUrl,
        userId: _userModel.userId,
        userNickname: _userModel.nickname);

    await ref.doc(docId).set(_commentModel.toJson());

    // You might want a new notification type for product comments
    _firebaseServices.addCommentNotification(
      title: widget.product.title ?? '',
      docId: widget.product.productId!,
      sender: _userModel.nickname.toString(),
    );

    // Update the last activity time on the product
    FirebaseFirestore.instance
        .collection('products')
        .doc(widget.product.productId!)
        .update({'timeLastActivity': Timestamp.now()});
  }
}
