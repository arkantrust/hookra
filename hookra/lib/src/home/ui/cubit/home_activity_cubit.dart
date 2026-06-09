import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hookra/src/preview/domain/entities/comment.dart';
import 'package:hookra/src/preview/domain/use_cases/get_team_comments_use_case.dart';

sealed class HomeActivityState extends Equatable {
  const HomeActivityState();
}

final class HomeActivityLoading extends HomeActivityState {
  const HomeActivityLoading();
  @override
  List<Object?> get props => [];
}

final class HomeActivityReady extends HomeActivityState {
  const HomeActivityReady(this.comments);
  final List<Comment> comments;
  @override
  List<Object?> get props => [comments];
}

final class HomeActivityFailure extends HomeActivityState {
  const HomeActivityFailure();
  @override
  List<Object?> get props => [];
}

class HomeActivityCubit extends Cubit<HomeActivityState> {
  HomeActivityCubit(this._getTeamComments) : super(const HomeActivityLoading());

  final GetTeamCommentsUseCase _getTeamComments;

  Future<void> load(String teamId) async {
    emit(const HomeActivityLoading());
    final result = await _getTeamComments(teamId);
    if (result.isSuccess) {
      emit(HomeActivityReady(result.value));
    } else {
      emit(const HomeActivityFailure());
    }
  }
}
