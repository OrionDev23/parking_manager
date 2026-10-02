import '../entities/user_profile.dart';

abstract class UserProfileRepository {
  Future<UserProfile?> getCurrent();
  Future<UserProfile?> getById(String id);
  Future<UserProfile> update(UserProfile profile);
}
