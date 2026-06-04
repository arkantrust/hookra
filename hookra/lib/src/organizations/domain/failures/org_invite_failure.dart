sealed class OrgInviteFailure implements Exception {
  const OrgInviteFailure();
}

class UserNotFound extends OrgInviteFailure {
  const UserNotFound();
}

class AlreadyMember extends OrgInviteFailure {
  const AlreadyMember();
}

class InviteNotFound extends OrgInviteFailure {
  const InviteNotFound();
}

class InviteExpired extends OrgInviteFailure {
  const InviteExpired();
}

class NotInvitedUser extends OrgInviteFailure {
  const NotInvitedUser();
}
