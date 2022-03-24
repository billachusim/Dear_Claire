
abstract class UserRepository {
  Future<void> registerUser(
      String email, String secretCode);
}