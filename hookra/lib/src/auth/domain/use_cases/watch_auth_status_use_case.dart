import 'package:hookra/src/auth/domain/repo/auth_repository.dart';

/// {@template watch_auth_status_use_case}
/// Streams the current [AuthStatus] of the user.
/// {@endtemplate}
class WatchAuthStatusUseCase {
  final AuthRepository _repository;

  WatchAuthStatusUseCase(this._repository);

  Stream<AuthStatus> call() => _repository.status;
}
