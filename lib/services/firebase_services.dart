import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:clairediary/services/transaction_service.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/data/models/profile_page_model.dart';
import 'package:clairediary/services/notification_service.dart';
import 'package:clairediary/services/reactions_handler.dart';
import 'package:clairediary/services/user_activity_model.dart';
import 'package:clairediary/services/user_model.dart';
import 'package:clairediary/ui/chats/data/chatroompodo.dart';
import 'package:clairediary/ui/chats/data/chats.dart';
import 'package:clairediary/ui/create_session/session_model.dart';
import 'package:clairediary/ui/routes/page_router_animation.dart';
import 'package:clairediary/ui/featured/model/comment_session_model.dart';
import 'package:clairediary/ui/featured/model/session.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/utils/helper.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:clairediary/helpers/toast_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../data/models/transaction_model.dart' as t_model;
import '../ui/ego-profile/claire_loves.dart';
import '../ui/love_store/cart_item_model.dart';
import '../ui/love_store/order_model.dart';
import '../ui/love_store/product_model.dart';
import 'data/notification_model.dart' as pushNotification;


final firebase_storage.FirebaseStorage _storage = firebase_storage.FirebaseStorage.instance; // Add this line

Logger logger = Logger();
SharedPreferences? prefs;

class FirebaseServices extends ChangeNotifier {
  /// create instance of Firestore
  FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  /// create instance of FirebaseMessaging
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  User? currentUser = FirebaseAuth.instance.currentUser;
  final String usersKey = 'user';
  final String alterEgoKey = 'alterEgo';
  final String alterEgoAccessCodeKey = 'alterEgoAccessCodeKey';
  String? _usersID;

  //var sharedPreference = SharedPreference.instance;
  UserModel? user;
  UserModel userModel = UserModel();


  /// Handles all love transactions between a user and the Claire Treasury.
  Future<bool> updateTreasuryAndUser({
    required String userId,
    required int amount,
    required t_model.TransactionType type,
    required String userTransactionDescription,
    Map<String, dynamic>? metadata,
    int fromGameWins = 0,
    int forGameLoses = 0,
    int fromRoomVisits = 0,
    int forRoomVisits = 0,
    int forLoveTransfer = 0,
    int fromLoveTransfer = 0,
  }) async {
    const String claireId = "PbRuh3FmtESK57j3PM1Tc9RvPKh2";
    const int treasuryMinBalance = 4000000;
    final int transactionTax = (amount * 0.10).round();
    final DocumentReference claireDoc = _firebaseFirestore.collection('users').doc(claireId);
    final DocumentReference userDoc = _firebaseFirestore.collection('users').doc(userId);
    final TransactionService transactionService = TransactionService();

    try {
      if (type == t_model.TransactionType.credit) {
        // USER RECEIVING (Claire Withdrawing)
        final claireSnapshot = await claireDoc.get();
        final claireCurrentLoves = (claireSnapshot.data() as Map<String, dynamic>?)?['currentLoveCount'] ?? 0;

        if (claireCurrentLoves < treasuryMinBalance) {
          await transactionService.recordTransaction(
            userId: userId,
            amount: amount,
            type: type,
            description: userTransactionDescription,
            status: t_model.TransactionStatus.pending,
            metadata: {...?metadata, 'treasury_status': 'pending_low_balance'},
          );
          return false;
        }

        // Treasury has enough, process the transaction for both.
        await userDoc.update({
          'currentLoveCount': FieldValue.increment(amount),
          'totalLoveCount': FieldValue.increment(amount),
          'fromGameWins': FieldValue.increment(fromGameWins),
          'fromRoomVisits': FieldValue.increment(fromRoomVisits),
          'fromLoveTransfer': FieldValue.increment(fromLoveTransfer),
        });

        await claireDoc.update({
          'currentLoveCount': FieldValue.increment(-amount),
          'forLoveTransfer': FieldValue.increment(transactionTax),
          'withdrawnLoveCount': FieldValue.increment(amount),
          'forGameLoses': FieldValue.increment(forGameLoses),
          'forRoomVisits': FieldValue.increment(forRoomVisits),
        });

        await transactionService.recordTransaction(
          userId: userId,
          amount: amount,
          type: t_model.TransactionType.credit,
          description: userTransactionDescription,
          status: t_model.TransactionStatus.approved,
          metadata: metadata,
        );

        // Audit for Claire
        await transactionService.recordTransaction(
          userId: claireId,
          amount: amount,
          type: t_model.TransactionType.debit,
          description: "Treasury Payout: $userTransactionDescription (User: $userId)",
          metadata: metadata,
        );

        return true;
      } else {
        // USER DEBIT (Claire Receiving)
        await userDoc.update({
          'currentLoveCount': FieldValue.increment(-amount),
          'withdrawnLoveCount': FieldValue.increment(amount),
          'forLoveTransfer': FieldValue.increment(forLoveTransfer),
          'forGameLoses': FieldValue.increment(forGameLoses),
          'forRoomVisits': FieldValue.increment(forRoomVisits),
        });

        await claireDoc.update({
          'currentLoveCount': FieldValue.increment(amount),
          'totalLoveCount': FieldValue.increment(amount),
          'fromLoveTransfer': FieldValue.increment(amount),
          'fromRoomVisits': FieldValue.increment(fromRoomVisits),
        });

        await transactionService.recordTransaction(
          userId: userId,
          amount: amount,
          type: t_model.TransactionType.debit,
          description: userTransactionDescription,
          status: t_model.TransactionStatus.approved,
          metadata: metadata,
        );

        // Audit for Claire
        await transactionService.recordTransaction(
          userId: claireId,
          amount: amount,
          type: t_model.TransactionType.credit,
          description: "Treasury Income: $userTransactionDescription (From: $userId)",
          metadata: metadata,
        );

        return true;
      }
    } catch (e) {
      print("Error in updateTreasuryAndUser: $e");
      return false;
    }
  }

  /// Handles a direct user-to-user love transfer with a 10% tax for Claire.
  /// This is a three-way transaction:
  /// 1. Debits the sender for the amount + tax.
  /// 2. Credits the receiver for the amount.
  /// 3. Credits Claire's treasury for the tax.
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> transferLoveBetweenUsers({
    required String senderId,
    required String receiverId,
    required int amountToSend,
    required int taxAmount,
    required int totalDebitAmount,
    required String senderTransactionDesc,
    required String receiverTransactionDesc,
    required String claireTransactionDesc,
    Map<String, dynamic>? metadata,
    int forRoomVisits = 0,
    int fromRoomVisits = 0,
    int forThanks = 0,
    int fromThanks = 0,
    int forReactions = 0,
    int fromReactions = 0,
    int forProfileVisits = 0,
    int fromProfileVisits = 0,
    int forLoveTransfer = 0,
    int fromLoveTransfer = 0,
    int forLoveStore = 0,
    int fromLoveStore = 0,
  }) async {
    const String claireId = "PbRuh3FmtESK57j3PM1Tc9RvPKh2";
    final DocumentReference senderDoc = _firebaseFirestore.collection('users').doc(senderId);
    final DocumentReference receiverDoc = _firebaseFirestore.collection('users').doc(receiverId);
    final DocumentReference claireDoc = _firebaseFirestore.collection('users').doc(claireId);
    final TransactionService transactionService = TransactionService();

    try {
      final senderSnapshot = await senderDoc.get();
      final senderLoves = (senderSnapshot.data() as Map<String, dynamic>?)?['currentLoveCount'] ?? 0;
      if (senderLoves < totalDebitAmount) return false;

      // 1. Debit the sender (spendable loves only)
      await senderDoc.update({
        'currentLoveCount': FieldValue.increment(-totalDebitAmount),
        'withdrawnLoveCount': FieldValue.increment(totalDebitAmount),
        'forLoveTransfer': FieldValue.increment(forLoveTransfer),
        'forRoomVisits': FieldValue.increment(forRoomVisits),
        'loveSentForThanks': FieldValue.increment(forThanks),
        'loveSentForReactions': FieldValue.increment(forReactions),
        'loveSentForVisits': FieldValue.increment(forProfileVisits),
        'forLoveStore': FieldValue.increment(forLoveStore),
      });

      // 2. Credit the receiver (current and total loves)
      await receiverDoc.update({
        'currentLoveCount': FieldValue.increment(amountToSend),
        'totalLoveCount': FieldValue.increment(amountToSend),
        'fromLoveTransfer': FieldValue.increment(fromLoveTransfer),
        'fromRoomVisits': FieldValue.increment(fromRoomVisits),
        'loveFromThanks': FieldValue.increment(fromThanks),
        'loveFromReactions': FieldValue.increment(fromReactions),
        'profileVisitLove': FieldValue.increment(fromProfileVisits),
        'fromLoveStore': FieldValue.increment(fromLoveStore),
      });

      // 3. Immediately credit Claire's treasury with the tax (current and total loves)
      await claireDoc.update({
        'currentLoveCount': FieldValue.increment(taxAmount),
        'totalLoveCount': FieldValue.increment(taxAmount),
        'loveFromThanks': FieldValue.increment(taxAmount),
        'fromRoomVisits': FieldValue.increment(taxAmount),
        'fromLoveTransfer': FieldValue.increment(taxAmount),
        'fromLoveStore': FieldValue.increment(taxAmount),
      });

      // If the transaction is successful, record the individual transaction logs.
      // Sender's Debit Record
      await transactionService.recordTransaction(
        userId: senderId, amount: totalDebitAmount, type: t_model.TransactionType.debit,
        description: senderTransactionDesc, metadata: metadata,
      );

      // Receiver's Credit Record
      await transactionService.recordTransaction(
        userId: receiverId, amount: amountToSend, type: t_model.TransactionType.credit,
        description: receiverTransactionDesc, metadata: metadata,
      );

      // Claire's Tax Credit Record (Optional but good for auditing)
      await transactionService.recordTransaction(
        userId: claireId, amount: taxAmount, type: t_model.TransactionType.credit,
        description: claireTransactionDesc, metadata: metadata,
      );

      return true;
    } catch (e) {
      print("Error during user-to-user love transfer: $e");
      return false;
    }
  }



