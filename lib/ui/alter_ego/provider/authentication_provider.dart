
import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationService {

  final FirebaseAuth _firebaseAuth;

  AuthenticationService(this._firebaseAuth);


  String? _uid;
  String? _email;
  bool _isLoading = false;



  bool get isLoading => _isLoading;

  String get getUid => _uid!;
  String get getEmail => _email!;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<bool> loginUser ({required String email, required String password})async {
    _isLoading = true;
    bool isSuccessful= false;
    try{
      UserCredential _userCredentials = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);

      isSuccessful=true;
      _email = _userCredentials.user!.email;
      _uid =_userCredentials.user!.uid;
        }on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    }catch(e){
      print(e.toString());
    }

    _isLoading = false;
    return isSuccessful;
  }


  Future<bool> signUpUser ({required String email, required String password})async {
  bool isSuccessful= false;
  _isLoading = true;
  try{
    UserCredential _userCredentials = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);

    isSuccessful=true;

    }on FirebaseAuthException catch (e) {
    if (e.code == 'weak-password') {
      print('The password provided is too weak.');
    } else if (e.code == 'email-already-in-use') {
      print('The account already exists for that email.');
    }
  }catch(e){
    print(e.toString());
  }


  _isLoading = false;
  return isSuccessful;
  }
}