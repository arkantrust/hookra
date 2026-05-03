import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hookra/src/config/config.dart';
import 'package:hookra/src/home/blocs/location_permission_bloc/location_permission_bloc.dart';

class LocationPermissionPage extends StatelessWidget {
  const LocationPermissionPage({super.key});

  static GoRoute route() => GoRoute(
    path: '/permissions/location',
    builder: (context, state) => const LocationPermissionPage(),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<LocationPermissionBloc>(),
      child: const LocationPermissionView(),
    );
  }
}

class LocationPermissionView extends StatelessWidget {
  const LocationPermissionView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocationPermissionBloc, LocationPermissionState>(
      listener: (context, state) {
        if (state.status == LocationPermissionStatus.granted) context.go('/');
      },
      child: SafeArea(
        child: Scaffold(
          body: BlocBuilder<LocationPermissionBloc, LocationPermissionState>(
            builder: (context, state) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (state.status == LocationPermissionStatus.checking)
                        const _LoadingWidget()
                      else
                        _PermissionContentWidget(state: state),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Verificando permisos...'),
      ],
    );
  }
}

class _PermissionContentWidget extends StatelessWidget {
  const _PermissionContentWidget({required this.state});

  final LocationPermissionState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(_getIcon(), size: 80, color: _getIconColor()),
        const SizedBox(height: 24),
        Text(
          _getTitle(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          _getDescription(),
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        if (state.message != null) ...[
          const SizedBox(height: 12),
          Text(
            state.message!,
            style: TextStyle(fontSize: 14, color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 32),
        _buildActionButtons(context),
      ],
    );
  }

  IconData _getIcon() {
    return switch (state.status) {
      LocationPermissionStatus.granted => Icons.location_on,
      LocationPermissionStatus.serviceDisabled => Icons.location_disabled,
      _ => Icons.location_off,
    };
  }

  Color _getIconColor() {
    return switch (state.status) {
      LocationPermissionStatus.granted => Colors.green,
      LocationPermissionStatus.serviceDisabled => Colors.orange,
      _ => Colors.red,
    };
  }

  String _getTitle() {
    return switch (state.status) {
      LocationPermissionStatus.granted => '¡Permiso Otorgado!',
      LocationPermissionStatus.serviceDisabled => 'Servicios de Ubicación Deshabilitados',
      LocationPermissionStatus.permanentlyDenied => 'Permiso Denegado Permanentemente',
      _ => 'Permiso de Ubicación Requerido',
    };
  }

  String _getDescription() {
    return switch (state.status) {
      LocationPermissionStatus.granted => 'Ya puedes usar la aplicación completa.',
      LocationPermissionStatus.serviceDisabled =>
        'Para usar esta aplicación, necesitas habilitar los servicios de ubicación en la configuración de tu dispositivo.',
      LocationPermissionStatus.permanentlyDenied =>
        'El permiso de ubicación ha sido denegado permanentemente. Para usar la aplicación, debes habilitarlo manualmente en la configuración.',
      _ =>
        'Esta aplicación necesita acceso a tu ubicación para funcionar correctamente. Tu ubicación se usa para añadirla a los reportes que crees.',
    };
  }

  Widget _buildActionButtons(BuildContext context) {
    return switch (state.status) {
      LocationPermissionStatus.denied => Column(
        children: [
          ElevatedButton(
            onPressed: () {
              context.read<LocationPermissionBloc>().add(
                const LocationPermissionRequestRequested(),
              );
            },
            child: const Text('Otorgar Permiso'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              context.read<LocationPermissionBloc>().add(const LocationPermissionRetryRequested());
            },
            child: const Text('Verificar Nuevamente'),
          ),
        ],
      ),
      LocationPermissionStatus.permanentlyDenied ||
      LocationPermissionStatus.serviceDisabled => Column(
        children: [
          ElevatedButton(
            onPressed: () => openAppSettings(),
            child: const Text('Abrir Configuración'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              context.read<LocationPermissionBloc>().add(const LocationPermissionRetryRequested());
            },
            child: const Text('Verificar Nuevamente'),
          ),
        ],
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