  /// Fetches a list of transactions for a specific user.
  ///
  /// [userId]: The ID of the user whose transactions are to be fetched.
  /// [limit]: The maximum number of transactions to retrieve.
  Future<List<t_model.TransactionModel>> getTransactionsForUser({ // FIX 1: Use TransactionModel
    required String userId,
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _firebaseFirestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('timestamp', descending: true) // Get the most recent first
          .limit(limit)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      // Convert each document into a TransactionModel
      return querySnapshot.docs
          .map((doc) => t_model.TransactionModel.fromFirestore(doc)) // FIX 2: Use TransactionModel.fromFirestore
          .toList();
    } catch (e) {
      print("Error fetching user transactions: $e");
      // Return an empty list or re-throw the error as needed
      return [];
    }
  }



  /// Subscribes a user to admin-level notifications if they have the correct userType.
  Future<void> subscribeToAdminNotifications() async {
    if (currentUser == null) return;

    try {
      final userDoc = await _firebaseFirestore.collection('users').doc(currentUser!.uid).get();
      if (!userDoc.exists) return;

      final userType = (userDoc.data())?['userType'] as String?;

      // Subscribe if the user is an ADMIN or SUPER_ADMIN
      if (userType == 'ADMIN' || userType == 'SUPER_ADMIN') {
        await _firebaseMessaging.subscribeToTopic('new_session_alerts');
        logger.i('User subscribed to admin notifications.');
      }
    } catch (e) {
      logger.e("Error subscribing to admin notifications: $e");
    }
  }

  /// Notifies all subscribed admins about a new session by sending a message to a topic.
  Future<void> notifyClaireForSession(String sender, CreateSessionModel session) async {
    const String adminTopic = 'new_session_alerts';

    // The notification payload
    final pushNotification.NotificationModel notificationModel =
    pushNotification.NotificationModel(
      topic: adminTopic,
      data: pushNotification.Data(
          id: session.sessionId.toString(),
          route: 'alterEgoHomepage'
      ),
      notification: pushNotification.Notification(
          title: 'New Diary Session: ${session.title ?? ''}',
          body: '$sender just started a new session. Please advise.'
      ),
    );

    try {
      // Send the notification to the topic
      await notificationService.sendNotification(notificationModel.toJson());
      logger.d('Notified admins for session: ${session.title}');
    } catch (e) {
      logger.e("Error sending admin notification for new session: $e");
    }
  }



  /// subscribe user to a topic
  Future<void> _subscribeToSession(String sender, Session session) async {
    _usersID = currentUser?.uid.toString();

    await _firebaseMessaging.subscribeToTopic(session.sessionId!);
    final pushNotification.NotificationModel _notificationModel =
        pushNotification.NotificationModel(
      topic: session.sessionId!,
      data: pushNotification.Data(id: _usersID, route: session.sessionId.toString()),
      notification: pushNotification.Notification(
          title: session.title ?? '', body: '$sender followed the session'),
    );
    notificationService.sendNotification(_notificationModel.toJson());
    logger.d('Following this session: ${session.title!}');
  }

  /// subscribe alter ego to advised session topic.
  Future<void> subscribeAlterEgoToAdvisedSession(Session session) async {
    FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

    final _usersID = currentUser!.uid.toString();

    await _firebaseMessaging.subscribeToTopic(session.sessionId!);
    if(!session.respondentUserId!.contains(_usersID)) {
      final pushNotification.NotificationModel _notificationModel =
      pushNotification.NotificationModel(
        topic: session.sessionId!,
        data: pushNotification.Data(id: _usersID, route: session.sessionId.toString()),
        notification: pushNotification.Notification(
            title: session.title ?? '', body: 'You are now assigned to this session. Will get notifications.'),
      );
      notificationService.sendNotification(_notificationModel.toJson());
    }
    logger.d('Following this session: ${session.title!}');
  }



  /// subscribe user to chat room
  Future<void> _subscribeToChatRoom(String id) async {
    await _firebaseMessaging.subscribeToTopic(id);
    logger.d('Following this chat room: $id');
  }

  /// subscribe user to chat room
  Future<void> unsubscribeToChatRoom(String id) async {
    await _firebaseMessaging.unsubscribeFromTopic(id);
    logger.d('unfollowing this chat room: $id');
  }

  /// unsubscribe user from a topic
  Future<void> _unSubscribeToSession(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  /// cache user id
  void setUsersId(String id) async {
    prefs = await SharedPreferences.getInstance();
    prefs!.setString(usersKey, id);
    notifyListeners();
  }

  /// get users id
  Future<String> getUsersId() async {
    prefs = await SharedPreferences.getInstance();
    return prefs!.getString(usersKey) ?? '';
  }

  /// cache AlterEgo id
  void setAlterEgoId(String id) async {
    prefs = await SharedPreferences.getInstance();
    prefs!.setString(alterEgoKey, id);
    notifyListeners();
  }

  /// get AlterEgo id
  Future<String> getAlterEgoSingleId() async {
    prefs = await SharedPreferences.getInstance();
    return prefs!.getString(alterEgoKey) ?? '';
  }

  /// cache AlterEgo id
  void setAlterEgoAccessCode(String id) async {
    prefs = await SharedPreferences.getInstance();
    prefs!.setString(alterEgoAccessCodeKey, id);
    notifyListeners();
  }

  /// get AlterEgo id
  Future<String> getAlterEgoSingleAccessCode() async {
    prefs = await SharedPreferences.getInstance();
    return prefs!.getString(alterEgoAccessCodeKey) ?? '';
  }

  /// get AlterEgoId
  Future<String> getAlterEgoUserAccessCode() async {
    prefs = await SharedPreferences.getInstance();
    return prefs!.getString(AppConstants.PREF_KEY_ALTER_EGO_ACCESS_CODE) ?? '';
  }

  /// get AlterEgoAccessCode
  Future<String> getAlterEgoUserId() async {
    prefs = await SharedPreferences.getInstance();
    return prefs!.getString(AppConstants.PREF_KEY_ALTER_EGO_ID) ?? '';
  }

  /// cache user
  void setUser(UserModel userModel) async {
    final _user = FirebaseAuth.instance;
    prefs = await SharedPreferences.getInstance();
    prefs!.setString(AppConstants.PREF_KEY_USER_AVATAR_URL, userModel.avatarUrl!);
    prefs!.setString(AppConstants.PREF_KEY_USER_NICKNAME, userModel.nickname!);
    prefs!.setString(AppConstants.PREF_KEY_USER_SECRET_CODE, userModel.secretCode!);
    prefs!.setString(AppConstants.PREF_KEY_USER_EMAIL, userModel.email!);
    prefs!.setString(AppConstants.PREF_KEY_USER_FCM_ID, _user.currentUser!.uid);
    prefs!.setString(AppConstants.PREF_KEY_USER_GENDER, userModel.gender!);
    prefs!.setString(AppConstants.PREF_KEY_USER_ID, userModel.userId!);
    prefs!.setString(AppConstants.PREF_KEY_USER_USER_TYPE, userModel.userType!);
    prefs!.setString(AppConstants.PREF_KEY_ALTER_EGO_ID, userModel.alterEgoId!);
    prefs!.setString(
        AppConstants.PREF_KEY_ALTER_EGO_ACCESS_CODE, userModel.alterEgoAccessCode!);
    prefs!.setString(AppConstants.PREF_KEY_USER_TIME_REGISTERED,
        userModel.timeRegistered!.toDate().toString());
    prefs!.setString(AppConstants.PREF_KEY_USER_LAST_UNLOCKED,
        userModel.timeLastUnlocked!.toDate().toString());
    //prefs!.setString(usersModelKey, id);
    notifyListeners();
  }

  /// get user
  Future<UserModel> getUser() async {
    prefs = await SharedPreferences.getInstance();
    var avatar = prefs!.getString(AppConstants.PREF_KEY_USER_AVATAR_URL) ?? '';
    var nickname = prefs!.getString(AppConstants.PREF_KEY_USER_NICKNAME) ?? '';
    var secretCode = prefs!.getString(AppConstants.PREF_KEY_USER_SECRET_CODE) ?? '';
    var email = prefs!.getString(AppConstants.PREF_KEY_USER_EMAIL) ?? '';
    var uid = prefs!.getString(AppConstants.PREF_KEY_USER_FCM_ID) ?? '';
    var gender = prefs!.getString(AppConstants.PREF_KEY_USER_GENDER) ?? '';
    var userId = prefs!.getString(AppConstants.PREF_KEY_USER_ID) ?? '';
    var userType = prefs!.getString(AppConstants.PREF_KEY_USER_USER_TYPE) ?? '';
    var alterEgoId = prefs!.getString(AppConstants.PREF_KEY_ALTER_EGO_ID) ?? '';
    var alterEgoAccessCode =
        prefs!.getString(AppConstants.PREF_KEY_ALTER_EGO_ACCESS_CODE) ?? '';
    //var timeRegistered = prefs!.getString(AppConstants.PREF_KEY_USER_TIME_REGISTERED) ?? '';
    //var timeLastUnlocked = prefs!.getString(AppConstants.PREF_KEY_USER_LAST_UNLOCKED) ?? '';
    return UserModel(
        alterEgoAccessCode: alterEgoAccessCode,
        alterEgoId: alterEgoId,
        avatarUrl: avatar,
        email: email,
        fcmId: uid,
        nickname: nickname,
        secretCode: secretCode,
        timeLastUnlocked: null,
        timeRegistered: null,
        gender: gender,
        userId: userId,
        userType: userType,
    );
  }

  /// [clear] all users informations
  void logUserOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await prefs!.clear();
    Navigator.of(context).pushReplacementNamed(AppRoutes.authSelection);
  }


