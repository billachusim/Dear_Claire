import 'dart:math';
import 'package:dear_claire/utils/constant.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';


class CreateSessionController extends GetxController {

  randomizeBackgroundColor(){
    Random random = new Random();
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

  List<XFile> images = <XFile>[];



  void changeColor() {
    print(selectedBackgroundColor.value);
    if (selectedBackgroundColor.value < 21) {
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
