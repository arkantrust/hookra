enum OrgRole {
  member('member'),
  admin('admin'),
  owner('owner');

  final String value;
  const OrgRole(this.value);

  static OrgRole fromString(String value) {
    return OrgRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OrgRole.member,
    );
  }
}