part of 'preview_bloc.dart';

sealed class PreviewState extends Equatable {
  const PreviewState();

  @override
  List<Object?> get props => [];
}

final class PreviewInitial extends PreviewState {
  const PreviewInitial();
}

final class PreviewLoading extends PreviewState {
  const PreviewLoading();
}

/// Loaded successfully. [content] is null when the team has no content yet.
final class PreviewLoaded extends PreviewState {
  const PreviewLoaded(this.content);
  final Content? content;

  @override
  List<Object?> get props => [content];
}

final class PreviewError extends PreviewState {
  const PreviewError(this.failure);
  final Exception failure;

  @override
  List<Object?> get props => [failure];
}
