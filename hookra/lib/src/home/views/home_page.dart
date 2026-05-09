import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:hookra/src/config/service_locator.dart';
import 'package:hookra/src/home/home.dart';
import 'package:hookra/src/authentication/authentication.dart';
import 'package:hookra/src/organizations/data/repo/organization_repository_impl.dart';
import 'package:hookra/src/organizations/data/sources/organization_data_source.dart';
import 'package:hookra/src/organizations/domain/usecase/update_member_role_usecase.dart';
import 'package:hookra/src/organizations/ui/bloc/organization_members_bloc.dart';
import 'package:hookra/src/organizations/ui/organization_members_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static GoRoute route() {
    return GoRoute(path: '/', builder: (context, state) => const HomePage());
  }

  @override
  Widget build(BuildContext context) {
    developer.log('HomePage build', name: 'DEBUG');
    return BlocProvider(create: (_) => sl<PositionCubit>(), child: const MapView());
  }
}

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final Completer<GoogleMapController> _controller = Completer();
  String _debugLog = '';

  void _log(String msg) {
    setState(() {
      _debugLog = '$_debugLog\n$msg';
    });
    developer.log(msg, name: 'DEBUG');
  }

  void _openMembersPage(BuildContext context) async {
    _log('Opening members page...');
    
    final authState = context.read<AuthenticationBloc>().state;
    _log('Auth state: ${authState.status}');
    
    if (authState.status != AuthenticationStatus.authenticated) {
      _log('Not authenticated');
      return;
    }

    final userId = authState.user.id;
    _log('User ID: $userId');

    final dataSource = OrganizationDataSource();
    final repository = OrganizationRepositoryImpl(dataSource);

    final organization = await repository.getUserOrganization(userId);
    _log('Organization: $organization');

    if (organization == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No perteneces a ninguna organización')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    _log('Navigating to members page...');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => OrganizationMembersBloc(
            repository: repository,
            updateRoleUseCase: UpdateMemberRoleUseCase(repository),
          )..add(LoadOrganizationMembers(organization.id)),
          child: Scaffold(
            appBar: AppBar(title: Text(organization.name)),
            body: OrganizationMembersPage(
              organizationId: organization.id,
              currentUserProfileId: userId,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _log('MapView build');
    
    return BlocBuilder<PositionCubit, LatLng>(
      bloc: context.read<PositionCubit>(),
      builder: (context, position) {
        _log('Position: $position');
        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(target: position, zoom: 15.0),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  compassEnabled: true,
                  tiltGesturesEnabled: true,
                  zoomControlsEnabled: false,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  markers: {
                    Marker(
                      markerId: const MarkerId('current_location'),
                      position: position,
                      infoWindow: const InfoWindow(title: 'Tu ubicación'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                    ),
                  },
                  onMapCreated: (controller) {
                    _log('Map created');
                    _controller.complete(controller);
                    controller.animateCamera(CameraUpdate.newLatLngZoom(position, 15));
                  },
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 80,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.black54,
                    child: Text(
                      'DEBUG: $_debugLog',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'members',
                onPressed: () {
                  _log('FAB members pressed');
                  _openMembersPage(context);
                },
                child: const Icon(Icons.people),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'location',
                onPressed: () {
                  _log('FAB location pressed');
                  context.read<PositionCubit>().updateCurrentPosition();
                },
                child: const Icon(Icons.location_on),
              ),
            ],
          ),
        );
      },
    );
  }
}