import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';

import 'package:hookra/src/app/snack_bar.dart';
import 'package:hookra/src/auth/auth.dart';
import 'package:hookra/src/components/components.dart';
import 'package:hookra/src/config/service_locator.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  static GoRoute route() {
    return GoRoute(
      path: '/auth/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ForgotPasswordBloc>(),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatelessWidget {
  const _ForgotPasswordView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: BackButton(
            onPressed: () => context.pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
            listenWhen: (previous, current) => previous.status != current.status,
            listener: (context, state) {
              if (state.status.isSuccess) {
                HapticFeedback.lightImpact();
                // Neutral message — never reveal whether the email is registered.
                context.showSnackBar(
                  'Si existe una cuenta con ese correo, recibirás instrucciones en breve.',
                );
                context.pop();
              }
            },
            child: Align(
              alignment: const Alignment(0, -1 / 3),
              child: BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
                builder: (context, state) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Recuperar contraseña',
                            textScaler: MediaQuery.textScalerOf(context),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Text(
                            'Introduce tu email y te enviaremos instrucciones para recuperar tu contraseña.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Email field
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: EmailField(
                            onChanged: (email) {
                              context
                                  .read<ForgotPasswordBloc>()
                                  .add(ForgotPasswordEmailChanged(email));
                            },
                            validationError: context.select(
                              (ForgotPasswordBloc bloc) =>
                                  bloc.state.email.displayError?.toFieldError(),
                            ),
                            textInputAction: TextInputAction.send,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Submit button
                        ThemedTextButton(
                          isInProgressOrSuccess: context.select(
                            (ForgotPasswordBloc bloc) =>
                                bloc.state.status.isInProgressOrSuccess,
                          ),
                          onPressed: context.select(
                                    (ForgotPasswordBloc bloc) => bloc.state.isValid,
                                  ) &&
                                  !state.status.isInProgressOrSuccess
                              ? () {
                                  context
                                      .read<ForgotPasswordBloc>()
                                      .add(const ForgotPasswordSubmitted());
                                }
                              : null,
                          text: 'Enviar instrucciones',
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
