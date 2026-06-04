import 'dart:async';

import 'package:hookra/src/profile/domain/entities/user.dart';
import 'package:hookra/src/utils/result.dart';

abstract base class UserRepository {
  Future<Result<User>> getUser();

  Future<Result<User>> updateUser({
    required String firstName,
    required String lastName,
  });

  void dispose();
}
