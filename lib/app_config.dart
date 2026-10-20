class AppConfig {
  static const demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: true);

  static Uri purchaseVerificationUrl() => _endpoint(
        const String.fromEnvironment('PURCHASE_VERIFICATION_URL'),
        'PURCHASE_VERIFICATION_URL',
      );

  static Uri reviewerVerificationUrl() => _endpoint(
        const String.fromEnvironment('REVIEWER_VERIFICATION_URL'),
        'REVIEWER_VERIFICATION_URL',
      );

  static Uri _endpoint(String value, String name) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw StateError('$name must be configured with an HTTPS URL.');
    }
    return uri;
  }
}
