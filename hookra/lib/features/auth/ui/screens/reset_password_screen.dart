import 'package:flutter/material.dart';
import 'package:hookra/features/auth/data/repo/auth_repo_impl.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _inProgress = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _inProgress = true);
    try {
      await AuthRepoImpl().resetPassword(_passwordController.text);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated. Please sign in with your new password.')));
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      // Friendly message and option to re-request
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('El enlace es inválido o expiró. ¿Deseas solicitar un nuevo correo de recuperación?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/forgot-password');
              },
              child: const Text('Sí'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _inProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text('Introduce una nueva contraseña.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa la contraseña';
                  if (v.length < 8) return 'Mínimo 8 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirma la contraseña';
                  if (v != _passwordController.text) return 'No coinciden';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _inProgress ? null : _submit,
                child: _inProgress ? const CircularProgressIndicator() : const Text('Actualizar contraseña'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
