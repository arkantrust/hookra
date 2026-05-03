import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:hookra/src/config/service_locator.dart';
import 'package:hookra/src/home/home.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static GoRoute route() {
    return GoRoute(path: '/', builder: (context, state) => const HomePage());
  }

  @override
  Widget build(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<PositionCubit, LatLng>(
      listener: (context, position) async {
        final controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLngZoom(position, 15));
      },
      child: BlocBuilder<PositionCubit, LatLng>(
        bloc: context.read<PositionCubit>(),
        builder: (context, position) {
          final markers = {
            Marker(
              markerId: MarkerId('current_location'),
              position: position,
              infoWindow: const InfoWindow(title: 'Tu ubicación'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            ),
          };

          return Scaffold(
            body: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(target: position, zoom: 15.0),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              tiltGesturesEnabled: true,
              zoomControlsEnabled: false,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              markers: markers,
              onMapCreated: (controller) => {_controller.complete(controller)},
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => context.read<PositionCubit>().updateCurrentPosition(),
              child: const Icon(Icons.location_on),
            ),
          );
        },
      ),
    );
  }
}
