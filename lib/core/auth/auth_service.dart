import 'auth_session.dart';
import 'auth_state.dart';

abstract class AuthService {
  AuthState get state;
  AuthSession? get session;
  Stream<AuthState> get stateStream;

  Future<AuthSession?> restoreSession();
  Future<AuthSession> signIn({
    required String email,
    required String password,
    String? projectId,
  });
  Future<void> signOut();
}
