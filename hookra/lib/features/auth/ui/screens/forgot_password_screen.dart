import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/features/auth/ui/bloc/forgot_password_bloc.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _emailController = TextEditingController();

    return BlocProvider(
      create: (_) => ForgotPasswordBloc(),
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(title: const Text('Recuperar contraseña')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Introduce tu email y te enviaremos instrucciones para recuperar tu contraseña. Si existe una cuenta, recibirás un correo.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 24),
                BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
                  listener: (context, state) {
                    if (state is ForgotPasswordSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('If an account exists for this email, you will receive password recovery instructions.'),
                        ),
                      );
                      Navigator.pop(context);
                    } else if (state is ForgotPasswordFailure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message)),
                      );
                    }
                  },
                  builder: (context, state) {
                    final inProgress = state is ForgotPasswordLoading;
                    return ElevatedButton(
                      onPressed: inProgress
                          ? null
                          : () {
                              final email = _emailController.text.trim();
                              context.read<ForgotPasswordBloc>().add(ForgotPasswordSubmitted(email));
                            },
                      child: inProgress
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Enviar instrucciones'),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
