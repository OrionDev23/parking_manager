import 'dart:async';

import '../tenancy/company_membership_resolver.dart';

import 'package:appwrite/appwrite.dart' hide Role;
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/client_database.dart';
import '../licensing/edition.dart';
import '../licensing/license.dart';
import '../../domain/repositories/access_control_repository.dart';
import '../tenancy/company_context.dart';
import 'auth_service.dart';
import 'auth_session.dart';
import 'auth_state.dart';

/// Transitional adapter around the existing Appwrite authentication stack.
class LegacyAppwriteAuthService implements AuthService {
  final SharedPreferences preferences;
  final ParcotoEdition edition;
  final AccessControlRepository accessControlRepository;
  final Future<void> Function()? onSessionEnding;
  final CompanyMembershipResolver membershipResolver =
      CompanyMembershipResolver();

  AuthState _state = AuthState.unknown;
  AuthSession? _session;
  Future<AuthSession?>? _restoreInFlight;
  final StreamController<AuthState> _stateController =
      StreamController<AuthState>.broadcast();

  LegacyAppwriteAuthService({
    required this.preferences,
    required this.accessControlRepository,
    this.onSessionEnding,
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
  Future<AuthSession?> restoreSession() {
    final inFlight = _restoreInFlight;
    if (inFlight != null) return inFlight;

    final restoration = _restoreSession();
    _restoreInFlight = restoration;
    return restoration.whenComplete(() {
      if (identical(_restoreInFlight, restoration)) {
        _restoreInFlight = null;
      }
    });
  }

  Future<AuthSession?> _restoreSession() async {
    _setState(AuthState.restoring);

    try {
      await onSessionEnding?.call();
      project = appwriteProjectId;
      final databaseGetter = DatabaseGetter();
      await databaseGetter.getUser();

      if (DatabaseGetter.user == null || DatabaseGetter.me.value == null) {
        _session = null;
        _setState(AuthState.signedOut);
        return null;
      }

      if (await membershipResolver.resolvePlatformSession()) {
        _session = _buildPlatformSession();
        _setState(AuthState.signedIn);
        return _session;
      }

      // "project" is retained only as a legacy company selector. Appwrite's
      // project is fixed and never comes from user input or preferences.
      final selector = preferences.getString('active_company_id') ??
          preferences.getString('project');
      final membership = await membershipResolver.select(selector: selector);
      await preferences.setString('active_company_id', membership.companyId);

      _session = _buildSession(membership.companyId, membership.permissions);
      _setState(AuthState.signedIn);
      return _session;
    } on CompanySelectionRequired {
      rethrow;
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
    String? companyId,
  }) async {
    _setState(AuthState.signingIn);

    try {
      // Stop the previous tenant's sync before replacing its session state.
      await onSessionEnding?.call();
      project = appwriteProjectId;
      final databaseGetter = DatabaseGetter();
      final account = DatabaseGetter.account;
      if (account == null) {
        throw StateError('Appwrite account is not initialized.');
      }

      try {
        await account.deleteSessions();
      } on AppwriteException {
        // No existing session: continue with the actual login.
      }

      await account.createEmailPasswordSession(
        email: email.trim(),
        password: password,
      );

      DatabaseGetter.user = null;
      DatabaseGetter.me.value = null;
      await databaseGetter.getUser();

      if (DatabaseGetter.user == null || DatabaseGetter.me.value == null) {
        throw StateError(
          'Authentication succeeded but the Parcoto profile could not be loaded.',
        );
      }

      if (await membershipResolver.resolvePlatformSession()) {
        _session = _buildPlatformSession();
        _setState(AuthState.signedIn);
        return _session!;
      }

      final membership = await membershipResolver.select(
        selector: companyId,
      );
      await preferences.setString('active_company_id', membership.companyId);
      // Keep the old key as a company selector for older UI code only.
      await preferences.setString('project', membership.companyId);

      _session = _buildSession(membership.companyId, membership.permissions);
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

  AuthSession _buildPlatformSession() {
    final user = DatabaseGetter.user!;
    final profile = DatabaseGetter.me.value!;
    return AuthSession(
      userId: user.$id,
      email: user.email,
      displayName: profile.name ?? user.name,
      company: const CompanyContext(companyId: '__platform__'),
      permissions: const {'platform.manage'},
      isPlatformSuperAdmin: true,
    );
  }

  AuthSession _buildSession(String projectId, Set<String> permissions) {
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
      permissions: permissions,
      license: license,
    );
  }

  @override
  Future<AuthSession> selectCompany(String companyId) async {
    if (DatabaseGetter.user == null || DatabaseGetter.me.value == null) {
      throw StateError('Aucune session Appwrite authentifiée.');
    }
    final membership = await membershipResolver.select(selector: companyId);
    await preferences.setString('active_company_id', membership.companyId);
    await preferences.setString('project', membership.companyId);
    _session = _buildSession(membership.companyId, membership.permissions);
    _setState(AuthState.signedIn);
    return _session!;
  }

  @override
  Future<void> signOut() async {
    _setState(AuthState.signingOut);
    try {
      await onSessionEnding?.call();
      await DatabaseGetter.account?.deleteSession(sessionId: 'current');
    } finally {
      DatabaseGetter.user = null;
      DatabaseGetter.me.value = null;
      _session = null;
      _setState(AuthState.signedOut);
    }
  }
}
