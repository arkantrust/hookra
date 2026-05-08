class EmailNotFound implements Exception {
  const EmailNotFound();
}

class EmailAlreadyExists implements Exception {
  const EmailAlreadyExists();
}

class WrongPassword implements Exception {
  const WrongPassword();
}

class WeakPassword implements Exception {
  const WeakPassword();
}

class NoSessionFound implements Exception {
  const NoSessionFound();
}

/// Thrown when a password recovery link has expired or is otherwise invalid.
class InvalidOrExpiredToken implements Exception {
  const InvalidOrExpiredToken();
}

/// Thrown when a password reset operation fails for an unspecified reason.
class PasswordResetFailed implements Exception {
  const PasswordResetFailed();
}
