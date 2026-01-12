import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/firebase_services.dart';
import '../ui/create_session/sound/custom_play_sound_widget.dart';
import '../ui/create_session/sound/sound_widget.dart';
import '../ui/featured/model/session.dart';
import '../ui/routes/page_router_animation.dart';
import '../utils/constant.dart';
import 'custom_image_widget.dart';

class ChatEditField extends StatefulWidget {
  // IMPORTANT: Consider changing the parent widget to accept List<String> instead of two separate strings.
  final Function(String value, String voiceNote, String image1, String image2) onTap;

  ChatEditField({Key? key, required this.onTap}) : super(key: key);

  @override
  _ChatEditFieldState createState() => _ChatEditFieldState();
}

class _ChatEditFieldState extends State<ChatEditField> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseServices _firebaseServices = FirebaseServices();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // --- State Variables ---
  bool isTyping = false;
  bool isProcessing = false; // Single flag for any loading state (audio, images).
  String processingMessage = ''; // Message to show while processing.

  File? _recordFile;
  List<File> imageList = <File>[]; // Holds local image files for preview.


  /// This function now ONLY picks images from the gallery and updates the UI for preview.
  /// The actual upload is handled when the 'send' button is pressed.
  Future<void> pickImages() async {
    // Let the user know we are opening the gallery
    setState(() {
      isProcessing = true;
      processingMessage = 'Opening gallery...';
    });

    List<XFile>? pickedFiles;
    try {
      // Pick up to 5 images. You can change this limit.
      // Use a lower imageQuality to reduce upload time and storage costs.
      pickedFiles = await ImagePicker().pickMultiImage(imageQuality: 80);
    } catch (e) {
      print('Error picking images: $e');
      // Optionally show an error message to the user.
    }

    if (!mounted) return;

    // If the user selected images, update the list for preview.
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        // Limit to 5 images
        final filesToAdd = pickedFiles!.take(5).map((file) => File(file.path)).toList();
        imageList = filesToAdd;
      });
    }

    // Reset the processing state
    setState(() {
      isProcessing = false;
      processingMessage = '';
    });
  }


  /// Uploads the recorded audio file to Firebase Storage.
  Future<String> uploadCommentAudio(File file) async {
    final timeStamp = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    final filename = currentUser!.uid.toString();
    final ref = firebase_storage.FirebaseStorage.instance.ref().child("audio/$filename$timeStamp");
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() => {});
    final downloadUrl = await snapshot.ref.getDownloadURL();
    print("The audio url is $downloadUrl");
    return downloadUrl;
  }


  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        color: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Audio Preview ---
            Visibility(
              visible: _recordFile != null,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(child: CustomPlaySoundWidget(filePath: _recordFile?.path)),
                    IconButton(
                        icon: Icon(Icons.cancel, color: Colors.red, size: 24.r),
                        onPressed: () => setState(() {
                          _recordFile = null;
                        }))
                  ],
                ),
              ),
            ),

            // --- Image Preview Row (New and Improved) ---
            Visibility(
              visible: imageList.isNotEmpty,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: SizedBox(
                  height: 75,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageList.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                imageList[index],
                                height: 75,
                                width: 75,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => setState(() => imageList.removeAt(index)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // --- User Feedback Messages ---
            Visibility(
              visible: isTyping || isProcessing,
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                  child: Text(
                    isProcessing ? processingMessage : "No form of abuse is allowed on this app. You will be banned.",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ),

            // --- Main Input Row ---
            Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: isProcessing ? null : pickImages,
                  child: Icon(Icons.linked_camera_rounded, size: 30, color: Colors.pink),
                ),
                FloatingActionButton(
                  heroTag: "Record",
                  onPressed: isProcessing
                      ? null
                      : () async {
                    if (!await _firebaseServices.isUserSignIn(context)) return;

                    // 1. Request microphone permission
                    var status = await Permission.microphone.request();

                    // 2. Check the permission status
                    if (status.isGranted) {
                      // Permission is granted, proceed to the recorder
                      if (!mounted) return;
                      var data = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SoundRecorderWidget(
                            onRecordComplete: (recordFile) {},
                          ),
                        ),
                      );
                      if (data != null) {
                        setState(() {
                          _recordFile = data;
                        });
                      }
                    } else if (status.isPermanentlyDenied) {
                      // Permission is permanently denied, show a dialog to open settings
                      // You might want to implement a 'showToast' function or use a SnackBar.
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Microphone permission is required. Please enable it in settings.')));
                      await openAppSettings();
                    } else {
                      // Permission was denied, but not permanently.
                      // You might want to implement a 'showToast' function or use a SnackBar.
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Microphone permission is required to record audio.')));
                    }
                  },

                  mini: true,
                  backgroundColor: Pallet.colorPrimary,
                  child: Icon(Icons.mic_rounded, size: 35),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 13.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade200,
                    ),
                    child: TextField(
                      cursorColor: Theme.of(context).colorScheme.primary,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      controller: _controller,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                      ),
                      onChanged: (text) => setState(() => isTyping = text.isNotEmpty),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Positive vibes only...",
                        hintStyle: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),

                // --- SEND BUTTON (New and Improved Logic) ---
                FloatingActionButton(
                  heroTag: "Write",
                  onPressed: isProcessing ? null : () async {
                    // Ignore empty sends
                    if (_controller.text.isEmpty && _recordFile == null && imageList.isEmpty) {
                      return;
                    }

                    if (!await _firebaseServices.isUserSignIn(context)) return;

                    setState(() {
                      isProcessing = true;
                      processingMessage = 'Sending...';
                    });

                    String audioUrl = '';
                    List<String> uploadedImageUrls = [];

                    try {
                      // 1. Upload audio if available
                      if (_recordFile != null) {
                        setState(() => processingMessage = 'Uploading audio...');
                        audioUrl = await uploadCommentAudio(_recordFile!);
                      }

                      // 2. Upload images concurrently if available
                      if (imageList.isNotEmpty) {
                        setState(() => processingMessage = 'Uploading images...');
                        List<Future<String>> uploadTasks = imageList.map((file) {
                          // Assuming _firebaseServices.uploadImage exists and works
                          return _firebaseServices.uploadImage(file);
                        }).toList();

                        uploadedImageUrls = await Future.wait(uploadTasks);
                      }

                      // 3. Callback with the data
                      // NOTE: We send the first two URLs to match the required function signature.
                      // For a better implementation, update the parent to accept List<String>.
                      String image1 = uploadedImageUrls.isNotEmpty ? uploadedImageUrls[0] : '';
                      String image2 = uploadedImageUrls.length > 1 ? uploadedImageUrls[1] : '';
                      widget.onTap(_controller.text, audioUrl, image1, image2);

                    } catch (e) {
                      print("Error during upload: $e");
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Upload failed. Please try again.')),
                        );
                      }
                    } finally {
                      // 4. Clean up state and UI
                      if (mounted) {
                        _controller.clear();
                        setState(() {
                          isTyping = false;
                          isProcessing = false;
                          processingMessage = '';
                          _recordFile = null;
                          imageList.clear();
                        });
                      }
                    }
                  },
                  mini: true,
                  backgroundColor: isProcessing ? Colors.grey : Pallet.colorSplashScreen,
                  child: isProcessing
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0,))
                      : SvgPicture.asset(AppImages.appSend, height: 25),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

