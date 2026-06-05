import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hookra/src/auth/auth.dart';
import 'package:hookra/src/config/service_locator.dart';
import 'package:hookra/src/home/home.dart';
import 'package:hookra/src/organizations/domain/model/org_invite_details.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/ui/blocs/accept_invite_bloc/accept_invite_bloc.dart';

class AcceptInvitePage extends StatelessWidget {
  final String token;

  const AcceptInvitePage({super.key, required this.token});

  static GoRoute route() {
    return GoRoute(
      path: '/invite',
      builder: (context, state) => AcceptInvitePage(
        token: state.uri.queryParameters['token'] ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wait for auth to resolve before creating the invite bloc.
    // BlocBuilder rebuilds once when transitioning from unknown → known,
    // then buildWhen prevents further rebuilds from auth changes.
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) => prev.status == AuthStatus.unknown,
      builder: (context, authState) {
        if (authState.status == AuthStatus.unknown) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return BlocProvider(
          create: (context) => sl<AcceptInviteBloc>()
            ..add(AcceptInviteLoadRequested(
              token: token,
              currentUserEmail: authState.status == AuthStatus.authenticated
                  ? authState.user.email
                  : null,
            )),
          child: BlocListener<AcceptInviteBloc, AcceptInviteState>(
            listener: (context, state) {
              if (state is AcceptInviteAccepted) {
                context.go(HomePage.route().path);
              }
            },
            child: _AcceptInviteView(token: token),
          ),
        );
      },
    );
  }
}

class _AcceptInviteView extends StatelessWidget {
  final String token;

  const _AcceptInviteView({required this.token});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AcceptInviteBloc, AcceptInviteState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Invitación'),
            automaticallyImplyLeading: false,
            actions: [
              if (state is AcceptInviteLoaded && !state.canAccept)
                IconButton(
                  icon: const Icon(Icons.login),
                  tooltip: 'Iniciar sesión',
                  onPressed: () => context.push(SignInPage.route().path),
                )
              else
                IconButton(
                  icon: const Icon(Icons.home_outlined),
                  tooltip: 'Ir al inicio',
                  onPressed: () => context.go(HomePage.route().path),
                ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: switch (state) {
                AcceptInviteInitial() ||
                AcceptInviteLoading() =>
                  const Center(child: CircularProgressIndicator()),
                AcceptInviteLoaded() => _LoadedBody(state: state, token: token),
                AcceptInviteExpired(details: final d) => _InfoBody(
                    details: d,
                    message: 'Esta invitación ha vencido',
                    messageColor: Theme.of(context).colorScheme.error,
                  ),
                AcceptInviteNotForUser(details: final d) => _InfoBody(
                    details: d,
                    message: 'Esta invitación no es para ti',
                    messageColor: Theme.of(context).colorScheme.error,
                    action: FilledButton(
                      onPressed: () => context.go(HomePage.route().path),
                      child: const Text('Ir al inicio'),
                    ),
                  ),
                AcceptInviteAccepting() =>
                  const Center(child: CircularProgressIndicator()),
                AcceptInviteAccepted() =>
                  const Center(child: CircularProgressIndicator()),
                AcceptInviteError(message: final msg, token: final t) =>
                  _ErrorBody(
                    message: msg,
                    onRetry: t != null
                        ? () {
                            final authState = context.read<AuthBloc>().state;
                            context.read<AcceptInviteBloc>().add(
                              AcceptInviteLoadRequested(
                                token: t,
                                currentUserEmail:
                                    authState.status == AuthStatus.authenticated
                                        ? authState.user.email
                                        : null,
                              ),
                            );
                          }
                        : null,
                  ),
              },
            ),
          ),
        );
      },
    );
  }
}

class _LoadedBody extends StatelessWidget {
  final AcceptInviteLoaded state;
  final String token;

  const _LoadedBody({required this.state, required this.token});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InviteCard(details: state.details),
        const SizedBox(height: 32),
        if (!state.canAccept) ...[
          const Icon(Icons.lock_outline, size: 40, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'Debes iniciar sesión para aceptar esta invitación',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ] else
          BlocBuilder<AcceptInviteBloc, AcceptInviteState>(
            builder: (context, state) {
              final isAccepting = state is AcceptInviteAccepting;
              return FilledButton(
                onPressed: isAccepting
                    ? null
                    : () => context
                        .read<AcceptInviteBloc>()
                        .add(const AcceptInviteAcceptPressed()),
                child: isAccepting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Aceptar invitación'),
              );
            },
          ),
      ],
    );
  }
}

class _InviteCard extends StatelessWidget {
  final OrgInviteDetails details;

  const _InviteCard({required this.details});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Organización', style: textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(
              details.organizationName,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 28),
            Text('Invitado por', style: textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(details.ownerFullName, style: textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text('Rol asignado', style: textTheme.labelMedium),
            const SizedBox(height: 4),
            _RoleChip(role: details.invite.role),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final OrganizationRole role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      OrganizationRole.owner => ('Owner', Colors.green),
      OrganizationRole.admin => ('Admin', Colors.blue),
      OrganizationRole.member => ('Miembro', Colors.grey),
    };

    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      side: BorderSide.none,
    );
  }
}

class _InfoBody extends StatelessWidget {
  final OrgInviteDetails details;
  final String message;
  final Color messageColor;
  final Widget? action;

  const _InfoBody({
    required this.details,
    required this.message,
    required this.messageColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InviteCard(details: details),
        const SizedBox(height: 24),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: messageColor, fontWeight: FontWeight.w500),
        ),
        if (action != null) ...[
          const SizedBox(height: 16),
          action!,
        ],
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorBody({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ],
    );
  }
}
