import 'dart:async';

import 'package:appwrite/appwrite.dart' hide Role;
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/client_database.dart';
import '../licensing/edition.dart';
import '../licensing/license.dart';
import '../permissions/role.dart';
import '../../domain/repositories/permission_repository.dart';
import '../tenancy/company_context.dart';
import 'auth_service.dart';
import 'auth_session.dart';
import 'auth_state.dart';

/// Transitional adapter around the existing Appwrite authentication stack.
class LegacyAppwriteAuthService implements AuthService {
  final SharedPreferences preferences;
  final ParcotoEdition edition;
  final PermissionRepository permissionRepository;

  AuthState _state = AuthState.unknown;
  AuthSession? _session;
  final StreamController<AuthState> _stateController =
      StreamController<AuthState>.broadcast();

  LegacyAppwriteAuthService({
    required this.preferences,
    required this.permissionRepository,
    this.edition = ParcotoEdition.online,
  });

  @override
  AuthState get state => _state;

  @override
  AuthSession? get session => _session;

  @override
  Stream<AuthState> get stateStream => _stateController.stream;

  void _setState(AuthState value) {
    _state = value;
    if (!_stateController.isClosed) {
      _stateController.add(value);
    }
  }

  @override
  Future<AuthSession?> restoreSession() async {
    if (_state == AuthState.restoring) return _session;
    _setState(AuthState.restoring);

    final configuredProject = preferences.getString('project');
    if (configuredProject == null || configuredProject.isEmpty) {
      _session = null;
      _setState(AuthState.signedOut);
      return null;
    }

    try {
      project = configuredProject;
      final databaseGetter = DatabaseGetter();
      await databaseGetter.getUser();

      if (DatabaseGetter.user == null || DatabaseGetter.me.value == null) {
        _session = null;
        _setState(AuthState.signedOut);
        return null;
      }

      _resolvedRole = await permissionRepository.getCurrentRole();
      _session = _buildSessionWithRole(configuredProject, _resolvedRole);
      _setState(AuthState.signedIn);
      return _session;
    } catch (_) {
      _session = null;
      _setState(AuthState.signedOut);
      return null;
    }
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
    String? projectId,
  }) async {
    _setState(AuthState.signingIn);

    final resolvedProject =
        (projectId ?? preferences.getString('project') ?? '').trim();
    if (resolvedProject.isEmpty) {
      _setState(AuthState.error);
      throw StateError('A Parcoto project ID is required.');
    }

    try {
      project = resolvedProject;
      final databaseGetter = DatabaseGetter();
      final account = DatabaseGetter.account;
      if (account == null) {
        throw StateError('Appwrite account is not initialized.');
      }

      // There may be no active session yet. Appwrite returns
      // general_unauthorized_scope in that case, so this cleanup is best-effort.
      try {
        await account.deleteSessions();
      } on AppwriteException {
        // No existing session: continue with the actual login.
      }

      await account.createEmailPasswordSession(
        email: email.trim(),
        password: password,
      );
      await preferences.setString('project', resolvedProject);

      DatabaseGetter.user = null;
      DatabaseGetter.me.value = null;
      await databaseGetter.getUser();

      if (DatabaseGetter.user == null || DatabaseGetter.me.value == null) {
        throw StateError(
          'Authentication succeeded but the Parcoto profile could not be loaded.',
        );
      }

      _resolvedRole = await permissionRepository.getCurrentRole();
      _session = _buildSessionWithRole(resolvedProject, _resolvedRole);
      _setState(AuthState.signedIn);
      return _session!;
    } on AppwriteException {
      _session = null;
      _setState(AuthState.error);
      rethrow;
    } catch (_) {
      _session = null;
      _setState(AuthState.error);
      rethrow;
    }
  }

  Role _resolvedRole = Role.user;

  AuthSession _buildSessionWithRole(String projectId, Role role) {
    final user = DatabaseGetter.user!;
    final profile = DatabaseGetter.me.value!;

    final trialDate = DatabaseGetter.trialDate;
    final limits = DatabaseGetter.limits;
    final license = License(
      id: '${projectId}_${user.$id}',
      companyId: projectId,
      edition: edition,
      expiresAt: trialDate,
      maxUsers: limits['users'],
      maxVehicles: limits['vehicles'],
    );

    return AuthSession(
      userId: user.$id,
      email: user.email,
      displayName: profile.name ?? user.name,
      company: CompanyContext(companyId: projectId),
      role: role,
      license: license,
    );
  }

  @override
  Future<void> signOut() async {
    _setState(AuthState.signingOut);
    try {
      await DatabaseGetter.account?.deleteSession(sessionId: 'current');
    } finally {
      DatabaseGetter.user = null;
      DatabaseGetter.me.value = null;
      _session = null;
      _setState(AuthState.signedOut);
    }
  }
}
