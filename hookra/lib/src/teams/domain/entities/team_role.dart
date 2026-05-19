enum TeamRole { manager, editor }

extension TeamRoleX on TeamRole {
  String toJson() => switch (this) {
    TeamRole.manager => 'manager',
    TeamRole.editor => 'editor',
  };
}

TeamRole teamRoleFromJson(String? value) => switch (value) {
  'manager' => TeamRole.manager,
  _ => TeamRole.editor,
};
