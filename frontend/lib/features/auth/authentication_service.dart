abstract interface class AuthenticationService {
  Future<void> signIn({required String username, required String password});
}

class AuthenticationUnavailable implements Exception {
  const AuthenticationUnavailable();
}

/// The backend currently has no authentication endpoint. Never fake a session.
class UnavailableAuthenticationService implements AuthenticationService {
  const UnavailableAuthenticationService();

  @override
  Future<void> signIn({required String username, required String password}) {
    return Future<void>.error(const AuthenticationUnavailable());
  }
}
