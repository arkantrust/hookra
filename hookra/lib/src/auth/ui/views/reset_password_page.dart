import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';

import 'package:hookra/src/app/snack_bar.dart';
import 'package:hookra/src/auth/auth.dart';
import 'package:hookra/src/components/components.dart';
import 'package:hookra/src/config/service_locator.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  static GoRoute route() {
    return GoRoute(
      path: '/auth/reset-password',
      builder: (context, state) => const ResetPasswordPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ResetPasswordBloc>(),
      child: const _ResetPasswordView(),
    );
  }
}

class _ResetPasswordView extends StatelessWidget {
  const _ResetPasswordView();

  void _showExpiredDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enlace inválido o expirado'),
        content: const Text(
          'El enlace de recuperación es inválido o ya expiró. ¿Deseas solicitar un nuevo correo?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go(ForgotPasswordPage.route().path);
            },
            child: const Text('Sí, solicitar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('No'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false, // No back button — one-shot flow
          title: const Text('Nueva contraseña'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: BlocListener<ResetPasswordBloc, ResetPasswordState>(
            listenWhen: (previous, current) => previous.status != current.status,
            listener: (context, state) {
              if (state.status.isSuccess) {
                HapticFeedback.lightImpact();
                context.showSnackBar('Contraseña actualizada. Inicia sesión.');
                context.go(SignInPage.route().path);
              } else if (state.status.isFailure) {
                HapticFeedback.mediumImpact();
                if (state.error == 'token_expired') {
                  _showExpiredDialog(context);
                } else {
                  context.showSnackBar(state.error);
                }
              }
            },
            child: Align(
              alignment: const Alignment(0, -1 / 3),
              child: BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
                builder: (context, state) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Elige una nueva contraseña',
                            textScaler: MediaQuery.textScalerOf(context),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: 50),

                        // New password field
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: PasswordField(
                            label: 'Nueva contraseña',
                            onChanged: (password) {
                              context
                                  .read<ResetPasswordBloc>()
                                  .add(ResetPasswordNewChanged(password));
                            },
                            validationError: context.select(
                              (ResetPasswordBloc bloc) =>
                                  bloc.state.newPassword.displayError?.toFieldError(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Confirm password field
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: PasswordField(
                            label: 'Confirmar contraseña',
                            onChanged: (password) {
                              context
                                  .read<ResetPasswordBloc>()
                                  .add(ResetPasswordConfirmChanged(password));
                            },
                            validationError: context.select(
                              (ResetPasswordBloc bloc) =>
                                  bloc.state.confirm.displayError?.toFieldError(),
                            ),
                            onSubmitted: (_) {
                              if (state.isValid) {
                                context
                                    .read<ResetPasswordBloc>()
                                    .add(const ResetPasswordSubmitted());
                              }
                            },
                            textInputAction: TextInputAction.send,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Submit button
                        ThemedTextButton(
                          isInProgressOrSuccess: context.select(
                            (ResetPasswordBloc bloc) =>
                                bloc.state.status.isInProgressOrSuccess,
                          ),
                          onPressed: context.select(
                                    (ResetPasswordBloc bloc) => bloc.state.isValid,
                                  ) &&
                                  !state.status.isInProgressOrSuccess
                              ? () {
                                  context
                                      .read<ResetPasswordBloc>()
                                      .add(const ResetPasswordSubmitted());
                                }
                              : null,
                          text: 'Actualizar contraseña',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
