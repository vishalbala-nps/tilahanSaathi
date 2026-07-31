import 'package:firebase_auth/firebase_auth.dart';
import 'package:tilahan_saathi/core/network/api_client.dart';
import 'package:tilahan_saathi/core/storage/token_storage.dart';

/// Wraps Firebase Authentication and syncs the resulting session with the
/// Tilahan Saathi backend.
class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth}) : _firebaseAuthOverride = firebaseAuth;

  final FirebaseAuth? _firebaseAuthOverride;

  // Resolved lazily so constructing an AuthRepository never touches the
  // Firebase SDK unless one of its methods is actually called.
  FirebaseAuth get _firebaseAuth => _firebaseAuthOverride ?? FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Whether a backend access token from a previous login is still stored,
  /// i.e. whether the user can be signed in automatically on app start.
  Future<bool> hasStoredSession() async {
    final token = await tokenStorage.readAccessToken();
    return token != null;
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _loginToBackend(credential.user!);
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(fullName);
    await _loginToBackend(credential.user!);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await tokenStorage.clear();
  }

  /// Exchanges the Firebase ID token for a backend session and persists the
  /// resulting access token so the user stays signed in across app restarts.
  Future<void> _loginToBackend(User user) async {
    final idToken = await user.getIdToken();
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'firebase_id_token': idToken},
    );
    final accessToken = response.data!['access_token'] as String;
    await tokenStorage.saveAccessToken(accessToken);
  }
}
