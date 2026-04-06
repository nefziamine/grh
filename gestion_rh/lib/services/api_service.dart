import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String? _token;

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await clearCache();
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_')).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> get(String url, {Map<String, String>? params, bool forceRefresh = false}) async {
    try {
      var uri = Uri.parse(url);
      if (params != null) {
        uri = uri.replace(queryParameters: params);
      }

      final prefs = await SharedPreferences.getInstance();
      final token = await getToken();
      final cacheKey = 'cache_${token ?? "guest"}_${uri.toString()}';

      // 1. Return cached data immediately if available (Stale-While-Revalidate pattern)
      if (!forceRefresh) {
        final cachedData = prefs.getString(cacheKey);
        if (cachedData != null) {
          _backgroundFetchAndUpdate(uri, cacheKey); // Silently update cache
          return json.decode(cachedData);
        }
      }

      // 2. Otherwise fetch from network
      final response = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 15));

      final result = _handleResponse(response);
      // Only cache successful requests
      if (result['success'] == true) {
        await prefs.setString(cacheKey, json.encode(result));
      }
      return result;
    } on TimeoutException {
      return {'success': false, 'message': 'Le réseau est lent. Impossible de mettre à jour les données actuelles.'};
    } on SocketException {
      return {'success': false, 'message': 'Pas de connexion Internet. Affichage des données hors ligne.'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion inattendue'};
    }
  }

  static Future<void> _backgroundFetchAndUpdate(Uri uri, String cacheKey) async {
    try {
      final response = await http.get(uri, headers: await _headers()).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(cacheKey, response.body);
        }
      }
    } catch (_) {
      // Ignore background errors
    }
  }

  static Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: await _headers(),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Le serveur ne répond pas (délai dépassé). Vérifiez votre connexion ou réessayez plus tard.'
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Impossible de se connecter au serveur. Assurez-vous que vous êtes sur le même réseau que le serveur.'
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion inattendue: $e'};
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Erreur de traitement de la réponse'};
    }
  }
}
