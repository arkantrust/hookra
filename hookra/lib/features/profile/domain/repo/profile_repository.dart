import 'package:hookra/features/profile/domain/model/profile.dart';

abstract class ProfileRepository {
  Future<void> saveProfile(Profile profile);
}
