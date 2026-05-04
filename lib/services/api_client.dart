import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.errors});

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required String baseUrl, http.Client? httpClient})
    : _baseUri = Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/'),
      _httpClient = httpClient ?? http.Client();

  final Uri _baseUri;
  final http.Client _httpClient;
  String? _bearerToken;

  set bearerToken(String? value) => _bearerToken = value;

  Future<Map<String, dynamic>> getJson(String path) {
    return _sendJson('GET', path);
  }

  Future<Map<String, dynamic>> deleteJson(String path) {
    return _sendJson('DELETE', path);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _sendJson('POST', path, body: body);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _sendJson('PUT', path, body: body);
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _sendJson('PATCH', path, body: body);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            _baseUri.resolve('./${path.replaceFirst(RegExp(r'^/+'), '')}'),
          )
          ..headers.addAll({
            'Accept': 'application/json',
            if (_bearerToken != null) 'Authorization': 'Bearer $_bearerToken',
          })
          ..fields.addAll(fields)
          ..files.addAll(files);

    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
    }

    final payload = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};
    throw ApiException(
      _firstLaravelError(payload) ??
          payload['message'] as String? ??
          'Nie udalo sie polaczyc. Sprobuj ponownie.',
      statusCode: response.statusCode,
      errors: payload['errors'] is Map<String, dynamic>
          ? payload['errors'] as Map<String, dynamic>
          : null,
    );
  }

  Future<Map<String, dynamic>> _sendJson(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final request =
        http.Request(
            method,
            _baseUri.resolve('./${path.replaceFirst(RegExp(r'^/+'), '')}'),
          )
          ..headers.addAll({
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (_bearerToken != null) 'Authorization': 'Bearer $_bearerToken',
          });

    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
    }

    final payload = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};
    throw ApiException(
      _firstLaravelError(payload) ??
          payload['message'] as String? ??
          'Nie udalo sie polaczyc. Sprobuj ponownie.',
      statusCode: response.statusCode,
      errors: payload['errors'] is Map<String, dynamic>
          ? payload['errors'] as Map<String, dynamic>
          : null,
    );
  }

  static String? _firstLaravelError(Map<String, dynamic> payload) {
    final errors = payload['errors'];
    if (errors is! Map) return null;
    for (final value in errors.values) {
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }
    }
    return null;
  }
}
