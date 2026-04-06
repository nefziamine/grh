import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static User? _currentUser;
  static final List<VoidCallback> _userChangeListeners = [];

  static User? get currentUser => _currentUser;

  static void addUserChangeListener(VoidCallback listener) {
    _userChangeListeners.add(listener);
  }

  static void removeUserChangeListener(VoidCallback listener) {
    _userChangeListeners.remove(listener);
  }

  static void _notifyUserChanged() {
    for (final listener in _userChangeListeners) {
      listener();
    }
  }

  static Future<Map<String, dynamic>> login(String matricule, String password) async {
    final result = await ApiService.post(ApiConfig.login, {
      'matricule': matricule,
      'password': password,
    });

    if (result['success'] == true && result['data'] != null) {
      _currentUser = User.fromJson(result['data']);
      await ApiService.setToken(_currentUser!.token!);
      
      // Save user data locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(result['data']));
      
      _notifyUserChanged();
    }

    return result;
  }

  static Future<bool> isLoggedIn() async {
    final token = await ApiService.getToken();
    if (token == null) return false;

    // Try to load cached user
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      _currentUser = User.fromJson(json.decode(userData));
      return true;
    }

    return false;
  }

  static Future<void> logout() async {
    _currentUser = null;
    await ApiService.clearToken();
    _notifyUserChanged();
  }

  static Future<User?> getProfile() async {
    final result = await ApiService.get(ApiConfig.employeeRead);
    if (result['success'] == true && result['data'] != null) {
      _currentUser = User.fromJson(result['data']);
      _notifyUserChanged();
      return _currentUser;
    }
    return null;
  }
}
