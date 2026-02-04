import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:clairediary/ui/love_store/product_model.dart';
import 'package:uuid/uuid.dart';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/services/user_model.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/helpers/toast_helper.dart';
import 'package:clairediary/widgets/unified_media_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../create_session/create_session_controller.dart';

class CreateLoveItemPage extends StatefulWidget {
  const CreateLoveItemPage({Key? key}) : super(key: key);

  @override
  _CreateLoveItemPageState createState() => _CreateLoveItemPageState();
}

class _CreateLoveItemPageState extends State<CreateLoveItemPage> {
  final FirebaseServices _firebaseServices = FirebaseServices();
  final c = Get.put(CreateSessionController()); // Using the same controller for media picking

  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController loveAmountController = TextEditingController();
  TextEditingController stockController = TextEditingController();

  var currentUser = FirebaseAuth.instance.currentUser;
  UserModel userModel = UserModel();
  var uuid = Uuid();
  late FocusNode descriptionFocusNode;

  List<File> _videoFiles = [];
  bool isLoading = false;

  void randomizeBackgroundColor() {
    Random random = Random();
    int randomNumber = random.nextInt(Constant.DIARY_COLORS.length);
    c.selectedBackgroundColor = randomNumber.obs;
  }

  @override
  void initState() {
    super.initState();
    randomizeBackgroundColor();
    descriptionFocusNode = FocusNode();
    _fetchUserModel();
    // Reset media from previous sessions if any
    c.images.clear();
  }

  Future<void> _fetchUserModel() async {
    if (currentUser != null) {
      final model = await _firebaseServices.getUserInfo();
      setState(() {
        userModel = model;
      });
    }
  }

  @override
  void dispose() {
    descriptionFocusNode.dispose();
    titleController.dispose();
    descriptionController.dispose();
    loveAmountController.dispose();
    stockController.dispose();
    super.dispose();
  }


  Future<void> _createLoveItem() async {
    if (currentUser == null) {
      showToast(message: "You must be logged in to create an item.");
      return;
    }

    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final loveAmount = int.tryParse(loveAmountController.text.trim());
    final stock = int.tryParse(stockController.text.trim());

    if (title.isEmpty) {
      showToast(message: "Please enter a product name.");
      return;
    }
    if (loveAmount == null || loveAmount <= 0) {
      showToast(message: "Please enter a valid Love Amount.");
      return;
    }
    if (c.images.isEmpty && _videoFiles.isEmpty) {
      showToast(message: 'Please add at least one image or video.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String docId = uuid.v1();
      List<String> imageUrls = [];
      List<String> videoUrls = [];
      List<String> videoThumbUrls = [];

      // 1. Upload Images using the new helper method
      if (c.images.isNotEmpty) {
        imageUrls = await _firebaseServices.uploadMultipleImages(
            images: c.images, docId: docId);
      }

      // 2. Upload Videos
      if (_videoFiles.isNotEmpty) {
        for (var videoFile in _videoFiles) {
          // CORRECTED: Call uploadVideoToStorage with only the file
          String videoUrl =
          await _firebaseServices.uploadVideoToStorage(videoFile);
          // CORRECTED: Call uploadVideoThumbnail with only the file
          String? thumbUrl =
          await _firebaseServices.uploadVideoThumbnailToStorage(videoFile);
          videoUrls.add(videoUrl);
          videoThumbUrls.add(thumbUrl);
                }
      }


      // 3. Create Product Object
      final product = Product(
        productId: docId,
        sellerId: currentUser!.uid,
        sellerNickname: userModel.nickname ?? 'Claire',
        sellerAvatarUrl: userModel.avatarUrl ?? '',
        title: title,
        description: description,
        loveAmount: loveAmount,
        stock: stock,
        mediaUrls: imageUrls,
        videoUrls: videoUrls,
        videoThumbnailUrls: videoThumbUrls,

        // CORRECTED: Use DIARY_COLORS_HEXCODE to get the String value
        colorHex: Constant.DIARY_COLORS_HEXCODE[c.selectedBackgroundColor.value],

        followers: [currentUser!.uid], // Seller auto-follows
        timeCreated: null, // Firestore will set this
        timeLastActivity: null,
      );

//... the rest of the method remains the same


      // 4. Save to Firestore
      await _firebaseServices.createProduct(product);

      showToast(message: 'New Love Store item has been listed!');
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      logger.e('Error creating product: $e');
      showToast(message: 'Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Obx(
          () => Scaffold(
        backgroundColor:
        Constant.DIARY_COLORS[c.selectedBackgroundColor.value],
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.color_lens_outlined, color: Colors.white),
              onPressed: randomizeBackgroundColor,
            ),
            IconButton(
              onPressed: () async {
                final List<XFile>? images = await ImagePicker().pickMultiImage();
                if (images != null) {
                  setState(() {
                    c.images.addAll(images.map((xfile) => File(xfile.path)).toList());
                  });
                }
              },
              icon: Icon(Icons.image_outlined, color: Colors.white),
            ),
            IconButton(
              onPressed: () async {
                final XFile? video = await ImagePicker().pickVideo(source: ImageSource.gallery);
                if (video != null) {
                  setState(() {
                    _videoFiles.add(File(video.path));
                  });
                }
              },
              icon: Icon(Icons.videocam_outlined, color: Colors.white),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Pallet.colorBlue,
          onPressed: isLoading ? null : _createLoveItem,
          child: isLoading
              ? CircularProgressIndicator(color: Colors.white)
              : Icon(Icons.check, size: 30),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeTextField(
                  controller: titleController,
                  maxLines: 2,
                  minFontSize: 28,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Product Name...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 36,
                    ),
                    border: InputBorder.none,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumericTextField(
                        controller: loveAmountController,
                        hintText: 'Love Amount',
                        icon: Icons.favorite,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildNumericTextField(
                        controller: stockController,
                        hintText: 'Stock (Optional)',
                        icon: Icons.inventory_2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextField(
                  controller: descriptionController,
                  focusNode: descriptionFocusNode,
                  maxLines: 15,
                  minLines: 1,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Describe the product or service...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 18,
                    ),
                    border: InputBorder.none,
                  ),
                ),
                SizedBox(height: 20),
                // In the build method, find and REPLACE the existing UnifiedMediaViewer section

                if (c.images.isNotEmpty || _videoFiles.isNotEmpty)
                  UnifiedMediaViewer(
                    // CORRECTED: Build the mediaItems list
                    mediaItems: [
                      ...c.images.map((file) => MediaItem(
                        networkUrl: file.path, // Use local path for preview
                        type: MediaType.image,
                        onDelete: () {
                          setState(() => c.images.remove(file));
                        },
                      )),
                      ..._videoFiles.map((file) => MediaItem(
                        networkUrl: file.path, // Use local path for preview
                        type: MediaType.video,
                        onDelete: () {
                          setState(() => _videoFiles.remove(file));
                        },
                      )),
                    ],
                    aspectRatio: 16 / 9, // Example aspect ratio
                  ),

                SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumericTextField({required TextEditingController controller, required String hintText, required IconData icon}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.7)),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.normal),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
