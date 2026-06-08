import 'package:hookra/src/preview/domain/entities/content.dart';
import 'package:hookra/src/preview/domain/repos/content_repository.dart';
import 'package:hookra/src/utils/result.dart';

class GetLatestContentUseCase {
  GetLatestContentUseCase(this._repository);

  final ContentRepository _repository;

  Future<Result<Content?>> call(String teamId) =>
      _repository.getLatestContentForTeam(teamId);
}
