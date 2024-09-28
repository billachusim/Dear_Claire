
import 'package:dear_claire/data/core/view_state.dart';

import 'base/base_view_model.dart';

class SignUpViewModel extends BaseViewModel {
  // final userRepository = locator<UserRepository>();

  ViewState _state = ViewState.Idle;
  ViewState get viewState => _state;
  String errorMessage = "";
  String type = 'user';
  String email= "";
  String secretCode= "";
  bool isValidSignUp = false;
  bool isHidesecretCode = true;

  void setViewState(ViewState state) {
    _state = state;
    notifyListeners();
  }

  void setError(String error) {
    errorMessage = error;
    notifyListeners();
  }

  void validateSignUp() {
    isValidSignUp = isValidEmail() && isValidPassword();
    notifyListeners();
  }

  bool isValidEmail() {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern.toString());
    return regex.hasMatch(email);
  }

  bool isValidPassword() {
    return secretCode.isNotEmpty && secretCode.length > 3;
  }

  // bool isValidUserName() {
  //   return username.isNotEmpty && username.length >= 4;
  // }

  void togglePassword() {
    isHidesecretCode = !isHidesecretCode;
    notifyListeners();
  }

  /// signup user

  Future<bool> registerUser(
      String email, String secretCode) async {
    try {
      setViewState(ViewState.Loading);
      var signUpResponse =
      // await userRepository.registerUser(email, secretCode);
      setViewState(ViewState.Success);
    } catch (error) {
      setViewState(ViewState.Error);
      setError(error.toString());
    }
    return true; //todo check if the return would be a problem
  }
}