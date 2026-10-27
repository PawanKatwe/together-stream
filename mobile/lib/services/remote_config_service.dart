import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config.dart';

class RemoteConfigService {
  static const List<String> defaultEmojis = ['❤️', '😊', '😂', '🥺', '🔥', '👏'];
  static const List<String> defaultQuickPhrases = [
    'I love you ❤️',
    'Look at that! 😂',
    'So romantic 🥺',
    'Wait, what happened? 🍿',
    'Hold my hand 💕',
    'BRB, 1 sec! 🥤',
  ];

  static List<String> emojis = List.from(defaultEmojis);
  static List<String> quickPhrases = List.from(defaultQuickPhrases);

  static const String _prefKeyEmojis = 'cached_remote_emojis';
  static const String _prefKeyPhrases = 'cached_remote_phrases';

  // Load cached config on startup
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedEmojisJson = prefs.getString(_prefKeyEmojis);
      if (cachedEmojisJson != null) {
        final list = (jsonDecode(cachedEmojisJson) as List<dynamic>).map((e) => e.toString()).toList();
        if (list.isNotEmpty) emojis = list;
      }

      final cachedPhrasesJson = prefs.getString(_prefKeyPhrases);
      if (cachedPhrasesJson != null) {
        final list = (jsonDecode(cachedPhrasesJson) as List<dynamic>).map((e) => e.toString()).toList();
        if (list.isNotEmpty) quickPhrases = list;
      }
    } catch (e) {
      debugPrint('Error loading cached remote config: $e');
    }

    // Fetch latest in background
    fetchRemoteConfig();
  }

  // Fetch dynamically from Render Cloud Server
  static Future<void> fetchRemoteConfig({String? customServerUrl}) async {
    try {
      final serverUrl = customServerUrl ?? AppConfig.tokenServerUrl;
      final uri = Uri.parse('$serverUrl/config');

      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final serverEmojis = data['emojis'] as List<dynamic>?;
          if (serverEmojis != null && serverEmojis.isNotEmpty) {
            emojis = serverEmojis.map((e) => e.toString()).toList();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_prefKeyEmojis, jsonEncode(emojis));
          }

          final serverPhrases = data['quickPhrases'] as List<dynamic>?;
          if (serverPhrases != null && serverPhrases.isNotEmpty) {
            quickPhrases = serverPhrases.map((e) => e.toString()).toList();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_prefKeyPhrases, jsonEncode(quickPhrases));
          }
          debugPrint('Remote config updated: ${emojis.length} emojis, ${quickPhrases.length} phrases');
        }
      }
    } catch (e) {
      debugPrint('Could not fetch remote config (offline fallback active): $e');
    }
  }
}
