import 'package:shared_preferences/shared_preferences.dart';

class HiddenPostsService {
  static const _hiddenPostsKey = 'hidden_post_ids';

  // Get the list of hidden post IDs
  Future<List<String>> getHiddenPostIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_hiddenPostsKey) ?? [];
  }

  // Add a post ID to the hidden list
  Future<void> hidePost(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> hiddenIds = await getHiddenPostIds();
    if (!hiddenIds.contains(postId)) {
      hiddenIds.add(postId);
      await prefs.setStringList(_hiddenPostsKey, hiddenIds);
    }
  }
}
