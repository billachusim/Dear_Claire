import 'package:clairediary/utils/filter.dart';
import 'package:clairediary/ui/featured/model/session.dart';

import '../../routes/routes.dart';

/// This class is used to filter session
class FeaturedSessionFilter implements ResultFilter {
  String? userId;

  FeaturedSessionFilter(this.userId);

  @override
  List<Session> filter(List<dynamic> t) {
    final filteredSession = t.cast<Session>();
    for (var session in t) {
      if (session.followers!.contains(userId)) {
        filteredSession.remove(session);
      }
    }
    return filteredSession;
  }




  List<Session> _featuredSessionsFilter(List<Session> _featuredSessionList) {
    final filteredSession = _featuredSessionList;
    for (var session in _featuredSessionList) {
      if (session.followers!.contains(currentUser?.uid)) {
        filteredSession.remove(session);
      }
    }
    return filteredSession;
  }
}
