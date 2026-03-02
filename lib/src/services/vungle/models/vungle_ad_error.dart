/// Error class for Vungle Ads
class VungleAdError {
  final int code;
  final String message;

  VungleAdError({required this.code, required this.message});

  factory VungleAdError.fromJson(Map<String, dynamic> json) {
    return VungleAdError(
      code: json['code'] as int? ?? -1,
      message: json['message'] as String? ?? 'Unknown error',
    );
  }

  @override
  String toString() => 'VungleAdError(code: $code, message: $message)';
}
