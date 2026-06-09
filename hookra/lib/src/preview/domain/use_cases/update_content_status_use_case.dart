import 'package:hookra/src/preview/domain/entities/content.dart';
import 'package:hookra/src/preview/domain/repos/content_repository.dart';
import 'package:hookra/src/utils/result.dart';

class UpdateContentStatusUseCase {
  final ContentRepository _repository;

  UpdateContentStatusUseCase(this._repository);

  Future<Result<void>> call({
    required String contentId,
    required ContentStatus status,
  }) async {
    return await _repository.updateContentStatus(
      contentId: contentId,
      status: status,
    );
  }
}