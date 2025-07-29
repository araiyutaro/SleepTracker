import '../entities/user_profile.dart';

abstract class UserRepository {
  Future<UserProfile?> getUserProfile();
  Future<void> saveUserProfile(UserProfile profile);
}