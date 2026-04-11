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

  Future<Map<String, dynamic>> get(String path) async {
    final response = await http
        .get(Uri.parse('$_baseUrl$path'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String path, {dynamic body}) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(String path, {dynamic body}) async {
    final response = await http
        .put(
          Uri.parse('$_baseUrl$path'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await http
        .delete(Uri.parse('$_baseUrl$path'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      if (response.statusCode == 401) {
        if (_token.isNotEmpty) forceLogout();
        throw ApiException(401, 'Unauthorized');
      }
      if (response.statusCode >= 400) {
        throw ApiException(
          response.statusCode,
          'Request failed (${response.statusCode})',
        );
      }
      throw ApiException(0, 'Invalid response body');
    }
    if (response.statusCode == 401) {
      if (_token.isNotEmpty) forceLogout();
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
}

class ApiException implements Exception {
  final int code;
  final String message;
  ApiException(this.code, this.message);
  @override
  String toString() => 'ApiException($code): $message';
}
