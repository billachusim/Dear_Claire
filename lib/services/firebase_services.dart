import 'dart:io';
import 'package:clairediary/services/transaction_service.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:get/get_navigation/src/root/parse_route.dart';
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
  ///
  /// [userId]: The ID of the user performing the action.
  /// [amount]: The number of loves to be transacted.
  /// [type]: 'credit' if the user is receiving loves, 'debit' if they are spending.
  /// [userTransactionDescription]: The description for the user's transaction list.
  /// [metadata]: Optional data for the transaction record.
  /// [fromGameWins]: Optional amount to increment for game wins.
  /// [forGameLoses]: Optional amount to increment for game losses.
  ///
  /// Returns `true` if the transaction was processed, `false` if it was set to pending.
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
  }) async {
    const String claireId = "PbRuh3FmtESK57j3PM1Tc9RvPKh2";
    const int treasuryMinBalance = 4000000;
    final DocumentReference claireDoc = _firebaseFirestore
        .collection('users')
        .doc(claireId);
    final DocumentReference userDoc = _firebaseFirestore.collection('users').doc(
        userId);
    final TransactionService transactionService = TransactionService();

    if (type == t_model.TransactionType.credit) {
      // USER is RECEIVING loves (deduct from Claire)
      try {
        final claireSnapshot = await claireDoc.get();
        final claireLoves = (claireSnapshot.data() as Map<String,
            dynamic>?)?['totalLoveCount'] ?? 0;

        if (claireLoves < treasuryMinBalance) {
          // Treasury is too low, mark as pending and DO NOT process.
          await transactionService.recordTransaction(
            userId: userId,
            amount: amount,
            type: type,
            description: userTransactionDescription,
            status: t_model.TransactionStatus.pending,
            // Mark as pending
            metadata: {
              ...metadata ?? {},
              'treasury_status': 'pending_low_balance'
            },
          );
          return false; // Indicate that the transaction is pending
        }

        // Treasury has enough, process the transaction for both.
        await userDoc.update({
          'currentLoveCount': FieldValue.increment(amount),
          'totalLoveCount': FieldValue.increment(-amount),
          'fromGameWins': FieldValue.increment(fromGameWins),
          'fromRoomVisits': FieldValue.increment(fromRoomVisits),
        });
        await claireDoc.update({'totalLoveCount': FieldValue.increment(-amount)});

        await transactionService.recordTransaction(
          userId: userId,
          amount: amount,
          type: type,
          description: userTransactionDescription,
          status: t_model.TransactionStatus.approved,
          metadata: metadata,
        );
        return true; // Transaction approved
      } catch (e) {
        print("Error in treasury credit transaction: $e");
        return false;
      }
    } else {
      // USER is SPENDING loves (add to Claire)
      try {
        // No need to check Claire's balance when user is paying.
        await userDoc.update({
          'currentLoveCount': FieldValue.increment(-amount),
          'forGameLoses': FieldValue.increment(forGameLoses),
          'forRoomVisits': FieldValue.increment(forRoomVisits),
        });
        await claireDoc.update({'totalLoveCount': FieldValue.increment(amount)});

        await transactionService.recordTransaction(
          userId: userId,
          amount: amount,
          type: type,
          description: userTransactionDescription,
          status: t_model.TransactionStatus.approved,
          metadata: metadata,
        );
        return true; // Transaction approved
      } catch (e) {
        print("Error in treasury debit transaction: $e");
        return false;
      }
    }
  }




  /// Handles a direct user-to-user love transfer with a 10% tax for Claire.
  ///
  /// This is a three-way transaction:
  /// 1. Debits the sender for the amount + tax.
  /// 2. Credits the receiver for the amount.
  /// 3. Credits Claire's treasury for the tax.
  ///
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
  }) async {
    const String claireId = "PbRuh3FmtESK57j3PM1Tc9RvPKh2";
    final DocumentReference senderDoc = _firebaseFirestore.collection('users').doc(senderId);
    final DocumentReference receiverDoc = _firebaseFirestore.collection('users').doc(receiverId);
    final DocumentReference claireDoc = _firebaseFirestore.collection('users').doc(claireId);
    final TransactionService transactionService = TransactionService();

    try {
      await _firebaseFirestore.runTransaction((transaction) async {
        // Get sender's data to ensure they have enough loves
        final senderSnapshot = await transaction.get(senderDoc);
        final senderLoves = (senderSnapshot.data() as Map<String,
            dynamic>?)?['currentLoveCount'] ?? 0;
        if (senderLoves < totalDebitAmount) {
          throw Exception('Insufficient funds');
        }

        // 1. Debit the sender and update their stats
        transaction.update(senderDoc, {
          'currentLoveCount': FieldValue.increment(-totalDebitAmount),
          'totalLoveCount': FieldValue.increment(-totalDebitAmount),
          'forRoomVisits': FieldValue.increment(forRoomVisits),
          'loveSentForThanks': FieldValue.increment(forThanks),
          'loveSentForReactions': FieldValue.increment(forReactions),
        });

        // 2. Credit the receiver and update their stats
        transaction.update(receiverDoc, {
          'currentLoveCount': FieldValue.increment(amountToSend),
          'totalLoveCount': FieldValue.increment(amountToSend),
          'fromRoomVisits': FieldValue.increment(fromRoomVisits),
          'loveFromThanks': FieldValue.increment(fromThanks),
          'loveFromReactions': FieldValue.increment(fromReactions),
        });

        // 3. Credit Claire's treasury with the tax
        transaction.update(
            claireDoc, {'totalLoveCount': FieldValue.increment(taxAmount)});
      });

      // If the transaction is successful, record the individual transaction logs.
      // Sender's Debit Record
      await transactionService.recordTransaction(
        userId: senderId,
        amount: totalDebitAmount,
        type: t_model.TransactionType.debit,
        description: senderTransactionDesc,
        metadata: metadata,
      );

      // Receiver's Credit Record
      await transactionService.recordTransaction(
        userId: receiverId,
        amount: amountToSend,
        type: t_model.TransactionType.credit,
        description: receiverTransactionDesc,
        metadata: metadata,
      );

      // Claire's Tax Credit Record (Optional but good for auditing)
      await transactionService.recordTransaction(
        userId: claireId,
        amount: taxAmount,
        type: t_model.TransactionType.credit,
        description: claireTransactionDesc,
        metadata: metadata,
      );

      return true; // Success
    } catch (e) {
      print("Error during user-to-user love transfer: $e");
      return false; // Failure
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



  /// Notify Claire for every session
  Future<void> notifyClaireForSession(String sender, CreateSessionModel session) async {
    _usersID = "PbRuh3FmtESK57j3PM1Tc9RvPKh2";

    await _firebaseMessaging.subscribeToTopic(session.sessionId!);
    final pushNotification.NotificationModel _notificationModel =
    pushNotification.NotificationModel(
      topic: session.sessionId!,
      data: pushNotification.Data(id: _usersID, route: session.sessionId.toString()),
      notification: pushNotification.Notification(
          title: session.title ?? '', body: '$sender started a new session'),
    );
    notificationService.sendNotification(_notificationModel.toJson());
    logger.d('Notified for this session: ${session.title!}');
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
    return prefs!.getString(Constant.PREF_KEY_ALTER_EGO_ACCESS_CODE) ?? '';
  }

  /// get AlterEgoAccessCode
  Future<String> getAlterEgoUserId() async {
    prefs = await SharedPreferences.getInstance();
    return prefs!.getString(Constant.PREF_KEY_ALTER_EGO_ID) ?? '';
  }

  /// cache user
  void setUser(UserModel userModel) async {
    final _user = FirebaseAuth.instance;
    prefs = await SharedPreferences.getInstance();
    prefs!.setString(Constant.PREF_KEY_USER_AVATAR_URL, userModel.avatarUrl!);
    prefs!.setString(Constant.PREF_KEY_USER_NICKNAME, userModel.nickname!);
    prefs!.setString(Constant.PREF_KEY_USER_SECRET_CODE, userModel.secretCode!);
    prefs!.setString(Constant.PREF_KEY_USER_EMAIL, userModel.email!);
    prefs!.setString(Constant.PREF_KEY_USER_FCM_ID, _user.currentUser!.uid);
    prefs!.setString(Constant.PREF_KEY_USER_GENDER, userModel.gender!);
    prefs!.setString(Constant.PREF_KEY_USER_ID, userModel.userId!);
    prefs!.setString(Constant.PREF_KEY_USER_USER_TYPE, userModel.userType!);
    prefs!.setString(Constant.PREF_KEY_ALTER_EGO_ID, userModel.alterEgoId!);
    prefs!.setString(
        Constant.PREF_KEY_ALTER_EGO_ACCESS_CODE, userModel.alterEgoAccessCode!);
    prefs!.setString(Constant.PREF_KEY_USER_TIME_REGISTERED,
        userModel.timeRegistered!.toDate().toString());
    prefs!.setString(Constant.PREF_KEY_USER_LAST_UNLOCKED,
        userModel.timeLastUnlocked!.toDate().toString());
    //prefs!.setString(usersModelKey, id);
    notifyListeners();
  }

  /// get user
  Future<UserModel> getUser() async {
    prefs = await SharedPreferences.getInstance();
    var avatar = prefs!.getString(Constant.PREF_KEY_USER_AVATAR_URL) ?? '';
    var nickname = prefs!.getString(Constant.PREF_KEY_USER_NICKNAME) ?? '';
    var secretCode = prefs!.getString(Constant.PREF_KEY_USER_SECRET_CODE) ?? '';
    var email = prefs!.getString(Constant.PREF_KEY_USER_EMAIL) ?? '';
    var uid = prefs!.getString(Constant.PREF_KEY_USER_FCM_ID) ?? '';
    var gender = prefs!.getString(Constant.PREF_KEY_USER_GENDER) ?? '';
    var userId = prefs!.getString(Constant.PREF_KEY_USER_ID) ?? '';
    var userType = prefs!.getString(Constant.PREF_KEY_USER_USER_TYPE) ?? '';
    var alterEgoId = prefs!.getString(Constant.PREF_KEY_ALTER_EGO_ID) ?? '';
    var alterEgoAccessCode =
        prefs!.getString(Constant.PREF_KEY_ALTER_EGO_ACCESS_CODE) ?? '';
    //var timeRegistered = prefs!.getString(Constant.PREF_KEY_USER_TIME_REGISTERED) ?? '';
    //var timeLastUnlocked = prefs!.getString(Constant.PREF_KEY_USER_LAST_UNLOCKED) ?? '';
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
    return _firebaseFirestore
        .collection(AppString.appFeaturedSessions)
        .where("repliesEnabled", isEqualTo: true)
        .where("archived", isEqualTo: false)
        .where('followers', arrayContains: _usersID)
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

  /// Get the user sessions that haven't been flagged and archived
  /// @param lastSession The last session from previous request. Used for pagination
  /// @param userId The id of the user to get diary sessions for
  /// @return LiveData
  Future<List<Session>> getDiarySessions() async {
    List<Session> _sessionList = [];
    try {
      final _value = await _firebaseFirestore
          .collection(AppString.appFeaturedSessions)
          .where("userId", isEqualTo: _usersID)
          //.where("flagged", isEqualTo: false)
          .where("archived", isEqualTo: false)
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
          Navigator.of(context)
              .pushReplacementNamed(AppRoutes.alterEgoHomepage);
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





  Future<UserModel> getUserWithId({String? id}) async {
    final _info =
        await _firebaseFirestore.collection(AppString.users).doc(id).get();
    final _data = UserModel.fromFirestore(_info.data()!);
    return _data;
  }

  /// SignUp user
  Future<bool> register(
      BuildContext context, String email, String secretCode, String nickname) async {
    final _user = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: secretCode);
    setUsersId(_user.user!.uid);
    final _email = email;
    final _secretCode = secretCode;
    final _nickname = nickname;
    try {
      final alterEgoAccessCode = "";
      final alterEgoId = "";
      final email = _email;
      final fcmId = "";
      final secretCode = _secretCode;
      final timeLastUnlocked = FieldValue.serverTimestamp();
      final timeRegistered = FieldValue.serverTimestamp();
      final userType = "REGULAR";
      final nickname = _nickname;
      final avatarUrl = "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2FSpeak_No_Evil_Monkey_Emoji.png?alt=media&token=88242e3b-ee93-4b76-9d91-a24c112ef4f2";
      final userId = _user.user?.uid;
      final sessionCount = 0;
      final adviseCount = 0;
      final totalLoveCount = 0;
      final currentLoveCount = 0;
      final withdrawnLoveCount = 0;
      FirebaseFirestore.instance
          .collection("users")
          .doc(_user.user!.uid)
          .set({
        "nickname": nickname,
        "avatarUrl": avatarUrl,
        "userId": userId,
        "alterEgoAccessCode": alterEgoAccessCode,
        "alterEgoId": alterEgoId,
        "email": email,
        "fcmId": fcmId,
        "secretCode": secretCode,
        "timeLastUnlocked": timeLastUnlocked,
        "timeRegistered": timeRegistered,
        "userType": userType,
        "sessionCount": sessionCount,
        "adviseCount": adviseCount,
        "totalLoveCount": totalLoveCount,
        "currentLoveCount": currentLoveCount,
        "withdrawnLoveCount": withdrawnLoveCount,
      },
      );
      logger.d('Completely created new ego');
      print('Email: $email');
      print('User Id: $userId');
      print('Secret Code: $secretCode');

      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: secretCode)
          .then((value) => {
        setUsersId(value.user!.uid),
      });

      showToast(message: AppString.create_ego_complete_toast);
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        showToast(message: 'The password provided is too weak.');
      } else if (e.code.length < 4) {
        showToast(message: 'secret code should be up to 4 digits');
      } else if (e.code == 'email-already-in-use') {
        showToast(message: 'The account already exists for that email.');
      } else if (!isValidEmail(email)) {
        showToast(message: 'email is not invalid');
      }
      logger.e(e);
      showToast(message: AppString.open_up_error);
      return false;
    } catch (e) {
      logger.e(e);
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
  void followThisSession(BuildContext context, {Session? session}) {
    showCustomDialog(context,
        message: session!.followers!.contains(_usersID)
            ? AppString.unFollowDiarySessions
            : AppString.followDiarySessions, onPressed: () {
      PageRouter.goBack(context);
      _followASession(context, session: session);
    });
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
            .map((doc) => Session.fromJson(doc.data() as Map<String, dynamic>))
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
    return _firebaseFirestore
        .collection("alterEgoChats")
        .doc(chatRoomPodo!.id.toString())
        .collection(chatRoomPodo.title!)
        .orderBy('timeCreated', descending: true)
        .limit(AppString.allSessionLength)
        .snapshots();
  }


  /// send alter ego message
  void addAlterEgoMessage(ChatRoomPodo? chatRoomPodo, ChatModel chatModel) async {
    final _user = await getUserInfo();
    final sender = _user.alterEgoId;
    final roomTitle = chatRoomPodo!.title.toString();
    final pushNotification.NotificationModel _notificationModel =
    pushNotification.NotificationModel(
        topic: chatRoomPodo.id.toString(),
        data: pushNotification.Data(id: chatModel.userNickname, route: 'room'),
        notification: pushNotification.Notification(
            title: chatRoomPodo.title!,
            body: '$sender started a new corner inside $roomTitle.'));

    _firebaseFirestore
        .collection("alterEgoChats")
        .doc(chatRoomPodo.id.toString())
        .collection(chatRoomPodo.title!)
        .doc(_user.userId)
        .set(chatModel.toJson())
        .whenComplete(() {
      /// automatically subscribe user to this topic
      _subscribeToChatRoom(chatRoomPodo.id.toString());
      notificationService.sendNotification(_notificationModel.toJson());
      logger.d('Message sent ${chatModel.toJson()}');
    });
  }

  /// get alter ego chats
  Stream<QuerySnapshot<Map<String, dynamic>>> getAlterEgoSubMessages(
      String key, ChatRoomPodo? chatRoomPodo, ChatModel chatModel) {
    return _firebaseFirestore
        .collection("alterEgoChats")
        .doc(chatRoomPodo!.id.toString())
        .collection(chatRoomPodo.title!)
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
    final pushNotification.NotificationModel _notificationModel =
    pushNotification.NotificationModel(
        topic: chatModel.userId!,
        data: pushNotification.Data(id: chatModel.userNickname, route: 'room'),
        notification: pushNotification.Notification(
          title: chatRoomPodo!.title!,
          body: '$sender sent something to your corner of the room',
        ));
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
      notificationService.sendNotification(_notificationModel.toJson());
      logger.d('SubMessage sent ${chatModel.toJson()}');
    });
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
        .orderBy('timeCreated', descending: true)
        .limit(AppString.allSessionLength)
        .snapshots();
  }

  /// send users message
  void addMessage(ChatRoomPodo? chatRoomPodo, ChatModel chatModel) async {
    final _user = await getUserInfo();
    final sender = _user.nickname;
    final roomTitle = chatRoomPodo!.title.toString();
    final pushNotification.NotificationModel _notificationModel =
        pushNotification.NotificationModel(
            topic: chatRoomPodo.id.toString(),
            data: pushNotification.Data(id: chatModel.userNickname, route: 'room'),
            notification: pushNotification.Notification(
                title: chatRoomPodo.title!,
                body: '$sender started a new corner inside $roomTitle.'));

    _firebaseFirestore
        .collection(AppString.appChats)
        .doc(chatRoomPodo.id.toString())
        .collection(chatRoomPodo.title!)
        .doc(_user.userId)
        .set(chatModel.toJson())
        .whenComplete(() {
      /// automatically subscribe user to this topic
      _subscribeToChatRoom(chatRoomPodo.id.toString());
      notificationService.sendNotification(_notificationModel.toJson());
      logger.d('Message sent ${chatModel.toJson()}');
    });
  }

  /// get chats
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
    final pushNotification.NotificationModel _notificationModel =
        pushNotification.NotificationModel(
            topic: chatModel.userId!,
            data: pushNotification.Data(id: chatModel.userNickname, route: 'room'),
            notification: pushNotification.Notification(
              title: chatRoomPodo!.title!,
              body: '$sender sent something to your corner of the room',
            ));
    _firebaseFirestore
        .collection(AppString.appChats)
        .doc(chatRoomPodo.id.toString())
        .collection(chatRoomPodo.title!)
        .doc(key.toString())
        .collection(key.toString())
        .doc(_user.userId)
        .set(chatModel.toJson())
        .whenComplete(() {
      _subscribeToChatRoom(key);
      notificationService.sendNotification(_notificationModel.toJson());
      logger.d('SubMessage sent ${chatModel.toJson()}');
    });
  }

  void updateMembers(
      String key, ChatRoomPodo? chatRoomPodo, ChatModel chatModel) async {
    _firebaseFirestore
        .collection(AppString.appChats)
        .doc(chatRoomPodo!.id.toString())
        .collection(chatRoomPodo.title!)
        .doc(key)
        .update(chatModel.toJson());
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

  /// add users reaction to a posts
  Future<void>? addUsersReactionToASession(BuildContext context, int index,
      {required Session session, required String sender}) async {
    _usersID = await getUsersId();
    final pushNotification.NotificationModel _notificationModel =
        pushNotification.NotificationModel(
      topic: session.sessionId!,
      data: pushNotification.Data(id: _usersID, route: session.sessionId.toString()),
      notification: pushNotification.Notification(
          title: session.title ?? '', body: '$sender reacted to the session.'),
    );

    ReactionHandler.reactionType(session, index).contains(_usersID)
        ? _firebaseFirestore
            .collection(AppString.appFeaturedSessions)
            .doc(session.sessionId)
            .update(ReactionHandler.returnReaction(index, _usersID!,
                addReaction: false))
            .then((value) => logger.d('Successfully remove reaction'))
        : _firebaseFirestore
            .collection(AppString.appFeaturedSessions)
            .doc(session.sessionId)
            .update(ReactionHandler.returnReaction(index, _usersID!,
                addReaction: true))
            .then((value) => notificationService
                .sendNotification(_notificationModel.toJson()));
  }

  /// adds reaction to users comment
  void addThanksReaction(
      {required String commentID,
      required String docId,
      required Session session,
      required String sender,
      required Map<String, dynamic> map}) {
    final pushNotification.NotificationModel _notificationModel =
    pushNotification.NotificationModel(
      topic: docId,
      data: pushNotification.Data(id: sender, route: docId.toString()),
      notification: pushNotification.Notification(
          title: session.title, body: '$sender thanked a response on the session.'),
    );
    notificationService.sendNotification(_notificationModel.toJson());

    _firebaseFirestore
        .collection(AppString.appFeaturedSessions)
        .doc(docId.toString())
        .collection(AppString.appFeaturedSessionsComments)
        .doc(commentID.toString())
        .update(map);
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


  // ADD THIS NEW METHOD inside your FirebaseServices class.

  /// ONE-TIME MIGRATION SCRIPT.
  /// This method will update old activity documents to include the new 'involvedUsers' field.
  Future<void> backfillInvolvedUsersField() async {
    print("MIGRATION STARTED: Backfilling 'involvedUsers' field...");
    try {
      final activityCollection = _firebaseFirestore.collection(AppString.userActivity);
      final snapshot = await activityCollection.get(); // Get all documents

      final WriteBatch batch = _firebaseFirestore.batch();
      int updatedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Check if 'involvedUsers' field is missing or null
        if (data['involvedUsers'] == null) {
          final clientId = data['clientId'] as String?;
          final userId = data['userId'] as String?;

          if (clientId != null && userId != null) {
            // Create the new array
            final List<String> involvedUsers = [clientId];
            if (clientId != userId) {
              involvedUsers.add(userId);
            }
            // Add the update operation to the batch
            batch.update(doc.reference, {'involvedUsers': involvedUsers});
            updatedCount++;
          }
        }
      }

      // If there are documents to update, commit the batch
      if (updatedCount > 0) {
        await batch.commit();
        print("✅ MIGRATION COMPLETE: Successfully updated $updatedCount documents.");
      } else {
        print("MIGRATION INFO: No documents needed to be updated.");
      }

    } catch (e) {
      print("❌ MIGRATION FAILED: $e");
    }
  }


}

// ADD THIS CLASS AT THE TOP OF lib/services/firebase_services.dart
class PaginatedActivities {
  final List<UserActivityModel> activities;
  final DocumentSnapshot? lastDocument;

  PaginatedActivities({required this.activities, this.lastDocument});
}