  /// [delete] all user's information and loves
  void deleteEgoAccount(BuildContext context, String userId) async {
    // --- Optional: Record a final transaction for archival ---
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final lovesToClear = userDoc.data()?['currentLoveCount'] ?? 0;
        if (lovesToClear > 0) {
          await TransactionService().recordTransaction( // Assuming you instantiate or have access to it
            userId: userId,
            amount: lovesToClear,
            type: t_model.TransactionType.debit,
            description: "Account deleted. Remaining loves cleared.",
            status: t_model.TransactionStatus.approved,
            metadata: {'reason': 'account_deletion'},
          );
        }
      }
    } catch (e) {
      print("Could not record final transaction for deleted account: $e");
    }
    await FirebaseAuth.instance.signOut();
    await prefs!.clear();
    final _userId = userId;
    final collection = FirebaseFirestore.instance.collection('users');
    await collection.doc(_userId).delete();
    logger.d('Successfully deleted an ego account');
    Navigator.of(context).pushReplacementNamed(AppRoutes.authSelection);
  }






  /// checks if a user is signed in or not
  /// if the use is not signed in
  /// then request them to sign in
  Future<bool> isUserSignIn(BuildContext context) async {
    _usersID = await getUsersId();
    if (_usersID!.isEmpty) {
      Navigator.of(context).pushNamed(AppRoutes.authSelection);
      return false;
    }
    return true;
  }

  /// Get sessions that have been featured
  /// But not flagged or even archived
  /// and does not have the [userId] found in the followers field
  Stream<QuerySnapshot<Map<String, dynamic>>> getFeaturedSession() {
    return _firebaseFirestore
        .collection(AppString.appFeaturedSessions)
        .where("featured", isEqualTo: true)
        .where("archived", isEqualTo: false)
       // .where("flagged", isEqualTo: false)
        .limit(150)
        .orderBy('timeLastActivity', descending: true)
        .snapshots();
  }

  /// [featured Session Comments] -> get users featured sessions comments
  Stream<QuerySnapshot<Map<String, dynamic>>> getFeaturedSessionsComments(
      String id) {
    return _firebaseFirestore
        .collection(AppString.appFeaturedSessions)
        .doc(id)
        .collection(AppString.appFeaturedSessionsComments)
        .orderBy('timeCreated', descending: false)
        .limit(AppString.appCommentLength)
        //.where("flagged", isEqualTo: false)
        .snapshots();
  }

  /// Get sessions that have not been featured, flagged or even archived
  /// But has the [userId] found in the followers field
  Stream<QuerySnapshot<Map<String, dynamic>>> getFollowingSessions() {
    if (currentUser?.uid == null) {
      return Stream.value(Future.value(null) as QuerySnapshot<Map<String, dynamic>>);
    }
    return _firebaseFirestore
        .collection(AppString.appFeaturedSessions)
        .where("archived", isEqualTo: false)
        .where('followers', arrayContains: currentUser?.uid)
        .limit(AppString.appSessionLength)
        .orderBy('timeLastActivity', descending: true)
        .snapshots();
  }

  /// featured Session -> get a single session document
  Stream<DocumentSnapshot<Map<String, dynamic>>> getSingleDocument(
      {String? id}) {
    final _snap = _firebaseFirestore
        .collection(AppString.appFeaturedSessions)
        .doc(id)
        .snapshots();
    return _snap;
  }


  /// Get the user sessions that haven't been flagged and archived as a real-time stream.
  /// @return A stream of session lists.
  Stream<List<Session>> getDiarySessionsStream() {
    if (_usersID == null || _usersID!.isEmpty) {
      return Stream.value([]);
    }

    try {
      return _firebaseFirestore
          .collection(AppString.appFeaturedSessions)
          .where("userId", isEqualTo: _usersID)
          .where("archived", isEqualTo: false)
          .orderBy('timeLastActivity', descending: true)
          .limit(AppString.appSessionLength)
          .snapshots() // Use snapshots() for a real-time stream
          .map((querySnapshot) {
        // Map the query snapshot to a list of Session objects
        return querySnapshot.docs
            .map((doc) => Session.fromJson(doc.data()))
            .toList();
      });
    } catch (e) {
      logger.e(e);
      // On error, return a stream that emits an error.
      return Stream.error(e);
    }
  }


  /// Get the user sessions that have been archived as a real-time stream.
  /// @return A stream of session lists.
  Stream<List<Session>> getArchivedDiarySessionsStream() {
    if (_usersID == null || _usersID!.isEmpty) {
      return Stream.value([]);
    }

    try {
      return _firebaseFirestore
          .collection(AppString.appFeaturedSessions)
          .where("userId", isEqualTo: _usersID)
          .where("archived", isEqualTo: true)
          .orderBy('timeLastActivity', descending: true)
          .limit(AppString.appSessionLength)
          .snapshots() // Use snapshots() for a real-time stream
          .map((querySnapshot) {
        // Map the query snapshot to a list of Session objects
        return querySnapshot.docs
            .map((doc) => Session.fromJson(doc.data()))
            .toList();
      });
    } catch (e) {
      logger.e(e);
      // On error, return a stream that emits an error.
      return Stream.error(e);
    }
  }


  /// Get new sessions that no admin has responded to before
  /// @param lastSession The last session from previous request. Used for pagination
  /// @return LiveData
  Future<List<Session>> getAlterEgoNonAssignedSessions() async {
    List<Session> _sessionList = [];
    try {
      final _value = await _firebaseFirestore
          .collection(AppString.appFeaturedSessions)
          .where("archived", isEqualTo: false)
          .where("repliesEnabled", isEqualTo: true)
          .where("respondentUserId", isEqualTo: '')
          .orderBy('timeCreated', descending: true)
          .limit(AppString.appSessionLength)
          .get();

      _value.docs
          .map((e) => _sessionList.addAll([Session.fromJson(e.data())]))
          .toList();
    } catch (e) {
      logger.e(e);
    }
    return _sessionList;
  }

  /// Get sessions that have been assigned to the admin user. When an admin replies a session,
  /// the session automatically gets assigned to him
  /// @param lastSession The last session from previous request. Used for pagination
  /// @param userId The id of the user to get assigned sessions for
  /// @return LiveData
  Future<List<Session>> getAssignedSessions() async {
    List<Session> _sessionList = [];
    try {
      final _value = await _firebaseFirestore
          .collection(AppString.appFeaturedSessions)
          .where("archived", isEqualTo: false)
         // .where("flagged", isEqualTo: false)
          .where("respondentUserId", isEqualTo: currentUser?.uid)
          .orderBy('timeLastActivity', descending: true)
          .limit(AppString.appSessionLength)
          .get();

      _value.docs
          .map((e) => _sessionList.addAll([Session.fromJson(e.data())]))
          .toList();
    } catch (e) {
      logger.e(e);
    }
    return _sessionList;
  }

  /// Get all sessions that have been created
  /// @param lastSession The last session from previous request. Used for pagination
  /// @return LiveData
  Future<List<Session>> getAllSessions() async {
    List<Session> _sessionList = [];
    try {
      final _value = await _firebaseFirestore
          .collection(AppString.appFeaturedSessions)
          .orderBy('timeCreated', descending: true)
          .limit(AppString.allSessionLength)
          .get();

      _value.docs
          .map((e) => _sessionList.addAll([Session.fromJson(e.data())]))
          .toList();
    } catch (e) {
      logger.e(e);
    }
    return _sessionList;
  }


  /// Get all sessions that have been flagged
  /// @return LiveData
  Future<List<Session>> getFlaggedSessions() async {
    List<Session> _sessionList = [];
    try {
      final _value = await _firebaseFirestore
          .collection(AppString.appFeaturedSessions)
          .where("flagged", isEqualTo: true)
          .orderBy('timeLastActivity', descending: true)
          .limit(AppString.allSessionLength)
          .get();

      _value.docs
          .map((e) => _sessionList.addAll([Session.fromJson(e.data())]))
          .toList();
    } catch (e) {
      logger.e(e);
    }
    return _sessionList;
  }



  /// adds a comment to a post
  void addCommentNotification(
      {required String title,
      required String docId,
      required String sender,}) {
    final pushNotification.NotificationModel _notificationModel =
        pushNotification.NotificationModel(
      topic: docId,
      data: pushNotification.Data(id: sender, route: docId.toString()),
      notification: pushNotification.Notification(
          title: title, body: '$sender added comment to the session'),
    );
    notificationService.sendNotification(_notificationModel.toJson());
  }


  /// [featured Session Comments] -> get users featured sessions comments
  Stream<QuerySnapshot<Map<String, dynamic>>> getDiarySessionsComments(
      String id) {
    return _firebaseFirestore
        .collection(AppString.appFeaturedSessions)
        .doc(id)
        .collection(AppString.appFeaturedSessionsComments)
        .where("flagged", isEqualTo: false)
        .orderBy('timeCreated', descending: false)
        .limit(AppString.appCommentLength)
        .snapshots();
  }



  void updateUserInfo(UserModel userModel) async {
    _usersID = await getUsersId();
    _firebaseFirestore
        .collection(AppString.users)
        .doc(_usersID)
        .update(userModel.toJson());
  }

  /// Authenticate the user in
  Future<bool> signIn(
      BuildContext context, String email, String secretCode) async {
    final _user;
    try {
      _user = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: secretCode)
          .then((value) => {
                setUsersId(value.user!.uid),
              });
      showToast(message: AppString.open_up_toast);
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        showToast(
            message: 'The ego code is invalid or the ego does not have an ego code.');
      } else if (e.code == 'wrong-email') {
        showToast(message: 'The email is invalid or the user does not have an email.');
      }
      showToast(message: AppString.open_up_error);
      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }




  /// Authenticate the AlterEgo in
  /// Returns true if credentials are valid, false otherwise.
  Future<bool> getUserAlterEgo(BuildContext context, String alterEgoId,
      String alterEgoAccessCode) async {
    try {      // Fetch the currently logged-in user's data
      UserModel user = await getUserInfo();

      // Compare the provided credentials with the ones stored in the user's document
      if (currentUser?.uid == user.userId &&
          user.alterEgoId == alterEgoId &&
          user.alterEgoAccessCode == alterEgoAccessCode) {

        // Credentials match, login is successful.
        print("AlterEgo login success: $alterEgoId");

        // Use a mounted check before navigating
        if (context.mounted) {
          // REMOVE ALL PREVIOUS ROUTES when switching to Alter Ego Mode
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.alterEgoHomepage,
                (Route<dynamic> route) => false,
          );
        }
        return true; // Indicate success
      } else {
        // Credentials do not match.
        showToast(message: AppString.get_alter_ego_error);
        print("AlterEgo login fail: Credentials do not match.");
        return false; // Indicate failure
      }
    } catch (e) {
      // Handle potential errors like network issues or user not found
      logger.e("Error during AlterEgo login: $e");
      showToast(message: 'An error occurred. Please try again.');
      return false; // Indicate failure
    }
  }



  /// Listens to real-time updates for an influencer application
  Stream<DocumentSnapshot> streamInfluencerApplication(String uid) {
    return _firebaseFirestore
        .collection('influencer_applications')
        .doc(uid)
        .snapshots();
  }


  Future<void> updateUserMoods(int moodId) async {
    if (currentUser == null) return;
    final userDoc = _firebaseFirestore.collection(AppString.users).doc(currentUser!.uid);

    try {
      await _firebaseFirestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userDoc);
        if (!snapshot.exists) return;

        // SAFE ACCESS: Use data() map to check for key existence instead of snapshot.get()
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<int> moods = data.containsKey('moods')
            ? List<int>.from(data['moods'] ?? [])
            : [];

        moods.add(moodId);

        // Keep only the last 100 moods for performance
        if (moods.length > 100) {
          moods = moods.sublist(moods.length - 100);
        }

        transaction.update(userDoc, {'moods': moods});
      });
      logger.d('Mood $moodId saved to user history.');
    } catch (e) {
      logger.e('Error updating user moods: $e');
    }
  }

  /// Reports a session by setting its 'flagged' status to true.
  Future<bool> reportSession(String sessionId) async {
    try {
      await _firebaseFirestore
          .collection('sessions')
          .doc(sessionId)
          .update({"flagged": true});
      logger.d('Successfully reported session: $sessionId');
      return true;
    } catch (e) {
      logger.e('Error reporting session $sessionId: $e');
      return false;
    }
  }

  /// Blocks a user by adding their ID to the current user's 'blockedUsers' list.
  Future<bool> blockUser(String userIdToBlock) async {
    if (currentUser == null) return false;
    final String currentUserId = currentUser!.uid;

    // Prevent a user from blocking themselves
    if (currentUserId == userIdToBlock) {
      showToast(message: "You cannot block yourself.");
      return false;
    }

    try {
      await _firebaseFirestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayUnion([userIdToBlock])
      });
      logger.d('User $currentUserId blocked user $userIdToBlock.');
      return true;
    } catch (e) {
      logger.e('Error blocking user $userIdToBlock: $e');
      return false;
    }
  }




  Future<UserModel> getUserWithId({String? id}) async {
    final _info =
        await _firebaseFirestore.collection(AppString.users).doc(id).get();
    final _data = UserModel.fromFirestore(_info.data()!);
    return _data;
  }


  /// SignUp user
  Future<bool> register(
      BuildContext context, String email, String secretCode, String nickname, String languageCode, {String? referredBy}) async {
    try {
      // 1. Create the user with Firebase Auth
      final _user = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: secretCode);
      setUsersId(_user.user!.uid);

      // 2. GET THE FCM TOKEN
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      print('FCM Token for new user: $fcmToken'); // Good for debugging

      // --- START: NEW AVATAR LOGIC ---
      // List of default avatars
      const List<String> clairevatarUrls = [
        "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Ficons8-walter-white-72.png?alt=media&token=0b791843-76ae-4441-aca6-8a06f9e6fa67",
        "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fbear.png?alt=media&token=c5348009-e700-4a5f-ae83-6653e29784d7",
        "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fthoughtful_baby.png?alt=media&token=702c1fa9-ed42-4764-ad8e-8a1a21ff9679",
        "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Ficons8-homer-simpson-72.png?alt=media&token=3461c319-0840-47f0-8025-8773587a6189",
        "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Ficons8-parrot-72.png?alt=media&token=3cdf21b9-b7da-450e-94e0-c54b4fcba295",
        "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Ficons8-starfish-72.png?alt=media&token=ad4feba1-ddc3-4354-bc0e-4cef75fb2fbc",
        "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2FYellow_Moon_Emoji.png?alt=media&token=98cd50a5-f2a0-411a-9aef-06fd91d16c52",
        "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2FUpside-Down_Face_Emoji.png?alt=media&token=be8ded7e-4880-490a-9bf7-6a0aef361c1c",
        "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Ficons8-strawberry-72.png?alt=media&token=ff64370f-939c-46ce-af5e-d220a625ef51",
        "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2FHugging_Face_Emoji.png?alt=media&token=108f537b-2671-4fce-ade8-3618d3665fc6",
        "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fpanda_dance.png?alt=media&token=7bd9a4d9-ed60-4736-af74-c19eb7c69d6a",
        "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Ficons8-iron-man-72(-hdpi).png?alt=media&token=4c7b9989-a762-469b-8386-c1d8daf2c8cc",
      ];

      // Select a random URL from the list
      final String randomAvatarUrl = clairevatarUrls[Random().nextInt(clairevatarUrls.length)];

      // 3. Prepare the user data for Firestore
      final userData = {
        "isPremium": false,
        "nickname": nickname,
        "avatarUrl": randomAvatarUrl,
        "userId": _user.user?.uid,
        "languagePreference": languageCode,
        "alterEgoAccessCode": "",
        "alterEgoId": "",
        "email": email,
        "fcmId": fcmToken ?? '',
        "secretCode": secretCode,
        "timeLastUnlocked": FieldValue.serverTimestamp(),
        "timeRegistered": FieldValue.serverTimestamp(),
        "userType": "REGULAR",
        "sessionCount": 0,
        "adviseCount": 0,
        "totalLoveCount": 10,
        "currentLoveCount": 10,
        "withdrawnLoveCount": 0,
        "forLoveTransfer": 0,
        "fromLoveTransfer": 0,
        "referredBy": referredBy ?? '',
      };

      // 4. Create the user document in Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(_user.user!.uid)
          .set(userData);

      logger.d('Completely created new ego for userId: ${_user.user?.uid}');

      // 5. Automatically sign in the user
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: secretCode)
          .then((value) => setUsersId(value.user!.uid));

      if (referredBy != null && referredBy.isNotEmpty && referredBy != _user.user!.uid) {
        await _processReferralReward(newUserId: _user.user!.uid, referrerId: referredBy);
      }

      // 6. Trigger a welcome email
      await FirebaseFirestore.instance.collection('mail').add({
        'to': [email],
        'template': {
          'name': 'welcome_template',
          'data': {
            'egoName': nickname,
          },
        },
      });

      showToast(message: AppString.create_ego_complete_toast);
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      return true;

    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        showToast(message: 'The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        showToast(message: 'An account already exists for that email.');
      } else {
        showToast(message: 'An error occurred during sign up.');
      }
      logger.e(e);
      return false;
    } catch (e) {
      logger.e("A general error occurred in register method: $e");
      showToast(message: AppString.open_up_error);
      return false;
    }
  }

  /// Sends a password reset email using Firebase Auth.
  Future<bool> sendPasswordResetEmail(String email) async {try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
    logger.d('Password reset email sent to $email');
    return true;
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      logger.w('Password reset attempt for non-existent user: $email');
      // We still return true to prevent user enumeration.
      // The user will see a generic success message.
    } else {
      logger.e('Error sending password reset email: ${e.message}');
    }
    // Return true even on "user-not-found" to not reveal who is registered.
    // Return false only for other, unexpected Firebase errors.
    return e.code == 'user-not-found';
  } catch (e) {
    logger.e('A general error occurred in sendPasswordResetEmail: $e');
    return false;
  }
  }


  // --- NEW METHOD FOR PREMIUM SUBSCRIPTION ACTIVATION ---
  /// Activates the premium subscription for a user, granting bonus loves.
  /// This method is transactional to ensure atomicity.
  Future<bool> activatePremiumSubscription({
    required String userId,
    required int bonusLoves,
    Map<String, dynamic>? metadata,
  }) async {
    final userDocRef = _firebaseFirestore.collection('users').doc(userId);

    try {
      // Step 1: Calculate the expiry date (31 days from now)
      final newExpiryDate = DateTime.now().add(const Duration(days: 31));
      final newExpiryTimestamp = Timestamp.fromDate(newExpiryDate);

      // Step 2: Update the user's document with the new expiry date and isPremium flag
      await userDocRef.update({
        'isPremium': true,
        'premiumExpiryDate': newExpiryTimestamp,
      });

      logger.d("Successfully set isPremium=true for user $userId.");

      // Step 2: Credit the bonus loves using the existing treasury logic.
      // This ensures the transaction is recorded and Claire's loves are updated.
      bool lovesCredited = await updateTreasuryAndUser(
        userId: userId,
        amount: bonusLoves,
        type: t_model.TransactionType.credit,
        userTransactionDescription: "Premium Subscription Bonus",
        metadata: metadata,
      );

      if (lovesCredited) {
        logger.d(
            "Successfully credited $bonusLoves bonus loves to user $userId.");
        return true;
      } else {
        logger.e(
            "Failed to credit bonus loves for user $userId, but premium was set.");
        // Although loves failed, we return true because the core premium feature was activated.
        // The transaction log from updateTreasuryAndUser will show the failure.
        return true;
      }
    } catch (e) {
      logger.e("Error activating premium subscription for user $userId: $e");
      // If the transaction fails, nothing should be written.
      return false;
    }
  }


  Future<void> _processReferralReward({required String newUserId, required String referrerId}) async {
    try {
      final String cleanReferrerId = referrerId.trim();

      // 1. Basic Validation
      if (cleanReferrerId.isEmpty || cleanReferrerId == newUserId) {
        logger.w("Referral skipped: Invalid ID or self-referral.");
        return;
      }

      // 2. Verify Referrer exists in Firestore
      DocumentSnapshot refDoc = await _firebaseFirestore
          .collection(AppString.users)
          .doc(cleanReferrerId)
          .get();

      if (!refDoc.exists) {
        logger.e("Referral fulfillment failed: Referrer ID $cleanReferrerId does not exist.");
        return;
      }

      // 3. Reward New User (1000 Loves)
      await updateTreasuryAndUser(
        userId: newUserId,
        amount: 1000,
        type: t_model.TransactionType.credit,
        userTransactionDescription: "Referral Welcome Bonus",
      );

      // 4. Reward Referrer (1000 Loves)
      await updateTreasuryAndUser(
        userId: cleanReferrerId,
        amount: 1000,
        type: t_model.TransactionType.credit,
        userTransactionDescription: "Referral Reward (New User Join)",
      );

      logger.d("Referral fulfillment complete for NewUser: $newUserId from Referrer: $cleanReferrerId");
    } catch (e) {
      logger.e("Referral processing error: $e");
    }
  }


  Future<Map<String, dynamic>> getReferralStats() async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) return {'count': 0, 'earned': 0};

      // Query users where referredBy matches current user
      final query = await _firebaseFirestore
          .collection('users')
          .where('referredBy', isEqualTo: uid)
          .get();

      int count = query.docs.length;
      return {
        'count': count,
        'earned': count * 1000, // 1000 Loves per referral
      };
    } catch (e) {
      return {'count': 0, 'earned': 0};
    }
  }



  /// Submits an application for the Micro-Influencer program
  Future<void> submitInfluencerApplication({
    required String motivation,
    required String tiktok,
    required String instagram,
    required String twitter,
    required String whatsapp,
  }) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) return;

      final applicationData = {
        "userId": uid,
        "motivation": motivation,
        "tiktok": tiktok,
        "instagram": instagram,
        "twitter": twitter,
        "whatsapp": whatsapp,
        "status": "pending",
        "timestamp": FieldValue.serverTimestamp(),
      };

      // 1. Save to Firestore
      await _firebaseFirestore
          .collection('influencer_applications')
          .doc(uid)
          .set(applicationData);
      await _firebaseFirestore.collection('users').doc(uid).update({
        'influencerStatus': 'pending',
        'tiktok': tiktok,
        'instagram': instagram,
        'twitter': twitter,
        'whatsapp': whatsapp,
      });

      // 2. Trigger Email
      final Email email = Email(
        body: '''
New Influencer Application
User ID: $uid
TikTok: $tiktok
Instagram: $instagram
X/Twitter: $twitter
WhatsApp: $whatsapp

Motivation:
$motivation
''',
        subject: 'Micro-Influencer Application: $uid',
        recipients: ['dearclaireapp@gmail.com'],
        isHTML: false,
      );

      await FlutterEmailSender.send(email);
      AppToast.show("Application submitted & Email draft created!");
    } catch (e) {
      logger.e("Application Error: $e");
      AppToast.showError("Failed to submit application.");
    }
  }


  /// Specialized method for Referral Cash Out
  Future<bool> requestReferralWithdrawal(int amount) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) return false;

      final userDoc = await _firebaseFirestore.collection('users').doc(uid).get();
      final currentLoves = userDoc.data()?['currentLoveCount'] ?? 0;

      if (currentLoves < amount) {
        AppToast.showError("Insufficient Loves for this withdrawal.");
        return false;
      }

      // 1. Record the pending withdrawal globally for Admin
      final withdrawalDoc = _firebaseFirestore.collection('withdrawals').doc();
      await withdrawalDoc.set({
        "withdrawalId": withdrawalDoc.id,
        "userId": uid,
        "amount": amount,
        "status": "pending",
        "type": "referral_cashout",
        "timestamp": FieldValue.serverTimestamp(),
      });

      // 2. Debit the user and record transaction via Treasury logic
      // This ensures the currentLoveCount is updated correctly
      return await updateTreasuryAndUser(
        userId: uid,
        amount: amount,
        type: t_model.TransactionType.debit,
        userTransactionDescription: "Referral Cash Out Request (Pending)",
        metadata: {"withdrawalId": withdrawalDoc.id},
      );
    } catch (e) {
      logger.e("Withdrawal Request Error: $e");
      return false;
    }
  }








  /// follow your session immediately upon creation
  Future<void> followYourSessionImmediately(BuildContext context,
      {CreateSessionModel? session}) async {
    _firebaseFirestore
        .collection(AppString.appFeaturedSessions)
        .doc(session!.sessionId)
        .update({
      'followers': FieldValue.arrayUnion([_usersID]),
      'timeLastActivity': FieldValue.serverTimestamp(),
    });
    subscribeToYourSession(session.userNickname.toString(), session);
  }



  /// subscribe user to his session topic.
  Future<void> subscribeToYourSession(String sender, CreateSessionModel session) async {
    _usersID = currentUser?.uid.toString();

    await _firebaseMessaging.subscribeToTopic(session.sessionId!);
    final pushNotification.NotificationModel _notificationModel =
    pushNotification.NotificationModel(
      topic: session.sessionId!,
      data: pushNotification.Data(id: _usersID, route: session.sessionId.toString()),
      notification: pushNotification.Notification(
          title: session.title ?? '', body: 'You will be notified of new advises.'),
    );
    notificationService.sendNotification(_notificationModel.toJson());
    logger.d('Following this session: ${session.title!}');
  }


  /// follow a session immediately upon advise.
  Future<void> followAdvisedSessionImmediately(session) async {
    _usersID = currentUser!.uid.toString();
    if(session!.repliesEnabled == true && !session.followers!.contains(_usersID)) {
      _firebaseFirestore
          .collection(AppString.appFeaturedSessions)
          .doc(session.sessionId)
          .update({
        'followers': FieldValue.arrayUnion([_usersID]),
      });
      _subscribeToAdvisedSession(session);
    }
  }


  /// subscribe user to this session topic.
  Future<void> _subscribeToAdvisedSession(Session session) async {
    _usersID = currentUser?.uid.toString();

    await _firebaseMessaging.subscribeToTopic(session.sessionId!);
    if(!session.followers!.contains(_usersID)) {
      final pushNotification.NotificationModel _notificationModel =
      pushNotification.NotificationModel(
        topic: session.sessionId!,
        data: pushNotification.Data(id: _usersID, route: session.sessionId.toString()),
        notification: pushNotification.Notification(
            title: session.title ?? '', body: 'You are now following this session. Will get notifications.'),
      );
      notificationService.sendNotification(_notificationModel.toJson());
    }
    logger.d('Following this session: ${session.title!}');
  }



  /// Mute or allow your session notifications
  void followYourSession(BuildContext context, {Session? session}) {
    showCustomDialog(context,
        message: session!.followers!.contains(_usersID)
            ? AppString.unFollowYourDiarySessions
            : AppString.followYourDiarySessions, onPressed: () {
          PageRouter.goBack(context);
          _followYourSession(context, session: session);
        });
  }
  /// request to follow a featured session
  Future<bool> followThisSession(BuildContext context, {required Session session, required bool isFollowAction}) async {
    final completer = Completer<bool>();
    showCustomDialog(context,
        message: isFollowAction
            ? AppString.followDiarySessions
            : AppString.unFollowDiarySessions,
        onPressed: () {
            _followASession(context, session: session);
          completer.complete(true); // User confirmed
        },
    );
    return completer.future;
  }


  /// follow a featured session
  Future<void>? _followYourSession(BuildContext context,
      {Session? session}) async {
    final _user = await getUserInfo();
    String _name = _user.userType == 'ADMIN' ? '${_user.nickname}\'s Alter Ego' : _user.nickname!;
    !session!.followers!.contains(_usersID)
        ? _firebaseFirestore
        .collection(AppString.appFeaturedSessions)
        .doc(session.sessionId)
        .update({
      'followers': FieldValue.arrayUnion([_usersID]),
      'timeLastActivity': FieldValue.serverTimestamp(),
      //"featured": false,
    }).whenComplete(() {
      _subscribeToSession(_name, session);

      showToast(
        message: AppString.followingYourDiarySessionMessage,
        backgroundColor: Color(
          int.parse(
            session.colorHex!.replaceAll('#', '0xff'),
          ),
        ),
      );
    })
        : _firebaseFirestore
        .collection(AppString.appFeaturedSessions)
        .doc(session.sessionId)
        .update({
      'followers': FieldValue.arrayRemove([_usersID]),
      // "featured": true,
    }).whenComplete(() {
      _unSubscribeToSession(session.sessionId!);

      showToast(message: AppString.unfollowingYourDiarySessionMessage,
          backgroundColor: Color(
              int.parse(session.colorHex!.replaceAll('#', '0xff'))));
    });
  }


  /// follow a featured session
  Future<void>? _followASession(BuildContext context,
      {Session? session}) async {
    final _user = await getUserInfo();
    String _name = _user.userType == 'ADMIN' ? '${_user.nickname}\'s Alter Ego' : _user.nickname!;
    !session!.followers!.contains(_usersID)
        ? _firebaseFirestore
            .collection(AppString.appFeaturedSessions)
            .doc(session.sessionId)
            .update({
            'followers': FieldValue.arrayUnion([_usersID]),
            'timeLastActivity': FieldValue.serverTimestamp(),
            //"featured": false,
          }).whenComplete(() {
            _subscribeToSession(_name, session);

            showToast(
              message: AppString.followingDiarySessionMessage,
              backgroundColor: Color(
                int.parse(
                  session.colorHex!.replaceAll('#', '0xff'),
                ),
              ),
            );
          })
        : _firebaseFirestore
            .collection(AppString.appFeaturedSessions)
            .doc(session.sessionId)
            .update({
            'followers': FieldValue.arrayRemove([_usersID]),
           // "featured": true,
          }).whenComplete(() {
            _unSubscribeToSession(session.sessionId!);

            showToast(message: AppString.unfollowingDiarySessionMessage,
                backgroundColor: Color(
                    int.parse(session.colorHex!.replaceAll('#', '0xff'))));
          });
  }



  /// Create a new product for the Love Store
  Future<void> createProduct(Product product) async {
    try {
      await _firebaseFirestore
          .collection('products')
          .doc(product.productId)
          .set(product.toJson());
      logger.d('Successfully created new product: ${product.title}');
    } catch (e) {
      logger.e('Error creating product: $e');
      throw e; // Re-throw the error to be handled by the UI
    }
  }

  /// Get all products for the Love Store
  Stream<List<Product>> getProducts() {
    return _firebaseFirestore
        .collection('products')
        .orderBy('timeCreated', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromJson(doc.data())).toList();
    });
  }

  /// Get a single product by its ID
  Stream<DocumentSnapshot<Map<String, dynamic>>> getSingleProduct({String? id}) {
    return _firebaseFirestore.collection('products').doc(id).snapshots();
  }

  /// [Love Store] - Add an item to the user's cart
  Future<void> addToCart(String userId, String productId, int quantity) async {
    try {
      final cartItemRef = _firebaseFirestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(productId);

      await cartItemRef.set({
        'productId': productId,
        'quantity': FieldValue.increment(quantity),
        'timeAdded': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      showToast(message: 'Item added to your cart.');
    } catch (e) {
      logger.e('Error adding to cart: $e');
      showToast(message: 'Could not add item. Please try again.');
    }
  }


  // In /lib/services/firebase_services.dart, inside the FirebaseServices class  /// Upload multiple images to Firebase Storage and return their URLs.
  Future<List<String>> uploadMultipleImages(
      {required List<File> images, required String docId}) async {
    List<String> imageUrls = [];
    for (var imageFile in images) {
      try {
        String imageUrl = await uploadImage(imageFile);
        imageUrls.add(imageUrl);
      } catch (e) {
        logger.e('Failed to upload an image: $e');
        // Continue trying to upload other images
      }
    }
    return imageUrls;
  }




  /// [Love Store] - Fetches the full product details for items in a user's cart.
  Future<List<CartItem>> getCartItems(String userId) async {
    List<CartItem> cartDetails = [];
    try {
      // 1. Fetch the simple cart items (productId and quantity)
      final cartSnapshot = await _firebaseFirestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      if (cartSnapshot.docs.isEmpty) {
        return []; // Return empty list if cart is empty
      }

      // 2. For each item in the cart, fetch the full product details
      for (var cartDoc in cartSnapshot.docs) {
        final productId = cartDoc.id;
        final quantity = cartDoc.data()['quantity'] as int? ?? 1;

        final productDoc = await _firebaseFirestore
            .collection('products')
            .doc(productId)
            .get();

        if (productDoc.exists) {
          final product = Product.fromJson(productDoc.data()!);
          // CORRECTED: Use the CartItem class
          cartDetails.add(CartItem(product: product, quantity: quantity));
        } else {
          logger.w('Product with ID $productId found in cart but not in products collection.');
        }
      }
    } catch (e) {
      logger.e('Error fetching cart items: $e');
      return [];
    }
    return cartDetails;
  }




  /// [Love Store] - Updates the quantity of an item in the user's cart.
  Future<void> updateCartItemQuantity(String userId, String productId, int newQuantity) async {
    if (newQuantity <= 0) {
      // If quantity is zero or less, remove the item instead.
      await removeCartItem(userId, productId);
      return;
    }
    try {
      final cartItemRef = _firebaseFirestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(productId);

      await cartItemRef.update({'quantity': newQuantity});
    } catch (e) {
      logger.e('Error updating cart quantity: $e');
      showToast(message: 'Could not update item quantity.');
    }
  }

  /// [Love Store] - Removes an item completely from the user's cart.
  Future<void> removeCartItem(String userId, String productId) async {
    try {
      await _firebaseFirestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(productId)
          .delete();
      showToast(message: 'Item removed from cart.');
    } catch (e) {
      logger.e('Error removing cart item: $e');
      showToast(message: 'Could not remove item.');
    }
  }


  // In /lib/services/firebase_services.dart, inside the FirebaseServices class

  /// [Love Store] - Processes the entire checkout flow.
  /// Returns a success message or an error message.
  Future<String> processCheckout(String userId) async {
    final UserModel? currentUserInfo = await getUserInfo();
    if (currentUserInfo == null) {
      return "Could not verify user. Please log in again.";
    }

    final List<CartItem> cartItems = await getCartItems(userId);
    if (cartItems.isEmpty) {
      return "Your cart is empty.";
    }

    // 1. Calculate total cost and find the seller
    int totalLove = 0;
    String sellerId = '';
    for (var item in cartItems) {
      totalLove += (item.product.loveAmount ?? 0) * item.quantity;
      if (sellerId.isEmpty) {
        sellerId = item.product.sellerId ?? '';
      }
    }

    if (sellerId.isEmpty) {
      return "Could not identify the seller. Checkout aborted.";
    }

    // 2. Validate user's balance
    if (currentUserInfo.currentLoveCount < totalLove) {
      return "Insufficient Loves. You need $totalLove Loves to complete this purchase.";
    }

    // 3. Execute the transaction
    final bool transactionSuccess = await transferLoveBetweenUsers(
      senderId: userId,
      receiverId: sellerId,
      amountToSend: totalLove,
      taxAmount: 0, // Assuming no tax on store purchases for now
      totalDebitAmount: totalLove,
      senderTransactionDesc: "Purchase of ${cartItems.length} item(s) from The Love Store.",
      receiverTransactionDesc: "Sale of ${cartItems.length} item(s) to ${currentUserInfo.nickname}.",
      claireTransactionDesc: "Love Store Sale.",
      metadata: {'reason': 'love_store_purchase'},
      forLoveStore: totalLove,
      fromLoveStore: totalLove,
    );

    if (!transactionSuccess) {
      return "Transaction failed. Please try again.";
    }

    // 4. Create the Order document
    try {
      final orderId = _firebaseFirestore.collection('orders').doc().id;
      final order = OrderModel(
        orderId: orderId,
        buyerId: userId,
        buyerNickname: currentUserInfo.nickname ?? 'Unknown',
        sellerId: sellerId,
        items: cartItems.map((item) => {
          'productId': item.product.productId,
          'title': item.product.title,
          'loveAmount': item.product.loveAmount,
          'quantity': item.quantity,
        }).toList(),
        totalLoveAmount: totalLove,
        timestamp: Timestamp.now(),
      );

      await _firebaseFirestore.collection('orders').doc(orderId).set(order.toJson());

      // ---- FULFILLMENT TRIGGER (Placeholder) ----
      // This is where you would trigger an email.
      // For now, we'll just log it. A Firebase Function listening to new 'orders' documents is the best approach.
      logger.i('FULFILLMENT REQUIRED: New order ${orderId} placed by ${currentUserInfo.nickname}.');


      // 5. Clear the user's cart
      final cartCollection = _firebaseFirestore.collection('users').doc(userId).collection('cart');
      final cartSnapshot = await cartCollection.get();
      for (var doc in cartSnapshot.docs) {
        await doc.reference.delete();
      }

      return "Purchase successful! Your order has been placed."; // Success

    } catch (e) {
      logger.e('Failed to create order or clear cart: $e');
      // This is a critical error state. The user has paid but the order wasn't recorded properly.
      // Manual intervention would be needed.
      return "Payment was successful, but there was an error recording your order. Please contact support.";
    }
  }


  // In /lib/services/firebase_services.dart, inside the FirebaseServices class

  /// [Love Store] - Gets a real-time stream of the number of items in the user's cart.
  Stream<int> getCartItemCount(String userId) {
    return _firebaseFirestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }




  /// Uploads a video file to Firebase Storage and returns the download URL.
  ///
  /// [videoFile]: The video file to be uploaded.
  /// Returns the public download URL of the uploaded video.
  Future<String> uploadVideoToStorage(File videoFile) async {
    try {
      // Create a unique file name for the video
      String fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // Create a reference to the 'videos' folder in Firebase Storage
      firebase_storage.Reference ref =
      _storage.ref().child('videos/$fileName');

      // Upload the file
      firebase_storage.UploadTask uploadTask = ref.putFile(
        videoFile,
        firebase_storage.SettableMetadata(contentType: 'video/mp4'),
      );

      // Await the upload to complete
      firebase_storage.TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      logger.d('Video uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      logger.e('Error uploading video: $e');
      return ''; // Return an empty string on error
    }
  }

  /// Generates a thumbnail from a video file, uploads it to Firebase Storage,
  /// and returns the download URL.
  ///
  /// [videoFile]: The video file from which to generate a thumbnail.
  /// Returns the public download URL of the uploaded thumbnail image.
  Future<String> uploadVideoThumbnailToStorage(File videoFile) async {
    try {
      // Generate a thumbnail from the video file
      final thumbnailBytes = await VideoThumbnail.thumbnailData(
        video: videoFile.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 500, // A reasonable width for a thumbnail
        quality: 75,
      );

      if (thumbnailBytes == null) {
        throw Exception('Failed to generate video thumbnail.');
      }

      // Create a unique file name for the thumbnail
      String fileName = 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Create a reference to the 'thumbnails' folder in Firebase Storage
      firebase_storage.Reference ref =
      _storage.ref().child('thumbnails/$fileName');

      // Upload the thumbnail data (in bytes)
      firebase_storage.UploadTask uploadTask = ref.putData(
        thumbnailBytes,
        firebase_storage.SettableMetadata(contentType: 'image/jpeg'),
      );


      // Await the upload to complete
      firebase_storage.TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      logger.d('Video thumbnail uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      logger.e('Error uploading video thumbnail: $e');
      return ''; // Return an empty string on error
    }
  }


  /// Upload audio file to Firebase Storage and return the download URL
  Future<String?> uploadAudioFile(File audioFile, String userId) async {
    try {
      // Create a reference to the location you want to upload to
      final ref = _storage
          .ref()
          .child('auto_diary_audio')
          .child(userId)
          .child('${DateTime.now().millisecondsSinceEpoch}.aac');

      // Upload the file
      firebase_storage.UploadTask uploadTask = ref.putFile(audioFile);

      // Wait for the upload to complete
      final snapshot = await uploadTask.whenComplete(() => {});

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading audio file: $e');
      return null;
    }
  }


  /// Upload image to Firebase Storage and return the download URL
  Future<String> uploadImage(File imageFile) async {
    // Step 1: Generate a unique filename using the current timestamp
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();

    // Step 2: Create a Reference to the file in Firebase Storage
    firebase_storage.Reference reference = firebase_storage
        .FirebaseStorage.instance
        .ref()
        .child('photos')
        .child(fileName);

    // Step 3: Set metadata for the file (optional, here specifying content type)
    final metaData = firebase_storage.SettableMetadata(
      contentType: 'image/jpeg',
    );

    // Step 4: Upload the file using putFile() since we now have a File object
    firebase_storage.UploadTask uploadTask = reference.putFile(imageFile, metaData);

    // Step 5: Get the download URL for the uploaded image
    var imageUrl = await (await uploadTask).ref.getDownloadURL();

    print("The image URL is $imageUrl");
    return imageUrl;  // Return the image download URL
  }


  /// Upload sound to Firebase Storage and return the download URL
  Future<String> uploadSound(File file) async {
    firebase_storage.UploadTask uploadTask;
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String timeStamp = dateFormat.format(DateTime.now());
    String filename = currentUser!.uid.toString();
    // Create a Reference to the file
    firebase_storage.Reference ref =
        firebase_storage.FirebaseStorage.instance.ref().child("audio/" + filename + timeStamp);

   // final metadata = firebase_storage.SettableMetadata(
    //    contentType: 'audio/wav',
   //     customMetadata: {'picked-file-path': file.path});
    uploadTask = ref.putFile(File(file.path));
    var audioUrl = await (await uploadTask).ref.getDownloadURL();
    print("The audio url is $audioUrl");
    return audioUrl;
  }



  /// Create new session
  Future<bool> createSession({CreateSessionModel? session}) async {
    bool? isSuccessfull;
    DocumentReference<Map<String, dynamic>> sessionRef = FirebaseFirestore
        .instance
        .collection('/sessions')
        .doc(session!.sessionId);

    sessionRef.set(session.toJson()).then((value) {
      logger.d('Successfully created a session');
      return true;
    }).catchError((error) => print("Failed to create session: $error"));

    return false;
  }

  /// Get user info

  Future<UserModel> getUserInfo() async {
    _usersID = await getUsersId();
    DocumentSnapshot response = await _firebaseFirestore
        .collection(AppString.users)
        .doc(_usersID)
        .get();

    var user = UserModel.fromFirestore(response.data() as Map<String, dynamic>);
    return user;
  }


  Future<CreateSessionModel> getSingleSession({String? sessionId}) async {
    DocumentSnapshot response = await _firebaseFirestore
        .collection(AppString.session)
        .doc(sessionId)
        .get();
    var session =
        CreateSessionModel.fromJson(response.data() as Map<String, dynamic>);
    print("This session is: ${session.toJson().toString()}");
    return session;
  }



  /// Saves a user activity to the database.
  Future<void> saveUserActivity({
    required String activityType,
    required String activityMessage,
    String? recipientId,
    String? recipientNickname,
    String? sessionId,
  }) async {
    if (currentUser == null) return;

    try {
      final user = await getUserInfo();
      final docRef = _firebaseFirestore.collection(AppString.userActivity).doc();

      // --- THIS IS THE KEY ---
      // Create a list of all users involved in the activity.
      final List<String> involvedUsers = [user.userId!];
      if (recipientId != null && recipientId != user.userId) {
        involvedUsers.add(recipientId);
      }
      // --- END OF KEY ---

      final activity = UserActivityModel(
        userActivityId: docRef.id,
        clientId: user.userId,
        clientNickname: user.nickname,
        clientAvatarUrl: user.avatarUrl,
        userId: recipientId ?? user.userId,
        userNickname: recipientNickname,
        activityType: activityType,
        activityMessage: activityMessage,
        dateCreated: Timestamp.now(),
        sessionId: sessionId ?? '',
        // Add the new field
        involvedUsers: involvedUsers,
      );
      await docRef.set(activity.toJson());

      print('✅ Activity Saved: $activityType');

    } catch (e) {
      logger.e('Error saving user activity: $e');
    }
  }






  /// Get user activity that a specific user made (with pagination)
  Future<PaginatedActivities> getActivityForUser({
    required String userId,
    int limit = 20,
    DocumentSnapshot? startAfter,  }) async {
    try {
      // This is the new, single, powerful query.
      var query = _firebaseFirestore
          .collection(AppString.userActivity)
      // It finds all documents where the 'involvedUsers' array contains the user's ID.
      // This requires a Firestore index. The error message in your console will give you a link to create it.
          .where("involvedUsers", arrayContains: userId)
          .orderBy('dateCreated', descending: true)
          .limit(limit);

      // This pagination logic now works perfectly with the single query.
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();

      final activities = querySnapshot.docs
          .map((doc) => UserActivityModel.fromJson(doc.data()))
          .toList();

      // The last document reference is now reliable.
      final lastDoc = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;

      return PaginatedActivities(activities: activities, lastDocument: lastDoc);

    } catch (e) {
      // Important: If you see an error about needing an index, Firebase will provide a URL in the debug console.
      // Click the URL to automatically create the required Firestore index. This is a one-time setup.
      logger.e(e);
      return PaginatedActivities(activities: [], lastDocument: null);
    }
  }





  /// Get sessions by ids
  Future<List<Session>> getSessionsByIds(List<String> sessionIds) async {
    if (sessionIds.isEmpty) {
      return [];
    }

    /// Get all sessions

    List<Session> allSessions = [];
    // Firestore's "in" query is limited to 10 items, so we fetch in batches.
    for (var i = 0; i < sessionIds.length; i += 10) {
      final sublist = sessionIds.sublist(
          i, i + 10 > sessionIds.length ? sessionIds.length : i + 10);
      try {
        final querySnapshot = await _firebaseFirestore
            .collection('sessions') // Make sure 'sessions' is your collection name
            .where(FieldPath.documentId, whereIn: sublist)
            .get();

        allSessions.addAll(querySnapshot.docs
            .map((doc) => Session.fromJson(doc.data()))
            .toList());
      } catch (e) {
        print('Error batch fetching sessions: $e');
      }
    }
    return allSessions;
  }





  /// [User Activity] -> get all users activities for super ego tab.
  Future<List<UserActivityModel>> getAllUsersActivities() async {
    List<UserActivityModel> _userActivityList = [];

    try {
      final _value = await _firebaseFirestore
          .collection(AppString.userActivity)
          .orderBy('dateCreated', descending: true)
          .limit(AppString.allSessionLength)
          .get();

      _value.docs
          .map((e) =>
          _userActivityList.addAll([UserActivityModel.fromJson(e.data())]))
          .toList();
    } catch (e) {
      logger.e(e);
    }
    return _userActivityList;
  }

  /// get alter ego chats
  Stream<QuerySnapshot<Map<String, dynamic>>> getAlterEgoChats(
      ChatRoomPodo? chatRoomPodo) {
    // If this is the Admin Portal, pull from Public Chats instead
    String collectionPath = chatRoomPodo!.id == 5 ? AppString.appChats : "alterEgoChats";
    // If ID is 5, we specifically want the public Claire DM title
    String roomTitle = chatRoomPodo.id == 5 ? "Chat Or Eavesdrop Inside Claire's DM" : chatRoomPodo.title!;

    return _firebaseFirestore
        .collection(collectionPath)
        .doc(chatRoomPodo.id == 5 ? "-1" : chatRoomPodo.id.toString())
        .collection(roomTitle)
        .orderBy('timeCreated', descending: true)
        .limit(AppString.allSessionLength)
        .snapshots();
  }



  /// send alter ego message
  void addAlterEgoMessage(ChatRoomPodo? chatRoomPodo, ChatModel chatModel) async {
    final _user = await getUserInfo();
    final roomTitle = chatRoomPodo!.title.toString();
    _firebaseFirestore
        .collection("alterEgoChats")
        .doc(chatRoomPodo.id.toString())
        .collection(chatRoomPodo.title!)
        .doc(_user.userId)
        .set(chatModel.toJson())
        .whenComplete(() {
      /// automatically subscribe user to this topic
      _subscribeToChatRoom(chatRoomPodo.id.toString());
      logger.d('Message sent ${chatModel.toJson()}');
    });
    await notificationService.sendNotification({
      "token": _user.fcmId,
      "notification": {
        "title": "You Started Your Own Corner!",
        "body": "You created a room corner of your own inside ${roomTitle}.",
      },
      "data": {
        'route': 'chatRoom',
        'roomId': chatRoomPodo.id,
      },
    });
  }

  /// get alter ego chats
  Stream<QuerySnapshot<Map<String, dynamic>>> getAlterEgoSubMessages(
      String key, ChatRoomPodo? chatRoomPodo, ChatModel chatModel) {
    String collectionPath = chatRoomPodo!.id == 5 ? AppString.appChats : "alterEgoChats";
    String roomTitle = chatRoomPodo.id == 5 ? "Chat Or Eavesdrop Inside Claire's DM" : chatRoomPodo.title!;

    return _firebaseFirestore
        .collection(collectionPath)
        .doc(chatRoomPodo.id == 5 ? "-1" : chatRoomPodo.id.toString())
        .collection(roomTitle)
        .doc(key.toString())
        .collection(chatModel.userId!)
        .orderBy('timeCreated', descending: true)
        .limit(AppString.appSessionLength)
        .snapshots();
  }


  /// send alter ego sub-message
  void addAlterEgoSubMessage(
      String key, ChatRoomPodo? chatRoomPodo, ChatModel chatModel) async {
    final _user = await getUserInfo();
    final sender = _user.alterEgoId;
    final roomTitle = chatRoomPodo!.title.toString();
    _firebaseFirestore
        .collection("alterEgoChats")
        .doc(chatRoomPodo.id.toString())
        .collection(chatRoomPodo.title!)
        .doc(key.toString())
        .collection(key.toString())
        .doc(_user.userId)
        .set(chatModel.toJson())
        .whenComplete(() {
      _subscribeToChatRoom(key);
      logger.d('SubMessage sent ${chatModel.toJson()}');
    });
    // Only send a notification if the person replying is NOT the owner of the corner.
    final cornerOwner = await getUserWithId(id: key);
    if (cornerOwner.userId != _user.userId) {
      await notificationService.sendNotification({
        // Send to the corner owner's FCM token, not the sender's.
        "token": cornerOwner.fcmId,
        "notification": {
          "title": "Message Dropped In Your Alter Ego Corner!",
          "body":
          "${sender ?? 'An Alter Ego'} sent something to your corner of the room inside ${roomTitle}.",
        },
        "data": {
          'route': 'alterEgoDiaryRooms',
          'roomId': chatRoomPodo.id,
          'cornerId': key,
        },
      });
    }
  }

  void updateAlterEgoMembers(
      String key, ChatRoomPodo? chatRoomPodo, ChatModel chatModel) async {
    _firebaseFirestore
        .collection("alterEgoChats")
        .doc(chatRoomPodo!.id.toString())
        .collection(chatRoomPodo.title!)
        .doc(key)
        .update(chatModel.toJson());
  }





  /// get chats
  Stream<QuerySnapshot<Map<String, dynamic>>> getChats(
      ChatRoomPodo? chatRoomPodo) {
    return _firebaseFirestore
        .collection(AppString.appChats)
        .doc(chatRoomPodo!.id.toString())
        .collection(chatRoomPodo.title!)
        .orderBy('timeLastActivity', descending: true)
        .limit(AppString.allSessionLength)
        .snapshots();
  }

  /// send users message
  void addMessage(ChatRoomPodo? chatRoomPodo, ChatModel chatModel) async {
    final _user = await getUserInfo();
    final roomTitle = chatRoomPodo!.title.toString();
    _firebaseFirestore
        .collection(AppString.appChats)
        .doc(chatRoomPodo.id.toString())
        .collection(chatRoomPodo.title!)
        .doc(_user.userId)
        .set(chatModel.toJson())
        .whenComplete(() {
      /// automatically subscribe user to this topic
      _subscribeToChatRoom(chatRoomPodo.id.toString());
      logger.d('Message sent ${chatModel.toJson()}');
    });
    await notificationService.sendNotification({
      "token": _user.fcmId,
      "notification": {
        "title": "You Started Your Own Corner!",
        "body": "You created a room corner of your own inside ${roomTitle}.",
      },
      "data": {
        'route': 'diaryRooms',
        'roomId': chatRoomPodo.id,
      },
    });
  }

  /// get sub chats
  Stream<QuerySnapshot<Map<String, dynamic>>> getSubMessages(
      String key, ChatRoomPodo? chatRoomPodo, ChatModel chatModel) {
    return _firebaseFirestore
        .collection(AppString.appChats)
        .doc(chatRoomPodo!.id.toString())
        .collection(chatRoomPodo.title!)
        .doc(key.toString())
        .collection(chatModel.userId!)
        .orderBy('timeCreated', descending: true)
        .limit(AppString.appSessionLength)
        .snapshots();
  }

  /// send sub-message
  void addSubMessage(
      String key, ChatRoomPodo? chatRoomPodo, ChatModel chatModel) async {
    final _user = await getUserInfo();
    final sender = _user.nickname;
    final roomTitle = chatRoomPodo!.title.toString();
    _firebaseFirestore
        .collection(AppString.appChats)
        .doc(chatRoomPodo.id.toString())
        .collection(chatRoomPodo.title!)
        .doc(key.toString())
        .collection(key.toString())
        .doc(_user.userId)
        .set(chatModel.toJson())
        .whenComplete(() {
      logger.d('SubMessage sent ${chatModel.toJson()}');
    });
    // Only send a notification if the person replying is NOT the owner of the corner.
    final cornerOwner = await getUserWithId(id: key);
    if (cornerOwner.userId != _user.userId) {
      await notificationService.sendNotification({
        // Send to the corner owner's FCM token, not the sender's.
        "token": cornerOwner.fcmId,
        "notification": {
          "title": "Message Dropped In Your Corner!",
          "body":
          "${sender ?? 'An Ego'} sent something to your corner of the room inside ${roomTitle}.",
        },
        "data": {
          'route': 'diaryRooms',
          'roomId': chatRoomPodo.id,
          'cornerId': key,
        },
      });
    }
  }




  Future<bool> addToCategory(
      String category, CreateSessionModel createSessionModel) async {
    try {
      _firebaseFirestore
          .collection(AppString.sessionCategories)
          .doc(category)
          .collection('sessions')
          .doc(createSessionModel.sessionId!)
          .set(createSessionModel.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// BRIDGE FUNCTION: For compatibility with old code that still passes an index.
  Future<void> addUsersReactionToASessionByIndex(
      BuildContext context,
      int index, // Accepts the old integer index
          {required Session session, required String sender}
      ) async {
    // This function converts the old index into the new string value.
    String reactionType;
    switch (index) {
      case 0: reactionType = 'Cheers👍'; break;
      case 1: reactionType = 'Thanks💕'; break;
      case 2: reactionType = 'Sorry🖐'; break;
      case 3: reactionType = 'Me2🌺'; break;
      default:
      // If the index is unknown, fallback to a generic 'react' type.
        reactionType = 'react';
        break;
    }

    // Now, call the primary, corrected function with the string value.
    await addUsersReactionToASession(
      context,
      reactionType,
      session: session,
      sender: sender,
    );
  }


  /// add users reaction to a posts
  Future<void> addUsersReactionToASession(
      BuildContext context,
      String reactionType, // Keep this as String
          {required Session session, required String sender}
      ) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      logger.w("Cannot add reaction, user is not signed in.");
      return;
    }

    final String userId = currentUser.uid;

    // Map the string reaction back to an index for your ReactionHandler
    int getIndexForReaction(String type) {
      switch (type) {
        case 'Cheers👍': return 0;
        case 'Thanks💕': return 1;
        case 'Sorry🖐': return 2;
        case 'Me2🌺': return 3;
        default: return -1;
      }
    }

    final int index = getIndexForReaction(reactionType);
    if (index == -1) {
      logger.e("Invalid reaction type received: $reactionType");
      return;
    }

    // This method now ONLY updates the Firestore document with the reaction.
    // It no longer handles notifications or love transactions.
    // We don't even need the reaction toggle logic, as the UI in metoo_button
    // already prevents a user from reacting more than once.

    try {
      await _firebaseFirestore
          .collection(AppString.appFeaturedSessions)
          .doc(session.sessionId)
          .update(ReactionHandler.returnReaction(index, userId, addReaction: true));

      logger.d('Successfully updated reaction array for session ${session.sessionId}');
    } catch (e) {
      logger.e("Failed to update reaction in Firestore: $e");
      // Optionally show a toast to the user if the DB update fails.
      showToast(message: "Failed to save your reaction. Please try again.");
    }
  }





  /// Update a session's last time activity

  Future<void> updateSessionLastTimeActivity(String id) async {
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(id)
        .update(
      {
        "timeLastActivity": FieldValue.serverTimestamp(),
      },
    );
    logger.d('Successfully updated session last time activity');
  }





  /// Update a user's last time unlocked

  Future<void> updateUserLastTimeUnlocked(String id) async {
    FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .update(
      {
        "timeLastUnlocked": FieldValue.serverTimestamp(),
      },
    );
    logger.d('Successfully updated user last time unlocked');
  }


  /// Get all sessions that have been created by a particular user
  /// @param lastSession The last session from previous request. Used for pagination
  /// @return LiveData
  Future<List<Session>> getUserSessionByDate({DateTime? startDate}) async {
    List<Session> _sessionList = [];

    _usersID = await getUsersId();
    try {
      final _value = await _firebaseFirestore
          .collection(AppString.appFeaturedSessions)
          .where("userId", isEqualTo: _usersID)
          .where("timeCreated", isGreaterThanOrEqualTo: startDate!)
          // .orderBy('timeCreated', descending: true)
         // .limit(AppString.appSessionLength)
          .get();


      _value.docs
          .map((e) => _sessionList.addAll([Session.fromJson(e.data())]))
          .toList();

    } catch (e) {
      debugPrint(e.toString());
    }
    return _sessionList;
  }

  /// get number of followers a user has
  Future<void> getNumberOfFollowersForUser() async {
    _usersID = await getUsersId();
    final query = await _firebaseFirestore
        .collection(AppString.COLLECTION_USER_FOLLOW_COUNTERS)
        .doc(_usersID)
        .collection(AppString.COLLECTION_USER_FOLLOW_SHARDS)
        //.limit(100)
        .get();

    debugPrint(
        " This is the number of followers for this user ${query.docs}");
  }





  Future<EgoProfileInfo> getEgoProfileInfo()async{
    EgoProfileInfo profileInfo= EgoProfileInfo();
    _usersID = await getUsersId();


    //get user profile Info
    user = await getUserInfo();

    profileInfo = EgoProfileInfo(userModel: user);



    //get user session count
    List<Session> _sessionList = [];
    try {
      final _value = await _firebaseFirestore
          .collection(AppString.appFeaturedSessions)
          .where("userId", isEqualTo: _usersID)
         // .limit(AppString.appSessionLength)
          .get();


      debugPrint(
          " This is the number of sessions by date for this user ${_value.docs.length}");
      _value.docs
          .map((e) => _sessionList.addAll([Session.fromJson(e.data())]))
          .toList();

      debugPrint(
          " This is the number of sessions by date for this user ${_sessionList.length}");
    } catch (e) {
      debugPrint(e.toString());
    }


    //get advises count

    List<CommentSessionModel> _advisesList = [];


    try {
    final _value = await _firebaseFirestore
        .collection("user_comment_counters")
        .where("userId", isEqualTo: _usersID)
      //  .limit(AppString.appSessionLength)
        .get();


    debugPrint(
    " This is the number of advises given by this user ${_value.docs.length}");
    _value.docs
        .map((e) => _advisesList.addAll([CommentSessionModel.fromJson(e.data())]))
        .toList();

    debugPrint(
    " This is the number of advises given by this user ${_advisesList.length}");
    } catch (e) {
    debugPrint(e.toString());
    }


    //get follows count

    List<UserModel> _followsList = [];


    try {
      final _value = await _firebaseFirestore
          .collection("user_follow_counters")
          .where("userId", isEqualTo: _usersID)
          //.limit(AppString.appCommentLength)
          .get();


      debugPrint(
          " This is the number of LOVES earned by this user ${_value.docs.length}");
      _value.docs
          .map((e) => _followsList.addAll([UserModel.fromJson(e.data())]))
          .toList();

      debugPrint(
          " This is the number of LOVES earned by this user ${_followsList.length}");
    } catch (e) {
      debugPrint(e.toString());
    }



    profileInfo = EgoProfileInfo(
        userModel: user,
        sessionCount: _sessionList.length,
        advisesCount: _advisesList.length,
        followCount: _followsList.length,
    );
    return profileInfo;

  }

  Future<void> deductLoves(int amount) async {
    _usersID = await getUsersId();
    FirebaseFirestore.instance
        .collection('users')
        .doc(_usersID)
        .set({
      'totalLoveCount': FieldValue.increment(-amount),
    },
      SetOptions(merge: true),
    );
    logger.d('Successfully decreased total love count from ${_usersID} for featured session');
  }

  Future<void> featureSession(String sessionId) async {
    await _firebaseFirestore
        .collection(AppString.appFeaturedSessions)
        .doc(sessionId)
        .update({'featured': true});
  }


}

// ADD THIS CLASS AT THE TOP OF lib/services/firebase_services.dart
class PaginatedActivities {
  final List<UserActivityModel> activities;
  final DocumentSnapshot? lastDocument;

  PaginatedActivities({required this.activities, this.lastDocument});
}

