import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';
import 'package:hookra/src/app/snack_bar.dart';
import 'package:hookra/src/auth/auth.dart';
import 'package:hookra/src/config/service_locator.dart';
import 'package:hookra/src/profile/domain/entities/user.dart';
import 'package:hookra/src/settings/ui/blocs/edit_profile_bloc/edit_profile_bloc.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  static GoRoute route() => GoRoute(
        path: '/settings/edit-profile',
        builder: (_, __) => const EditProfilePage(),
      );

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;

    return BlocProvider(
      create: (_) => sl<EditProfileBloc>()
        ..add(EditProfileFirstChanged(user.firstName))
        ..add(EditProfileLastChanged(user.lastName)),
      child: _EditProfileView(user: user),
    );
  }
}

class _EditProfileView extends StatefulWidget {
  final User user;

  const _EditProfileView({required this.user});

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  late final TextEditingController _firstController;
  late final TextEditingController _lastController;

  @override
  void initState() {
    super.initState();
    _firstController = TextEditingController(text: widget.user.firstName);
    _lastController = TextEditingController(text: widget.user.lastName);
  }

  @override
  void dispose() {
    _firstController.dispose();
    _lastController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;

    return BlocListener<EditProfileBloc, EditProfileState>(
      listener: (context, state) {
        if (state.status == FormzSubmissionStatus.success &&
            state.updatedUser != null) {
          context
              .read<AuthBloc>()
              .add(AuthProfileUpdated(state.updatedUser!));
          context.pop();
        }
        if (state.status == FormzSubmissionStatus.failure) {
          context.showSnackBar(state.error);
        }
      },
      child: Scaffold(
        backgroundColor: palette.surfaceContainerLowest,
        appBar: AppBar(
          backgroundColor: palette.surface,
          title: Text(
            'EDITAR PERFIL',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              fontSize: 16,
              color: palette.primary,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarSection(palette: palette),
              const SizedBox(height: 24),
              _FormSection(
                firstController: _firstController,
                lastController: _lastController,
                palette: palette,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final ColorScheme palette;
  const _AvatarSection({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: palette.surfaceContainerHighest,
            child: Icon(
              Icons.person,
              size: 56,
              color: palette.onSurfaceVariant,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: palette.primary,
                shape: BoxShape.circle,
                border: Border.all(color: palette.surface, width: 2),
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                size: 16,
                color: palette.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final TextEditingController firstController;
  final TextEditingController lastController;
  final ColorScheme palette;

  const _FormSection({
    required this.firstController,
    required this.lastController,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INFORMACIÓN PERSONAL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: palette.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<EditProfileBloc, EditProfileState>(
              buildWhen: (prev, curr) => prev.first != curr.first,
              builder: (context, state) => TextField(
                controller: firstController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onChanged: (v) =>
                    context.read<EditProfileBloc>().add(EditProfileFirstChanged(v)),
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  errorText: state.first.displayError != null
                      ? 'El nombre no puede estar vacío'
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<EditProfileBloc, EditProfileState>(
              buildWhen: (prev, curr) => prev.last != curr.last,
              builder: (context, state) => TextField(
                controller: lastController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onChanged: (v) =>
                    context.read<EditProfileBloc>().add(EditProfileLastChanged(v)),
                onSubmitted: (_) =>
                    context.read<EditProfileBloc>().add(const EditProfileSubmitted()),
                decoration: InputDecoration(
                  labelText: 'Apellido',
                  errorText: state.last.displayError != null
                      ? 'El apellido no puede estar vacío'
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            BlocBuilder<EditProfileBloc, EditProfileState>(
              buildWhen: (prev, curr) =>
                  prev.status != curr.status || prev.isValid != curr.isValid,
              builder: (context, state) {
                final loading =
                    state.status == FormzSubmissionStatus.inProgress;
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading || !state.isValid
                        ? null
                        : () => context
                            .read<EditProfileBloc>()
                            .add(const EditProfileSubmitted()),
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: palette.onPrimary,
                      disabledBackgroundColor:
                          palette.onSurface.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: loading
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: palette.onPrimary,
                            ),
                          )
                        : const Text('Guardar Cambios'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
