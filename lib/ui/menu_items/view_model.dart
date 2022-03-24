import 'package:flutter/foundation.dart';

class HowClaireWorksProvider extends ChangeNotifier {
  bool _isExpanded = true;

  bool get isExpanded => _isExpanded;

  int _imageSliderIndex = 0;
  int get imageSliderIndex => _imageSliderIndex;

  void increaseIndex(int currentIndex) {
    if (currentIndex != 3) {
      _imageSliderIndex++;
    } else {
      print('do nothing');
    }
    notifyListeners();
  }

  void decreaseIndex(int currentIndex) {
    if (currentIndex != 0) {
      _imageSliderIndex--;
    } else {
      print('do nothing');
    }

    notifyListeners();
  }

  resetImageSlider() {
    _imageSliderIndex = 0;
    notifyListeners();
  }

  toggleIsExpanded() {
    _isExpanded = !_isExpanded;

    notifyListeners();
  }
}
