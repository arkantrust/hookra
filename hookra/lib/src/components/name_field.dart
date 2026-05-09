import 'package:flutter/material.dart';
import 'package:hookra/src/components/components.dart';

enum NameFieldError { empty }

class NameField extends StatelessWidget {
  final String label;
  final NameFieldError? validationError;
  final void Function(String) onChanged;
  final void Function(String)? onSubmitted;
  final TextInputAction? textInputAction;

  const NameField({
    super.key,
    required this.label,
    required this.onChanged,
    required this.validationError,
    this.onSubmitted,
    this.textInputAction,
  });

  String? _getError(NameFieldError? e) => switch (e) {
    NameFieldError.empty => 'Escribe tu ${label.toLowerCase()}',
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
      enableSuggestions: true,
      textCapitalization: TextCapitalization.words,
      keyboardType: TextInputType.name,
    );
  }
}
