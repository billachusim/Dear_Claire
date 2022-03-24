import 'package:dear_claire/ui/visited_user_ego_page/visited_user_model.dart';

class VisitedEgoProfileInfo{

  final VisitedUserModel? visitedUserModel;
  var sessionCount;
  var followCount;
  var advisesCount;
  var userType;

  VisitedEgoProfileInfo(
      { this.visitedUserModel,
        this.sessionCount,
        this.followCount,
        this.advisesCount,
        this.userType});

}