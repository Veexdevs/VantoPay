import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';

/// Low-level JSON client for the VantoPay REST API.
///
/// Attaches the Supabase access token as a Bearer credential and normalizes
/// errors. The backend never trusts client-supplied balances, so this client
/// only sends operation parameters and reads server-derived values.
class ApiClient {
  ApiClient._();

  static String? _token;

  static void setToken(String? token) => _token = token;

  static Uri _uri(String path, [Map<String, String>? query]) {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    final uri = Uri.parse('$base$path');
    if (query == null || query.isEmpty) return uri;
    final qs = query
        .map((k, v) =>
            '${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(v.toString())}')
        .join('&');
    return uri.replace(query: qs);
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null && _token!.isNotEmpty)
          'Authorization': 'Bearer $_token',
      };

  static Future<Map<String, dynamic>> get(
    String path, [Map<String, String>? query]) async {
    final res = await http.get(_uri(path, query), headers: _headers);
    return _decodeObject(res);
  }

  static Future<List<Map<String, dynamic>>> getList(
    String path, [Map<String, String>? query]) async {
    final res = await http.get(_uri(path, query), headers: _headers);
    return _decodeList(res);
  }

  static Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body,
      [Map<String, String>? query]) async {
    final res = await http.post(_uri(path, query),
        headers: _headers, body: jsonEncode(body));
    return _decodeObject(res);
  }

  static Future<Map<String, dynamic>> patch(String path,
      Map<String, dynamic> body) async {
    final res = await http.patch(_uri(path),
        headers: _headers, body: jsonEncode(body));
    return _decodeObject(res);
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final res = await http.delete(_uri(path), headers: _headers);
    return _decodeObject(res);
  }

  static Map<String, dynamic> _decodeObject(http.Response res) {
    final status = res.statusCode;
    Map<String, dynamic> data = {};
    try {
      final parsed = res.body.isEmpty ? null : jsonDecode(res.body);
      if (parsed is Map) data = parsed.cast<String, dynamic>();
    } catch (_) {
      // ignore malformed bodies
    }
    if (status >= 200 && status < 300) return data;
    throw ApiException(statusCode: status, message: _errorMessage(data, res));
  }

  static List<Map<String, dynamic>> _decodeList(http.Response res) {
    final status = res.statusCode;
    final result = <Map<String, dynamic>>[];
    List<dynamic> items = [];
    try {
      final parsed = res.body.isEmpty ? null : jsonDecode(res.body);
      if (parsed is List) items = parsed;
    } catch (_) {
      // ignore malformed bodies
    }
    if (status >= 200 && status < 300) {
      for (final item in items) {
        if (item is Map) result.add(item.cast<String, dynamic>());
      }
      return result;
    }
    Map<String, dynamic> data = {};
    try {
      final parsed = jsonDecode(res.body);
      if (parsed is Map) data = parsed.cast<String, dynamic>();
    } catch (_) {
      // ignore
    }
    throw ApiException(statusCode: status, message: _errorMessage(data, res));
  }

  static String _errorMessage(Map<String, dynamic> data, http.Response res) {
    final detail = data['detail'];
    if (detail is String) return detail;
    if (detail != null) return detail.toString();
    return 'Erro de comunicação (${res.statusCode}).';
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
