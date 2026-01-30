import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InAppReviewService {
  final InAppReview _inAppReview = InAppReview.instance;

  // --- CONFIGURATION ---
  // The number of comments a user needs to send before we ask for a review.
  static const int _commentThreshold = 5;
  // Key to store the comment count in SharedPreferences.
  static const String _commentCountKey = 'app_review_comment_count';
  // Key to store the timestamp of the last time we requested a review.
  static const String _lastReviewRequestKey = 'app_review_last_request_timestamp';


  /// Call this method every time the user successfully sends a comment.
  /// It increments the comment count and requests a review if the threshold is met.
  Future<void> incrementCommentCountAndRequestReview() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Get current comment count, defaulting to 0 if not set.
    int currentCount = prefs.getInt(_commentCountKey) ?? 0;
    currentCount++;

    print('InAppReviewService: Comment count is now $currentCount');

    // 2. Check if the count has reached our threshold.
    if (currentCount >= _commentThreshold) {
      if (await _canRequestReview(prefs)) {
        print('InAppReviewService: Threshold met. Requesting review.');

        // Request the review pop-up.
        if (await _inAppReview.isAvailable()) {
          _inAppReview.requestReview();
        }

        // Store the current time as the last request time.
        await prefs.setInt(_lastReviewRequestKey, DateTime.now().millisecondsSinceEpoch);

        // Reset the counter so we can start counting again for a future review request.
        await prefs.setInt(_commentCountKey, 0);
      } else {
        print('InAppReviewService: Threshold met, but it is too soon to ask again.');
        // Optionally, still reset the counter if you want the countdown to restart regardless.
        await prefs.setInt(_commentCountKey, 0);
      }
    } else {
      // If threshold is not met, just save the new count.
      await prefs.setInt(_commentCountKey, currentCount);
    }
  }

  /// Checks if enough time has passed since the last review request.
  /// This prevents us from spamming the user.
  Future<bool> _canRequestReview(SharedPreferences prefs) async {
    final lastRequestTimestamp = prefs.getInt(_lastReviewRequestKey);

    // If we've never requested a review before, we can request one.
    if (lastRequestTimestamp == null) {
      return true;
    }

    final lastRequestDate = DateTime.fromMillisecondsSinceEpoch(lastRequestTimestamp);
    final currentDate = DateTime.now();

    // Only allow a review request if it has been more than 90 days.
    // Apple's guidelines limit this to a few times a year. This is a safe interval.
    final difference = currentDate.difference(lastRequestDate).inDays;
    return difference > 90;
  }
}
