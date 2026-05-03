import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final LocationSettings locationSettings = LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 100,
);

class PositionCubit extends Cubit<LatLng> {
  PositionCubit() : super(const LatLng(3.340874198746151, -76.53011712989412)) {
    updateCurrentPosition();
  }

  Future<void> updateCurrentPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
      emit(LatLng(position.latitude, position.longitude));
    } catch (e) {
      log('Error getting current position: $e', name: 'PositionCubit');
    }
  }
}
