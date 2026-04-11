class ApiResponse {
  final int code;
  final String message;
  final dynamic data;

  ApiResponse({required this.code, required this.message, this.data});

  bool get isSuccess => code == 200;

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      code: json['code'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      data: json['data'],
    );
  }
}
