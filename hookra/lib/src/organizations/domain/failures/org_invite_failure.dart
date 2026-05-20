sealed class OrgInviteFailure implements Exception {
  const OrgInviteFailure();
}

final class InviteNotFound extends OrgInviteFailure {
  const InviteNotFound();
}

final class InviteExpired extends OrgInviteFailure {
  const InviteExpired();
}

final class InviteAlreadyAccepted extends OrgInviteFailure {
  const InviteAlreadyAccepted();
}

final class InviteEmailMismatch extends OrgInviteFailure {
  const InviteEmailMismatch();
}
