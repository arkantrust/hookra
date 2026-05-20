class OrganizationNotFound implements Exception {
  const OrganizationNotFound();
}

class UnauthorizedOrgAccess implements Exception {
  const UnauthorizedOrgAccess();
}

class OrgAlreadyExists implements Exception {
  const OrgAlreadyExists();
}

class MemberAlreadyExists implements Exception {
  const MemberAlreadyExists();
}

class OrgOperationFailed implements Exception {
  const OrgOperationFailed();
}
