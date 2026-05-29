class CredentialsEntity {
  final String accessToken;
  final String refreshToken;

  const CredentialsEntity({
    required this.accessToken,
    required this.refreshToken,
  });
}
