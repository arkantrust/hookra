import 'dart:developer';

/// A result is an abstraction over the success and failure of an operation.
/// Inspired by Go's error handling, it allows you to handle success and failure cases without exceptions,
/// making code much more readable.
class Result<T> {
  final T? _value;

  final Exception? _error;

  /// Optionally provide a stack trace for unknown errors.
  final StackTrace? stackTrace;

  /// Use this constructor for success results.
  const Result.success(T value) : _value = value, _error = null, stackTrace = null;

  /// Use this constructor for failure results.
  Result.failure(Exception error, [StackTrace? stackTrace])
    : _value = null as T?,
      _error = error,
      stackTrace = stackTrace ?? StackTrace.current {
    log(_error.toString(), stackTrace: stackTrace);
  }

  /// Use this constructor for void results (no value).
  const Result.voidResult() : _value = null as T?, _error = null, stackTrace = null;

  /// Use this constructor for unknown failures (e.g., caught errors that are not Exception).
  /// Specially useful for logging and debugging.
  Result.unknown({required String name, required Object error, required StackTrace this.stackTrace})
    : _value = null as T?,
      _error = error is Exception ? error : Exception(error.toString()) {
    log('Unknown error in $name: $error', stackTrace: stackTrace);
  }

  /// Check if the result is a success.
  bool get isSuccess => _value != null && _error == null;

  /// Check if the result is a failure.
  bool get isFailure => _error != null;

  /// Get value (throws if failure)
  T get value {
    if (isFailure) {
      throw _error!;
    }
    return _value!;
  }

  /// Get error (throws if success)
  Exception get error {
    if (isSuccess) {
      throw StateError('Cannot get error from a successful result');
    }
    return _error!;
  }

  /// Get value or null
  T? get valueOrNull {
    if (isFailure) {
      return null;
    }
    return _value;
  }

  /// Get error or null
  Exception? get errorOrNull {
    if (isSuccess) {
      return null;
    }
    return _error;
  }

  /// Handle both cases
  U fold<U>(U Function(T?) onSuccess, U Function(Exception) onFailure) {
    if (isSuccess) {
      return onSuccess(_value);
    }
    return onFailure(_error!);
  }
}
