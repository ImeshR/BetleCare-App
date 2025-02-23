import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../supabase_client.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  Map<String, dynamic>? _userData;

  static const String _userKey = 'user';
  static const String _userDataKey = 'userData';

  UserProvider() {
    _loadUserFromStorage();
  }

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;

  Future<void> _loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    final userDataJson = prefs.getString(_userDataKey);

    if (userJson != null) {
      _user = User.fromJson(json.decode(userJson));
    }

    if (userDataJson != null) {
      _userData = json.decode(userDataJson);
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
  }

  Future<void> initializeUser() async {
    final supabase = await SupabaseClientManager.instance;
    final currentUser = supabase.client.auth.currentUser;
    if (currentUser != null) {
      setUser(currentUser);
      // Fetch additional user data if needed
      try {
        final userData = await supabase.client
            .from('users')
            .select()
            .eq('id', currentUser.id)
            .single();
        setUserData(userData);
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
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
    _userData = null;
    await _saveUserToStorage();
    notifyListeners();
  }
}
