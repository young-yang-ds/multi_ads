class PangleAdError {
  final int code;
  final String message;

  PangleAdError({
    required this.code,
    required this.message,
  });

  factory PangleAdError.fromJson(Map<String, dynamic> json) {
    return PangleAdError(
      code: json['code'] as int,
      message: json['message'] as String,
    );
  }

  @override
  String toString() => 'PangleAdError(code: $code, message: $message)';
}
