

import 'package:dear_claire/data/cache/user_cache.dart';
import 'package:dear_claire/data/remote/user_remote/user_remote.dart';
import 'package:dear_claire/data/repository/user_repository.dart';

class UserRepositoryImpl extends UserRepository {
  final UserRemote userRemote;
  final UserCache userCache;

  UserRepositoryImpl(this.userRemote, this.userCache);

  @override
  Future<void> registerUser(String email, String secretCode) {
    // TODO: implement registerUser
    throw UnimplementedError();
  }

}