import 'package:clairediary/services/user_model.dart';

class EgoProfileInfo{

  final UserModel? userModel;
   var avatarUrl;
   var nickname;
   int? sessionCount;
   var followCount;
   int? advisesCount;
   var userType;
   int? totalLoveCount;
   int? currentLoveCount;
   int? withdrawnLoveCount;

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
       this.withdrawnLoveCount,
      });

}