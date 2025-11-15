import 'package:dear_claire/utils/filter.dart';
import 'package:dear_claire/ui/featured/model/session.dart';

/// This class is used to filter sessions.
class FeaturedSessionFilter implements ResultFilter<Session> {
  final String? userId;

  FeaturedSessionFilter(this.userId);

  @override
  List<Session> filter(List<dynamic> t) {
    if (userId == null) {
      return t.cast<Session>().toList();
    }
    return t
        .cast<Session>()
        .where((session) => !session.followers!.contains(userId))
        .toList();
  }
}
