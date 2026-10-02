import 'package:appwrite/appwrite.dart';

import '../../../domain/entities/user_profile.dart';
import '../../../domain/repositories/user_profile_repository.dart';
import '../../../providers/client_database.dart';
import '../../../serializables/parc_user.dart';

class LegacyAppwriteUserProfileRepository implements UserProfileRepository {
  const LegacyAppwriteUserProfileRepository();

  @override
  Future<UserProfile?> getCurrent() async {
    final user = DatabaseGetter.user;
    if (user == null) return null;
    return getById(user.$id);
  }

  @override
  Future<UserProfile?> getById(String id) async {
    final database = DatabaseGetter.database;
    if (database == null) {
      throw StateError('Appwrite database is not initialized.');
    }

    try {
      final row = await database.getRow(
        databaseId: databaseId,
        tableId: userid,
        rowId: id,
      );
      return _fromLegacy(ParcUser.fromJson(row.data));
    } on AppwriteException {
      final user = DatabaseGetter.user;
      if (user == null || user.$id != id) return null;

      final profile = ParcUser(
        id: user.$id,
        email: user.email,
        name: user.name,
        tel: user.phone,
      );
      return _fromLegacy(profile);
    }
  }

  @override
  Future<UserProfile> update(UserProfile profile) async {
    final database = DatabaseGetter.database;
    if (database == null) {
      throw StateError('Appwrite database is not initialized.');
    }

    final legacy = ParcUser(
      id: profile.id,
      email: profile.email,
      name: profile.name,
      tel: profile.phone,
      avatar: profile.avatar,
    );

    final row = await database.updateRow(
      databaseId: databaseId,
      tableId: userid,
      rowId: profile.id,
      data: legacy.toJson(),
    );

    return _fromLegacy(ParcUser.fromJson(row.data));
  }

  UserProfile _fromLegacy(ParcUser profile) {
    return UserProfile(
      id: profile.id,
      email: profile.email,
      name: profile.name,
      phone: profile.tel,
      avatar: profile.avatar,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }
}
