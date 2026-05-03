export 'supabase_user_repository.dart';
export 'user_failure.dart';
import 'dart:async';

import 'package:hookra/src/models/user.dart';
import 'package:hookra/src/utils/result.dart';

abstract base class UserRepository {
  Future<Result<User>> getUser();

  void dispose();
}
