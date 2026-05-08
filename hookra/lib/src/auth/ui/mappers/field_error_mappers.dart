import 'package:hookra/src/auth/domain/value_objects/email.dart';
import 'package:hookra/src/auth/domain/value_objects/name.dart';
import 'package:hookra/src/auth/domain/value_objects/password.dart';
import 'package:hookra/src/components/components.dart';

extension EmailValidationErrorX on EmailValidationError {
  EmailFieldError toFieldError() => switch (this) {
    EmailValidationError.empty => EmailFieldError.empty,
    EmailValidationError.noAtSymbol => EmailFieldError.noAtSymbol,
    EmailValidationError.noLocal => EmailFieldError.noLocal,
    EmailValidationError.noDomain => EmailFieldError.noDomain,
  };
}

extension NameValidationErrorX on NameValidationError {
  NameFieldError toFieldError() => switch (this) {
    NameValidationError.empty => NameFieldError.empty,
  };
}

extension PasswordValidationErrorX on PasswordValidationError {
  PasswordFieldError toFieldError() => switch (this) {
    PasswordValidationError.empty => PasswordFieldError.empty,
    PasswordValidationError.lessThan12Chars => PasswordFieldError.lessThan12Chars,
    PasswordValidationError.noNumber => PasswordFieldError.noNumber,
    PasswordValidationError.noUpper => PasswordFieldError.noUpper,
    PasswordValidationError.noLower => PasswordFieldError.noLower,
    PasswordValidationError.hasSpaces => PasswordFieldError.hasSpaces,
    PasswordValidationError.noSymbol => PasswordFieldError.noSymbol,
  };
}
