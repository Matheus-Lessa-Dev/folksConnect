abstract interface class AuthenticationService {
  Future<void> signIn({required String username, required String password});
}

class AuthenticationUnavailable implements Exception {
  const AuthenticationUnavailable();
}

class InvalidCredentials implements Exception {
  const InvalidCredentials();
}

/// Explicit local demo account requested for previewing the application.
/// This does not create a backend session or authorize access to real data.
class DemoAuthenticationService implements AuthenticationService {
  const DemoAuthenticationService();

  @override
  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    if (username.trim().toLowerCase() != 'joabe@gmail.com' ||
        password != '12345') {
      throw const InvalidCredentials();
    }
  }
}

/// Fallback for callers that have not configured an authentication service.
class UnavailableAuthenticationService implements AuthenticationService {
  const UnavailableAuthenticationService();

  @override
  Future<void> signIn({required String username, required String password}) {
    return Future<void>.error(const AuthenticationUnavailable());
  }
}
