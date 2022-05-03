import 'package:dear_claire/utils/constant.dart';
import 'package:get/get.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'dart:math';



class CreateSessionController extends GetxController {

  randomizeBackgroundColor(){
    Random random = new Random();
    int randomNumber = random.nextInt(Constant.DIARY_COLORS.length+1);
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

  List<Asset> images = <Asset>[];



  void changeColor() {
    print(selectedBackgroundColor.value);
    if (selectedBackgroundColor.value < 18) {
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
