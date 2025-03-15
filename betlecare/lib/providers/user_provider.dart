import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../supabase_client.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _userSettings;

  static const String _userKey = 'user';
  static const String _userDataKey = 'userData';
  static const String _userSettingsKey = 'userSettings';

  UserProvider() {
    _loadUserFromStorage();
  }

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  Map<String, dynamic>? get userSettings => _userSettings;

  Future<void> _loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    final userDataJson = prefs.getString(_userDataKey);
    final settingsJson = prefs.getString(_userSettingsKey);

    if (userJson != null) {
      _user = User.fromJson(json.decode(userJson));
    }

    if (userDataJson != null) {
      _userData = json.decode(userDataJson);
    }

    if (settingsJson != null) {
      _userSettings = json.decode(settingsJson);
    }

    notifyListeners();
  }

  Future<void> _saveUserToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (_user != null) {
      await prefs.setString(_userKey, json.encode(_user!.toJson()));
    } else {
      await prefs.remove(_userKey);
    }

    if (_userData != null) {
      await prefs.setString(_userDataKey, json.encode(_userData));
    } else {
      await prefs.remove(_userDataKey);
    }

    if (_userSettings != null) {
      await prefs.setString(_userSettingsKey, json.encode(_userSettings));
    } else {
      await prefs.remove(_userSettingsKey);
    }
  }

  Future<void> initializeUser() async {
    final supabase = await SupabaseClientManager.instance;
    final currentUser = supabase.client.auth.currentUser;
    if (currentUser != null) {
      setUser(currentUser);
      await fetchUserSettings();
    }
  }

  Future<void> fetchUserSettings() async {
    if (_user == null) return;

    final supabase = await SupabaseClientManager.instance;
    try {
      final response = await supabase.client
          .from('user_settings')
          .select()
          .eq('userid', _user!.id)
          .single();

      setUserSettings(response);
    } catch (e) {
      print('Error fetching user settings: $e');
    }
  }

  void setUserSettings(Map<String, dynamic>? settings) {
    _userSettings = settings;
    _saveUserToStorage();
    notifyListeners();
  }

  void setUser(User? user) {
    _user = user;
    _saveUserToStorage();
    notifyListeners();
  }

  void setUserData(Map<String, dynamic>? userData) {
    _userData = userData;
    _saveUserToStorage();
    notifyListeners();
  }

  Future<void> clearUser() async {
    _user = null;
    _userSettings = null;
    await _saveUserToStorage();
    notifyListeners();
  }
}
