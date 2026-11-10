class RouterProfile {
  final String name;
  final String host;
  final int port;
  final String username;
  final String password;
  final bool useTls;

  const RouterProfile({
    required this.name,
    required this.host,
    this.port = 8728,
    required this.username,
    required this.password,
    this.useTls = false,
  });
}
