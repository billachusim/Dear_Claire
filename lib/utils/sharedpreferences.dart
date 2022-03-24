import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences? prefs;

class SharedPreference extends ChangeNotifier {
  final String alterEgoIdKey = 'alterEgoId';
  final String alterEgoAccessCodeKey = 'alterEgoAccessCode';


  // clear shared preferences
  Future<void> clear() async {
    prefs = await SharedPreferences.getInstance();
    await prefs!.clear();
  }

  /// cache AlterEgo id
  void setAlterEgoId(String id) async {
    prefs = await SharedPreferences.getInstance();
    prefs!.setString(alterEgoIdKey, id);
    notifyListeners();
  }

  /// get AlterEgoId id
  Future<String> getAlterEgoId() async {
    prefs = await SharedPreferences.getInstance();
    return prefs!.getString(alterEgoIdKey) ?? '';
  }

  /// cache AlterEgo AccessCode
  void setAlterEgoAccessCode(String id) async {
    prefs = await SharedPreferences.getInstance();
    prefs!.setString(alterEgoAccessCodeKey, id);
    notifyListeners();
  }

  /// get AlterEgo AccessCode
  Future<String> getAlterEgoAccessCode() async {
    prefs = await SharedPreferences.getInstance();
    return prefs!.getString(alterEgoAccessCodeKey) ?? '';
  }

}
