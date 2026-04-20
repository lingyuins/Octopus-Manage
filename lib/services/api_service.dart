import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _keyBaseUrl = 'base_url';
  static const String _keyToken = 'auth_token';

  String _baseUrl = '';
  String _token = '';
  void Function()? onUnauthorized;

  String get baseUrl => _baseUrl;
  String get token => _token;
  bool get isConfigured => _baseUrl.isNotEmpty;
  bool get isLoggedIn => _token.isNotEmpty;

  Future<void> loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_keyBaseUrl) ?? '';
    _token = prefs.getString(_keyToken) ?? '';
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, _baseUrl);
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  Future<void> logout() async {
    _token = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
  }

  Future<void> forceLogout() async {
    await logout();
    onUnauthorized?.call();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
  };

  static const _timeout = Duration(seconds: 15);

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) async {
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final finalUri = query != null ? uri.replace(queryParameters: query) : uri;
      final response = await http
          .get(finalUri, headers: _headers)
          .timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(0, 'Request timed out');
    }
  }

  Future<dynamic> post(String path, {dynamic body, String? contentType}) async {
    try {
      final headers = Map<String, String>.from(_headers);
      if (contentType != null) {
        headers['Content-Type'] = contentType;
      }
      final response = await http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: headers,
            body: contentType == 'application/json' ? body : jsonEncode(body),
          )
          .timeout(_timeout);
      // Handle raw string response for export endpoint
      if (contentType == 'application/json' && body is String) {
        return _handleRawResponse(response);
      }
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(0, 'Request timed out');
    }
  }

  Future<Map<String, dynamic>> put(String path, {dynamic body}) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl$path'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(0, 'Request timed out');
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl$path'), headers: _headers)
          .timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(0, 'Request timed out');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException catch (_) {
      if (response.statusCode == 401) {
        _forceLogoutSync();
        throw ApiException(401, 'Unauthorized');
      }
      if (response.statusCode >= 400) {
        throw ApiException(
          response.statusCode,
          'Request failed (${response.statusCode})',
        );
      }
      throw ApiException(0, 'Invalid response body');
    } on TypeError {
      if (response.statusCode == 401) {
        _forceLogoutSync();
        throw ApiException(401, 'Unauthorized');
      }
      throw ApiException(0, 'Invalid response format');
    }
    if (response.statusCode == 401) {
      _forceLogoutSync();
      throw ApiException(401, json['message'] as String? ?? 'Unauthorized');
    }
    if (response.statusCode >= 400) {
      throw ApiException(
        response.statusCode,
        json['message'] as String? ?? 'Request failed',
      );
    }
    return json;
  }

  dynamic _handleRawResponse(http.Response response) {
    if (response.statusCode >= 400) {
      throw ApiException(
        response.statusCode,
        'Request failed (${response.statusCode})',
      );
    }
    return response.body;
  }

  /// Synchronous logout + notification for use inside synchronous
  /// [_handleResponse] where we cannot await [forceLogout].
  void _forceLogoutSync() {
    _token = '';
    SharedPreferences.getInstance().then(
      (prefs) => prefs.remove(_keyToken),
      onError: (_) {},
    );
    onUnauthorized?.call();
  }
}

class ApiException implements Exception {
  final int code;
  final String message;
  ApiException(this.code, this.message);
  @override
  String toString() => 'ApiException($code): $message';
}
