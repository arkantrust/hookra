import 'package:flutter/material.dart';
import 'package:hookra/src/components/components.dart';

enum EmailFieldError { empty, noAtSymbol, noLocal, noDomain }

class EmailField extends StatelessWidget {
  final void Function(String) onChanged;
  final void Function(String)? onSubmitted;
  final EmailFieldError? validationError;
  final TextInputAction? textInputAction;

  const EmailField({
    super.key,
    required this.onChanged,
    required this.validationError,
    this.onSubmitted,
    this.textInputAction,
  });

  String? _getError(EmailFieldError? e) => switch (e) {
    EmailFieldError.empty => 'Escribe tu email',
    EmailFieldError.noAtSymbol => 'No incluiste un @',
    EmailFieldError.noLocal => 'No incluiste tu nombre de usuario',
    EmailFieldError.noDomain => 'No incluiste el dominio',
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    return ThemedTextField(
      label: 'Email',
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      error: _getError(validationError),
      enableSuggestions: true,
      keyboardType: TextInputType.emailAddress,
    );
  }
}
