part of 'location_permission_bloc.dart';

sealed class LocationPermissionEvent extends Equatable {
  const LocationPermissionEvent();

  @override
  List<Object> get props => [];
}

class LocationPermissionCheckRequested extends LocationPermissionEvent {
  const LocationPermissionCheckRequested();
}

class LocationPermissionRequestRequested extends LocationPermissionEvent {
  const LocationPermissionRequestRequested();
}

class LocationPermissionRetryRequested extends LocationPermissionEvent {
  const LocationPermissionRetryRequested();
}
