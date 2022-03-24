import 'package:dear_claire/services/user_model.dart';

class EgoProfileInfo{

  final UserModel? userModel;
   var sessionCount;
   var followCount;
   var advisesCount;
   var userType;

  EgoProfileInfo(
      { this.userModel,
       this.sessionCount,
       this.followCount,
       this.advisesCount,
       this.userType});

}