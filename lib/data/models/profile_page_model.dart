import 'package:dear_claire/services/user_model.dart';

class EgoProfileInfo{

  final UserModel? userModel;
   var avatarUrl;
   var nickname;
   var sessionCount;
   var followCount;
   var advisesCount;
   var userType;
   var totalLoveCount;
   var currentLoveCount;

  EgoProfileInfo(
      { this.userModel,
       this.avatarUrl,
       this.nickname,
       this.sessionCount,
       this.followCount,
       this.advisesCount,
       this.userType,
       this.totalLoveCount,
       this.currentLoveCount,
      });

}