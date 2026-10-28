import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_profile.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _keyToken = 'aegis_auth_token';
  static const String _keyProfile = 'aegis_user_profile';
  static const String _keyBackendUrl = 'aegis_backend_url';

  String? _cachedToken;
  UserProfile? _cachedProfile;

  String? get token => _cachedToken;
  UserProfile? get profile => _cachedProfile;
  bool get isAuthenticated => _cachedProfile != null;

  /// Determines default backend URL based on platform
  String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {}
    return 'http://localhost:8000';
  }

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBackendUrl) ?? defaultBaseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBackendUrl, url.trim());
  }

  /// Initialize cached credentials on app launch
  Future<UserProfile?> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString(_keyToken);
      final profileJson = prefs.getString(_keyProfile);

      if (profileJson != null) {
        _cachedProfile = UserProfile.fromJson(jsonDecode(profileJson));
      }

      // If we have a cached token, try to refresh profile from backend
      if (_cachedToken != null) {
        try {
          final refreshed = await fetchProfileFromBackend(_cachedToken!);
          if (refreshed != null) {
            _cachedProfile = refreshed;
            await _saveSession(_cachedToken!, refreshed);
          }
        } catch (e) {
          debugPrint('[AuthService] Backend profile refresh deferred: $e');
        }
      }
      return _cachedProfile;
    } catch (e) {
      debugPrint('[AuthService] Init error: $e');
      return null;
    }
  }

  /// Register a new user with Firebase Auth and create profile on Python FastAPI Backend
  Future<UserProfile> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    Map<String, dynamic>? emergencyProfile,
  }) async {
    String authToken;
    String uid;

    // 1. Firebase Authentication Registration
    if (_isFirebaseInitialized()) {
      try {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        final user = credential.user;
        if (user == null) throw Exception('Firebase user creation returned null.');
        uid = user.uid;
        authToken = await user.getIdToken() ?? 'mock-token:$uid:normal_user';
      } catch (e) {
        // Fallback for offline / dev emulator mode if Firebase network is unconfigured
        debugPrint('[AuthService] Firebase Auth create error, using dev mock token: $e');
        uid = 'user_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
        authToken = 'mock-token:$uid:normal_user';
      }
    } else {
      uid = 'user_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      authToken = 'mock-token:$uid:normal_user';
    }

    // 2. Call FastAPI Backend to create user profile in Firestore
    final baseUrl = await getBaseUrl();
    final profileUrl = Uri.parse('$baseUrl/api/v1/profile');

    final payload = {
      'full_name': fullName.trim(),
      'phone': phone?.trim(),
      'emergency_profile': emergencyProfile,
    };

    try {
      final response = await http
          .post(
            profileUrl,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 201) {
        final profileData = jsonDecode(response.body) as Map<String, dynamic>;
        final profile = UserProfile.fromJson(profileData);
        await _saveSession(authToken, profile);
        return profile;
      } else if (response.statusCode == 409) {
        // Profile already created; fetch existing
        final existing = await fetchProfileFromBackend(authToken);
        if (existing != null) {
          await _saveSession(authToken, existing);
          return existing;
        }
        throw Exception('User profile already registered in AEGIS backend.');
      } else {
        final errorMsg = _extractErrorMessage(response.body);
        throw Exception('Backend registration failed (${response.statusCode}): $errorMsg');
      }
    } catch (e) {
      debugPrint('[AuthService] Backend registration warning: $e');
      // If backend is temporarily offline, create local session with token
      final fallbackProfile = UserProfile(
        uid: uid,
        fullName: fullName.trim(),
        email: email.trim(),
        phone: phone?.trim(),
        role: 'normal_user',
        accountStatus: 'active',
        emergencyProfile: emergencyProfile,
        createdAt: DateTime.now().toIso8601String(),
      );
      await _saveSession(authToken, fallbackProfile);
      return fallbackProfile;
    }
  }

  /// Login with Firebase Auth and sync profile with Python FastAPI Backend
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    String authToken;
    String uid;

    // 1. Firebase Authentication Login
    if (_isFirebaseInitialized()) {
      try {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        final user = credential.user;
        if (user == null) throw Exception('Firebase user sign-in returned null.');
        uid = user.uid;
        authToken = await user.getIdToken() ?? 'mock-token:$uid:normal_user';
      } catch (e) {
        debugPrint('[AuthService] Firebase signIn error, falling back to mock dev mode: $e');
        uid = 'user_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
        authToken = 'mock-token:$uid:normal_user';
      }
    } else {
      uid = 'user_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      authToken = 'mock-token:$uid:normal_user';
    }

    // 2. Fetch User Profile from Python Backend
    try {
      final backendProfile = await fetchProfileFromBackend(authToken);
      if (backendProfile != null) {
        await _saveSession(authToken, backendProfile);
        return backendProfile;
      }
    } catch (e) {
      debugPrint('[AuthService] Backend profile lookup warning: $e');
    }

    // Fallback if backend unreachable
    final fallback = UserProfile(
      uid: uid,
      fullName: email.split('@').first,
      email: email.trim(),
      role: 'normal_user',
      accountStatus: 'active',
    );
    await _saveSession(authToken, fallback);
    return fallback;
  }

  /// Fetch user profile from /api/v1/profile/me
  Future<UserProfile?> fetchProfileFromBackend(String token) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/api/v1/profile/me');

    final response = await http
        .get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 6));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    }
    return null;
  }

  /// Sign out
  Future<void> signOut() async {
    if (_isFirebaseInitialized()) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    _cachedToken = null;
    _cachedProfile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyProfile);
  }

  bool _isFirebaseInitialized() {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveSession(String token, UserProfile profile) async {
    _cachedToken = token;
    _cachedProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyProfile, jsonEncode(profile.toJson()));
  }

  String _extractErrorMessage(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map && json['detail'] != null) {
        return json['detail'].toString();
      }
    } catch (_) {}
    return body;
  }
}
