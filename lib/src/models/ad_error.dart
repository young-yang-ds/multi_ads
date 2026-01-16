class AdError {
  final int code;
  final String message;
  final String? platform;

  AdError({required this.code, required this.message, this.platform});

  factory AdError.fromPangle(dynamic error) {
    if (error is Map) {
      return AdError(
        code: error['code'] ?? -1,
        message: error['message'] ?? 'Unknown error',
        platform: 'pangle',
      );
    }
    return AdError(
      code: -1,
      message: error?.toString() ?? 'Unknown error',
      platform: 'pangle',
    );
  }

  factory AdError.fromVungle(dynamic error) {
    if (error is Map) {
      return AdError(
        code: error['code'] ?? -1,
        message: error['message'] ?? 'Unknown error',
        platform: 'vungle',
      );
    }
    return AdError(
      code: -1,
      message: error?.toString() ?? 'Unknown error',
      platform: 'vungle',
    );
  }

  factory AdError.fromGoogle(String? message) {
    return AdError(
      code: -1,
      message: message ?? 'Unknown error',
      platform: 'google',
    );
  }

  @override
  String toString() =>
      'AdError(code: $code, message: $message, platform: $platform)';
}
