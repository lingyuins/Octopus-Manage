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

  static String normalizeBaseUrl(String url) {
    return url.trim().replaceAll(RegExp(r'/+$'), '');
  }

  static bool isValidBaseUrl(String url) {
    final normalized = normalizeBaseUrl(url);
    if (normalized.isEmpty) return false;
    final uri = Uri.tryParse(normalized);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Future<void> loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = normalizeBaseUrl(prefs.getString(_keyBaseUrl) ?? '');
    _token = prefs.getString(_keyToken) ?? '';
  }

  Future<void> setBaseUrl(String url) async {
    final normalizedUrl = normalizeBaseUrl(url);
    final prefs = await SharedPreferences.getInstance();
    final shouldClearToken =
        normalizedUrl.isEmpty ||
        (_baseUrl.isNotEmpty && _baseUrl != normalizedUrl);

    _baseUrl = normalizedUrl;
    await prefs.setString(_keyBaseUrl, _baseUrl);

    if (shouldClearToken && _token.isNotEmpty) {
      _token = '';
      await prefs.remove(_keyToken);
    }
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

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    try {
      final finalUri = _buildUri(path, query: query);
      final response = await http
          .get(finalUri, headers: _headers)
          .timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(0, 'Request timed out');
    } on http.ClientException catch (e) {
      throw ApiException(0, 'Network request failed: ${e.message}');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Network request failed');
    }
  }

  Future<dynamic> post(String path, {dynamic body, String? contentType}) async {
    try {
      final headers = Map<String, String>.from(_headers);
      if (contentType != null) {
        headers['Content-Type'] = contentType;
      }
      final encodedBody = body is String ? body : jsonEncode(body);
      final response = await http
          .post(_buildUri(path), headers: headers, body: encodedBody)
          .timeout(_timeout);
      // Handle raw string response for JSON import/export endpoints.
      if (contentType == 'application/json' && body is String) {
        return _handleRawResponse(response);
      }
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(0, 'Request timed out');
    } on http.ClientException catch (e) {
      throw ApiException(0, 'Network request failed: ${e.message}');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Network request failed');
    }
  }

  Future<Map<String, dynamic>> put(String path, {dynamic body}) async {
    try {
      final response = await http
          .put(_buildUri(path), headers: _headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(0, 'Request timed out');
    } on http.ClientException catch (e) {
      throw ApiException(0, 'Network request failed: ${e.message}');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Network request failed');
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? query,
  }) async {
    try {
      final finalUri = _buildUri(path, query: query);
      final response = await http
          .delete(finalUri, headers: _headers)
          .timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(0, 'Request timed out');
    } on http.ClientException catch (e) {
      throw ApiException(0, 'Network request failed: ${e.message}');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Network request failed');
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
      throw ApiException(
        401,
        _extractErrorMessage(response.body, fallback: 'Unauthorized'),
      );
    }
    if (response.statusCode >= 400) {
      throw ApiException(
        response.statusCode,
        _extractErrorMessage(
          response.body,
          fallback: json['message']?.toString() ?? 'Request failed',
        ),
      );
    }
    return json;
  }

  dynamic _handleRawResponse(http.Response response) {
    if (response.statusCode == 401) {
      _forceLogoutSync();
      throw ApiException(
        401,
        _extractErrorMessage(response.body, fallback: 'Unauthorized'),
      );
    }
    if (response.statusCode >= 400) {
      throw ApiException(
        response.statusCode,
        _extractErrorMessage(
          response.body,
          fallback: 'Request failed (${response.statusCode})',
        ),
      );
    }
    return response.body;
  }

  Uri _buildUri(String path, {Map<String, String>? query}) {
    if (_baseUrl.isEmpty) {
      throw ApiException(0, 'Server URL is not configured');
    }

    final resolvedPath = path.startsWith('/') ? path : '/$path';
    final baseUri = Uri.parse(_baseUrl);
    final uri = baseUri.resolveUri(Uri.parse(resolvedPath));
    final mergedQuery = <String, String>{
      ...uri.queryParameters,
      if (query != null) ...query,
    };
    return mergedQuery.isEmpty
        ? uri
        : uri.replace(queryParameters: mergedQuery);
  }

  String _extractErrorMessage(String body, {required String fallback}) {
    if (body.trim().isEmpty) return fallback;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {}
    return fallback;
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
  String toString() => message;
}
