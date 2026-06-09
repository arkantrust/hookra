part of 'preview_bloc.dart';

sealed class PreviewEvent extends Equatable {
  const PreviewEvent();

  @override
  List<Object?> get props => [];
}

final class PreviewRequested extends PreviewEvent {
  const PreviewRequested(this.teamId);
  final String teamId;

  @override
  List<Object?> get props => [teamId];
}

final class ApproveContent extends PreviewEvent {
  const ApproveContent(this.contentId);
  final String contentId;

  @override
  List<Object?> get props => [contentId];
}
