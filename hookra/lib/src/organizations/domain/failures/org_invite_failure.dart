sealed class OrgInviteFailure implements Exception {
  const OrgInviteFailure();
}

class UserNotFound extends OrgInviteFailure {
  const UserNotFound();
}

class AlreadyMember extends OrgInviteFailure {
  const AlreadyMember();
}
