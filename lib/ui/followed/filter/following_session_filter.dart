import 'package:clairediary/ui/featured/model/session.dart';
import 'package:clairediary/utils/filter.dart';

/// This class is used to filter session
class FollowingSessionFilter implements ResultFilter {
  String? userId;

  FollowingSessionFilter(this.userId);

  @override
  List<Session> filter(List<dynamic> t) {
    final filteredSession = t.cast<Session>();
    for (var session in t) {
      if (!session.followers!.contains(userId)) {
        filteredSession.remove(session);
      }
    }
    return filteredSession;
  }
}
