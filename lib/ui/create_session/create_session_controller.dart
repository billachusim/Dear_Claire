import 'dart:io';

import 'package:clairediary/utils/constant.dart';
import 'package:get/get.dart';
import 'dart:math';



class CreateSessionController extends GetxController {

  @override
  void onInit() {
    super.onInit();
    // Randomize the background color when the controller is initialized
    randomizeBackgroundColor();
  }

  randomizeBackgroundColor(){
    Random random = new Random();
    // Corrected the range to avoid out-of-bounds errors
    int randomNumber = random.nextInt(Constant.DIARY_COLORS.length);
    selectedBackgroundColor = randomNumber.obs;
  }
  var selectedBackgroundColor;

  var isShowSticker = false.obs;
  var selectedFontIndex = 0.obs;

  var acceptReplies = false.obs;
  var followClaire = true.obs;
  var location = false.obs;
  var sessionMood = 'Current Mood'.obs;

  changeMood(String value) {
    sessionMood.value = value;
  }

  List<File> images = <File>[];



  void changeColor() {
    print(selectedBackgroundColor.value);
    // Updated the condition to match the length of the DIARY_COLORS list
    if (selectedBackgroundColor.value < Constant.DIARY_COLORS.length - 1) {
      selectedBackgroundColor++;
    } else {
      selectedBackgroundColor.value = 0;
    }
  }

  void selectFont(int index) {
    print(index);
    selectedFontIndex.value = index;
  }
}
