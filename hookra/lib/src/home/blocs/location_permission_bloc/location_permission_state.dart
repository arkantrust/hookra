part of 'location_permission_bloc.dart';

enum LocationPermissionStatus {
  unknown,
  checking,
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

class LocationPermissionState extends Equatable {
  const LocationPermissionState({this.status = LocationPermissionStatus.unknown, this.message});

  final LocationPermissionStatus status;
  final String? message;

  LocationPermissionState copyWith({LocationPermissionStatus? status, String? message}) {
    return LocationPermissionState(status: status ?? this.status, message: message ?? this.message);
  }

  @override
  List<Object?> get props => [status, message];
}
