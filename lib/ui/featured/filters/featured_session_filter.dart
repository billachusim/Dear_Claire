import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/utils/filter.dart';
import 'package:dear_claire/ui/featured/model/session.dart';

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
}
