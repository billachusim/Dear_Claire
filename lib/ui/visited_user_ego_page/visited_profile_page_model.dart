import 'package:dear_claire/ui/visited_user_ego_page/visited_user_model.dart';

class VisitedEgoProfileInfo{

  final VisitedUserModel? visitedUserModel;
  int? sessionCount;
  var followCount;
  int? advisesCount;
  var userType;
  int? totalLoveCount;
  int? currentLoveCount;

  VisitedEgoProfileInfo(
      { this.visitedUserModel,
        this.sessionCount,
        this.followCount,
        this.advisesCount,
        this.userType,
        this.totalLoveCount,
        this.currentLoveCount,
      });

}