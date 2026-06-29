/// Роли пользователя на backend (client/master/admin). Админка через mobile
/// не доступна, но enum держим полным, чтобы не падать на `firstWhere`.
enum UserRole {
  client('client'),
  master('master'),
  admin('admin'),
  unknown('unknown');

  const UserRole(this.value);
  final String value;

  static UserRole fromValue(String? raw) {
    if (raw == null) return UserRole.unknown;
    for (final r in UserRole.values) {
      if (r.value == raw) return r;
    }
    return UserRole.unknown;
  }

  bool get isClient => this == UserRole.client;
  bool get isMaster => this == UserRole.master;
}
