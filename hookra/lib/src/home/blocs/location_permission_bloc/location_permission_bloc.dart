import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:permission_handler/permission_handler.dart';

part 'location_permission_event.dart';
part 'location_permission_state.dart';

class LocationPermissionBloc extends Bloc<LocationPermissionEvent, LocationPermissionState> {
  LocationPermissionBloc() : super(const LocationPermissionState()) {
    on<LocationPermissionCheckRequested>(_onPermissionCheckRequested);
    on<LocationPermissionRequestRequested>(_onPermissionRequestRequested);
    on<LocationPermissionRetryRequested>(_onPermissionRetryRequested);
  }

  Future<void> _onPermissionCheckRequested(
    LocationPermissionCheckRequested event,
    Emitter<LocationPermissionState> emit,
  ) async {
    emit(state.copyWith(status: LocationPermissionStatus.checking));
    await _checkLocationPermission(emit);
  }

  Future<void> _onPermissionRequestRequested(
    LocationPermissionRequestRequested event,
    Emitter<LocationPermissionState> emit,
  ) async {
    emit(state.copyWith(status: LocationPermissionStatus.checking));
    await _requestLocationPermission(emit);
  }

  Future<void> _onPermissionRetryRequested(
    LocationPermissionRetryRequested event,
    Emitter<LocationPermissionState> emit,
  ) async {
    emit(state.copyWith(status: LocationPermissionStatus.checking));
    await _checkLocationPermission(emit);
  }

  Future<void> _checkLocationPermission(Emitter<LocationPermissionState> emit) async {
    try {
      // Check if location services are enabled first
      bool serviceEnabled = await Permission.locationWhenInUse.serviceStatus.isEnabled;
      if (!serviceEnabled) {
        log('Location service is disabled.');
        emit(
          state.copyWith(
            status: LocationPermissionStatus.serviceDisabled,
            message: 'Los servicios de ubicación están deshabilitados.',
          ),
        );
        return;
      }

      // Check current permission status
      final permissionStatus = await Permission.locationWhenInUse.status;

      if (permissionStatus.isGranted) {
        log('Location permission is already granted.');
        emit(state.copyWith(status: LocationPermissionStatus.granted));
      } else if (permissionStatus.isPermanentlyDenied) {
        log('Location permission is permanently denied.');
        emit(
          state.copyWith(
            status: LocationPermissionStatus.permanentlyDenied,
            message: 'El permiso de ubicación ha sido denegado permanentemente.',
          ),
        );
      } else {
        log('Location permission is denied or not determined.');
        emit(state.copyWith(status: LocationPermissionStatus.denied));
      }
    } catch (e) {
      log('Error checking location permission: $e');
      emit(
        state.copyWith(
          status: LocationPermissionStatus.denied,
          message: 'Error al verificar permisos de ubicación.',
        ),
      );
    }
  }

  Future<void> _requestLocationPermission(Emitter<LocationPermissionState> emit) async {
    try {
      final status = await Permission.locationWhenInUse.request();

      if (status.isGranted) {
        log('Location permission granted after request.');
        emit(state.copyWith(status: LocationPermissionStatus.granted));
      } else if (status.isPermanentlyDenied) {
        log('Location permission permanently denied after request.');
        emit(
          state.copyWith(
            status: LocationPermissionStatus.permanentlyDenied,
            message: 'El permiso ha sido denegado permanentemente.',
          ),
        );
      } else {
        log('Location permission denied after request.');
        emit(
          state.copyWith(
            status: LocationPermissionStatus.denied,
            message: 'Permiso de ubicación denegado.',
          ),
        );
      }
    } catch (e) {
      log('Error requesting location permission: $e');
      emit(
        state.copyWith(
          status: LocationPermissionStatus.denied,
          message: 'Error al solicitar permisos de ubicación.',
        ),
      );
    }
  }
}
