import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hookra/src/preview/domain/entities/content.dart';
import 'package:hookra/src/preview/domain/failures/preview_failure.dart';
import 'package:hookra/src/preview/domain/use_cases/get_latest_content_use_case.dart';
import 'package:hookra/src/preview/domain/use_cases/update_content_status_use_case.dart';

part 'preview_event.dart';
part 'preview_state.dart';

class PreviewBloc extends Bloc<PreviewEvent, PreviewState> {
  PreviewBloc({
    required GetLatestContentUseCase getLatestContent,
    required UpdateContentStatusUseCase updateContentStatus,
  }) : _getLatestContent = getLatestContent,
       _updateContentStatus = updateContentStatus,
       super(const PreviewInitial()) {
    on<PreviewRequested>(_onRequested);
    on<ApproveContent>(_onApproveContent);
  }

  final GetLatestContentUseCase _getLatestContent;
  final UpdateContentStatusUseCase _updateContentStatus;
  String? _currentTeamId;

  Future<void> _onRequested(
    PreviewRequested event,
    Emitter<PreviewState> emit,
  ) async {
    _currentTeamId = event.teamId;
    emit(const PreviewLoading());
    final result = await _getLatestContent(event.teamId);
    if (result.isFailure) {
      emit(const PreviewError(LoadContentFailed()));
      return;
    }
    emit(PreviewLoaded(result.valueOrNull));
  }

  Future<void> _onApproveContent(
    ApproveContent event,
    Emitter<PreviewState> emit,
  ) async {
    final teamId = _currentTeamId;
    if (teamId == null) return;

    final result = await _updateContentStatus(
      contentId: event.contentId,
      status: ContentStatus.approved,
    );

    if (result.isSuccess) {
      emit(const ContentApproved());
      add(PreviewRequested(teamId));
    } else {
      emit(PreviewError(result.error));
    }
  }
}
