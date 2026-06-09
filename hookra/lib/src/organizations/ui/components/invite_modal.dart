import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/ui/blocs/invite_bloc/invite_bloc.dart';
import 'package:hookra/src/organizations/ui/components/role_picker.dart';

class InviteModal extends StatefulWidget {
  final String organizationId;

  const InviteModal({super.key, required this.organizationId});

  @override
  State<InviteModal> createState() => _InviteModalState();
}

class _InviteModalState extends State<InviteModal> {
  final _emailController = TextEditingController();
  OrganizationRole _selectedRole = OrganizationRole.member;
  bool _isValidEmail = false;

  bool _validateEmail(String value) {
    final at = value.indexOf('@');
    return at > 0 && at < value.length - 1;
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      final valid = _validateEmail(_emailController.text.trim());
      if (valid != _isValidEmail) setState(() => _isValidEmail = valid);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InviteBloc, InviteState>(
      builder: (context, state) {
        final isLoading = state.status == InviteStatus.loading;

        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invitar miembro',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  hintText: 'usuario@ejemplo.com',
                  border: OutlineInputBorder(),
                ),
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Rol:', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(width: 12),
                  RolePicker(
                    role: _selectedRole,
                    isInteractive: !isLoading,
                    allowedRoles: const [
                      OrganizationRole.admin,
                      OrganizationRole.member,
                    ],
                    onRoleSelected: (role) =>
                        setState(() => _selectedRole = role),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLoading || !_isValidEmail ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Generar link'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submit() {
    final email = _emailController.text.trim();
    if (!_isValidEmail) return;

    context.read<InviteBloc>().add(
      InviteSubmitted(
        organizationId: widget.organizationId,
        email: email,
        role: _selectedRole,
      ),
    );
  }
}
