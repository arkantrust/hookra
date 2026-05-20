import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hookra/src/auth/auth.dart';
import 'package:hookra/src/config/service_locator.dart';
import 'package:hookra/src/organizations/domain/failures/org_invite_failure.dart';
import 'package:hookra/src/organizations/domain/model/org_invite.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/use_cases/accept_invite_use_case.dart';
import 'package:hookra/src/organizations/domain/use_cases/get_invite_by_token_use_case.dart';

class AcceptInvitePage extends StatefulWidget {
  final String token;

  const AcceptInvitePage({super.key, required this.token});

  @override
  State<AcceptInvitePage> createState() => _AcceptInvitePageState();
}

class _AcceptInvitePageState extends State<AcceptInvitePage> {
  final _getInvite = sl<GetInviteByTokenUseCase>();
  final _acceptInvite = sl<AcceptInviteUseCase>();

  OrgInvite? _invite;
  bool _isLoading = true;
  bool _isAccepting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvite();
  }

  Future<void> _loadInvite() async {
    final result = await _getInvite(widget.token);
    if (!mounted) return;

    result.fold(
      (invite) {
        final loaded = invite!;
        String? error;
        if (loaded.isExpired) {
          error = 'Esta invitación ha expirado.';
        } else if (loaded.isAccepted) {
          error = 'Esta invitación ya fue aceptada.';
        }
        setState(() {
          _invite = loaded;
          _errorMessage = error;
          _isLoading = false;
        });
      },
      (error) {
        setState(() {
          _errorMessage = error is InviteNotFound
              ? 'Invitación no encontrada.'
              : 'Ocurrió un error al cargar la invitación.';
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _accept() async {
    final profileId = context.read<AuthBloc>().state.user.id;
    setState(() => _isAccepting = true);

    final result = await _acceptInvite(
      token: widget.token,
      profileId: profileId,
    );
    if (!mounted) return;

    result.fold(
      (_) => context.go('/organizations/${_invite!.organizationId}'),
      (error) {
        String message;
        if (error is InviteExpired) {
          message = 'Esta invitación ha expirado.';
        } else if (error is InviteAlreadyAccepted) {
          message = 'Esta invitación ya fue aceptada.';
        } else if (error is InviteEmailMismatch) {
          message =
              'Tu correo no coincide con el de la invitación (${_invite?.email}).';
        } else {
          message = 'No se pudo aceptar la invitación.';
        }
        setState(() {
          _errorMessage = message;
          _isAccepting = false;
        });
      },
    );
  }

  String _roleLabel(OrganizationRole role) {
    switch (role) {
      case OrganizationRole.owner:
        return 'Owner';
      case OrganizationRole.admin:
        return 'Admin';
      case OrganizationRole.member:
        return 'Member';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invitación')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _invite == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    final invite = _invite!;
    final isInvalid = invite.isExpired || invite.isAccepted;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_add, size: 64),
          const SizedBox(height: 24),
          Text(
            'Te han invitado a unirte',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Rol: ${_roleLabel(invite.role)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isInvalid || _isAccepting ? null : _accept,
              child: _isAccepting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Aceptar invitación'),
            ),
          ),
        ],
      ),
    );
  }
}
