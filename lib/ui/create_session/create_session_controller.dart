import 'dart:math';
import 'package:flutter/material.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:image_picker/image_picker.dart';

class CreateSessionController extends ChangeNotifier {
  int _selectedBackgroundColor = 0;
  int get selectedBackgroundColor => _selectedBackgroundColor;
  set selectedBackgroundColor(int value) {
    _selectedBackgroundColor = value;
    notifyListeners();
  }

  bool _isShowSticker = false;
  bool get isShowSticker => _isShowSticker;
  set isShowSticker(bool value) {
    _isShowSticker = value;
    notifyListeners();
  }

  int _selectedFontIndex = 0;
  int get selectedFontIndex => _selectedFontIndex;
  void selectFont(int index) {
    _selectedFontIndex = index;
    notifyListeners();
  }

  bool _acceptReplies = false;
  bool get acceptReplies => _acceptReplies;
  set acceptReplies(bool value) {
    _acceptReplies = value;
    notifyListeners();
  }

  bool _followClaire = true;
  bool get followClaire => _followClaire;
  set followClaire(bool value) {
    _followClaire = value;
    notifyListeners();
  }

  bool _location = false;
  bool get location => _location;
  set location(bool value) {
    _location = value;
    notifyListeners();
  }

  String _sessionMood = 'Current Mood';
  String get sessionMood => _sessionMood;
  void changeMood(String value) {
    _sessionMood = value;
    notifyListeners();
  }

  List<XFile> _images = <XFile>[];
  List<XFile> get images => _images;
  set images(List<XFile> value) {
    _images = value;
    notifyListeners();
  }

  void randomizeBackgroundColor() {
    final random = Random();
    _selectedBackgroundColor = random.nextInt(Constant.DIARY_COLORS.length);
    notifyListeners();
  }

  void changeColor() {
    if (_selectedBackgroundColor < 21) {
      _selectedBackgroundColor++;
    } else {
      _selectedBackgroundColor = 0;
    }
    notifyListeners();
  }
}
