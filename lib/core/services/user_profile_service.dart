import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';

class UserProfileService {
  final UserProfileRepository repository;

  const UserProfileService({required this.repository});

  Future<UserProfile?> getCurrent() => repository.getCurrent();

  Future<UserProfile?> getById(String id) => repository.getById(id);

  Future<UserProfile> update(UserProfile profile) => repository.update(profile);
}
