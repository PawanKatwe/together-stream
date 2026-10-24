import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';

class TokenResponse {
  final String token;
  final String url;
  final String room;
  final String identity;

  TokenResponse({
    required this.token,
    required this.url,
    required this.room,
    required this.identity,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      token: json['token'] as String,
      url: json['url'] as String,
      room: json['room'] as String,
      identity: json['identity'] as String,
    );
  }
}

class TokenService {
  static Future<TokenResponse> fetchToken({
    required String identity,
    String? customServerUrl,
  }) async {
    final serverUrl = (customServerUrl ?? AppConfig.tokenServerUrl).replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$serverUrl/token');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'identity': identity,
              'passcode': AppConfig.passcode,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return TokenResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Passcode rejected by token server. Please check your passcode.');
      } else {
        final data = jsonDecode(response.body);
        final errorMsg = data['error'] ?? 'Server error ${response.statusCode}';
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (e.toString().contains('Failed host lookup') || e.toString().contains('SocketException')) {
        throw Exception('Cannot reach token server. Please check your internet connection or server status.');
      }
      rethrow;
    }
  }
}
