import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/featured/model/session.dart';

class ReactionHandler {
  /// use the index to retrieve what the users reaction was
  static Map<String, Object?> returnReaction(int index, String _usersID,
      {bool addReaction = false}) {
    if (addReaction) {
      if (index == 0)
        return {
          'meToos': FieldValue.arrayUnion([_usersID])
        };
      if (index == 1)
        return {
          'meLove': FieldValue.arrayUnion([_usersID])
        };
      if (index == 2)
        return {
          'meHiFive': FieldValue.arrayUnion([_usersID])
        };
      if (index == 3)
        return {
          'meFlower': FieldValue.arrayUnion([_usersID])
        };
    } else {
      if (index == 0)
        return {
          'meToos': FieldValue.arrayRemove([_usersID])
        };
      if (index == 1)
        return {
          'meLove': FieldValue.arrayRemove([_usersID])
        };
      if (index == 2)
        return {
          'meHiFive': FieldValue.arrayRemove([_usersID])
        };
      if (index == 3)
        return {
          'meFlower': FieldValue.arrayRemove([_usersID])
        };
    }
    return {};
  }

  /// return the type of reaction list that is to be done
  static List reactionType(Session session, int index) {
    switch (index) {
      case 0:
        return session.meToos!;
      case 1:
        return session.meLove!;
      case 2:
        return session.meHiFive!;
      case 3:
        return session.meFlower!;
      default:
        return [];
    }
  }
}
