import 'package:flutter/material.dart';

import 'themed_text_field.dart';

enum PasswordFieldError {
  empty,
  lessThan12Chars,
  noNumber,
  noUpper,
  noLower,
  hasSpaces,
  noSymbol,
}

class PasswordField extends StatelessWidget {
  final String label;
  final void Function(String) onChanged;
  final void Function(String)? onSubmitted;
  final PasswordFieldError? validationError;
  final TextInputAction? textInputAction;

  const PasswordField({
    super.key,
    required this.onChanged,
    required this.validationError,
    this.label = 'Contraseña',
    this.onSubmitted,
    this.textInputAction,
  });

  String? _getError(PasswordFieldError? e) => switch (e) {
    PasswordFieldError.empty => 'Escribe tu contraseña',
    PasswordFieldError.lessThan12Chars => 'Debe tener al menos 12 caracteres',
    PasswordFieldError.noNumber => 'Debe incluir al menos un número',
    PasswordFieldError.noUpper => 'Debe incluir al menos una letra mayúscula',
    PasswordFieldError.noLower => 'Debe incluir al menos una letra minúscula',
    PasswordFieldError.hasSpaces => 'No debe contener espacios',
    PasswordFieldError.noSymbol => 'Debe incluir al menos un carácter especial',
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    return ThemedTextField(
      label: label,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      error: _getError(validationError),
      obscure: true,
      keyboardType: TextInputType.visiblePassword,
    );
  }
}
