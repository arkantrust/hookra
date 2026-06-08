import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hookra/src/preview/domain/entities/content.dart';
import 'package:hookra/src/preview/domain/failures/preview_failure.dart';
import 'package:hookra/src/preview/domain/use_cases/get_latest_content_use_case.dart';

part 'preview_event.dart';
part 'preview_state.dart';

class PreviewBloc extends Bloc<PreviewEvent, PreviewState> {
  PreviewBloc({required GetLatestContentUseCase getLatestContent})
    : _getLatestContent = getLatestContent,
      super(const PreviewInitial()) {
    on<PreviewRequested>(_onRequested);
  }

  final GetLatestContentUseCase _getLatestContent;

  Future<void> _onRequested(
    PreviewRequested event,
    Emitter<PreviewState> emit,
  ) async {
    emit(const PreviewLoading());
    final result = await _getLatestContent(event.teamId);
    if (result.isFailure) {
      emit(const PreviewError(LoadContentFailed()));
      return;
    }
    // `valueOrNull` is null both for a real null value (no content) and is the
    // intended "empty" signal here. Result.success(null) is neither isSuccess
    // nor isFailure, so we branch on isFailure above and treat the rest as data.
    emit(PreviewLoaded(result.valueOrNull));
  }
}
