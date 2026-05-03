import 'package:hookra/features/profile/domain/model/profile.dart';
import 'package:hookra/features/profile/domain/repo/profile_repository.dart';
import 'package:hookra/features/profile/data/sources/profile_data_source.dart';

class ProfileRepositoryImpl extends ProfileRepository {
  final ProfileDataSource _source = ProfileDataSource();

  @override
  Future<void> saveProfile(Profile profile) async {
    await _source.saveProfile(profile.toJson());
  }
}
