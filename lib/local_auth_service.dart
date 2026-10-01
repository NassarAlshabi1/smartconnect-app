class LocalUser {
  final String uid;
  const LocalUser(this.uid);
}

class AuthResult {
  final LocalUser user;
  const AuthResult(this.user);
}

class AuthService {
  AuthService._();
  static final instance = AuthService._();
  LocalUser? currentUser;
  Future<AuthResult> signIn(String username, String password) async {
    if (username == 'admin' && password == 'admin') {
      currentUser = const LocalUser('admin-uid');
      return AuthResult(currentUser!);
    }
    throw const AuthException('invalid-credentials');
  }

  Future<void> signOut() async {
    currentUser = null;
  }

  Future<AuthResult> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final user = LocalUser('user-${email.hashCode.abs()}');
    currentUser = user;
    return AuthResult(user);
  }
}

class AuthException implements Exception {
  final String code;
  const AuthException(this.code);
}
