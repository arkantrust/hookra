import 'package:hookra/src/preview/domain/entities/content.dart';
import 'package:hookra/src/utils/result.dart';

abstract base class ContentRepository {
  /// Latest content for the active team's project, or `null` when none exists.
  Future<Result<Content?>> getLatestContentForTeam(String teamId);

  void dispose();
}
