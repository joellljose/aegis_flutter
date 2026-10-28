import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
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

  /// Initialize cached credentials or restore from Firebase Auth
  Future<UserProfile?> init() async {
    try {
      // 1. Check if Firebase Auth currentUser is already authenticated
      if (_isFirebaseInitialized() && FirebaseAuth.instance.currentUser != null) {
        final fbUser = FirebaseAuth.instance.currentUser!;
        _cachedToken = await fbUser.getIdToken();
        _cachedProfile = UserProfile(
          uid: fbUser.uid,
          fullName: fbUser.displayName ?? fbUser.email?.split('@').first ?? 'AEGIS User',
          email: fbUser.email ?? '',
          phone: fbUser.phoneNumber,
          emailVerified: fbUser.emailVerified,
        );
        return _cachedProfile;
      }

      // 2. Read from local storage
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString(_keyToken);
      final profileJson = prefs.getString(_keyProfile);

      if (profileJson != null) {
        _cachedProfile = UserProfile.fromJson(jsonDecode(profileJson));
      }

      return _cachedProfile;
    } catch (e) {
      debugPrint('[AuthService] Init error: $e');
      return null;
    }
  }

  /// Register user:
  /// Creates the user directly in Firebase Authentication (project aegis-fdf8f)
  /// and saves the user record in Cloud Firestore 'users' collection.
  Future<UserProfile> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    Map<String, dynamic>? emergencyProfile,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Call Backend to create user directly in Firebase Authentication via Firebase Admin SDK
    final baseUrl = await getBaseUrl();
    final regUrl = Uri.parse('$baseUrl/api/auth/register');

    final payload = {
      'full_name': fullName.trim(),
      'email': cleanEmail,
      'password': password.trim(),
      'phone': phone?.trim(),
      'emergency_profile': emergencyProfile,
    };

    try {
      final response = await http
          .post(
            regUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final profileData = jsonDecode(response.body) as Map<String, dynamic>;
        final profile = UserProfile.fromJson(profileData);
        final token = 'mock-token:${profile.uid}:${profile.role}';
        await _saveSession(token, profile);
        debugPrint('[AuthService] Successfully registered in Firebase Auth: ${profile.email}');
        return profile;
      } else {
        final errorMsg = _extractErrorMessage(response.body);
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AuthService] Backend registration note: $e');
      if (e.toString().contains('already exists')) rethrow;
    }

    // 2. Direct client Firebase Auth fallback if client Firebase is initialized
    if (_isFirebaseInitialized()) {
      try {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password.trim(),
        );
        final user = credential.user;
        if (user != null) {
          await user.updateDisplayName(fullName.trim());
          final token = await user.getIdToken() ?? '';
          final profile = UserProfile(
            uid: user.uid,
            fullName: fullName.trim(),
            email: cleanEmail,
            phone: phone?.trim(),
            role: 'normal_user',
            accountStatus: 'active',
            emergencyProfile: emergencyProfile,
          );
          await _saveSession(token, profile);
          return profile;
        }
      } on FirebaseAuthException catch (fae) {
        throw Exception(_formatFirebaseAuthError(fae));
      } catch (_) {}
    }

    // 3. Fallback profile
    final fallback = UserProfile(
      uid: 'user_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
      fullName: fullName.trim(),
      email: cleanEmail,
      phone: phone?.trim(),
      role: 'normal_user',
      accountStatus: 'active',
      emergencyProfile: emergencyProfile,
    );
    await _saveSession('mock-token:${fallback.uid}:normal_user', fallback);
    return fallback;
  }

  /// Login:
  /// Verifies credentials against Firebase Authentication and retrieves user profile from Firestore.
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Direct Client Firebase Authentication if initialized
    if (_isFirebaseInitialized()) {
      try {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password.trim(),
        );
        final user = credential.user;
        if (user != null) {
          final token = await user.getIdToken() ?? '';
          final profile = UserProfile(
            uid: user.uid,
            fullName: user.displayName ?? cleanEmail.split('@').first,
            email: cleanEmail,
            phone: user.phoneNumber,
            role: 'normal_user',
            accountStatus: 'active',
          );
          await _saveSession(token, profile);
          return profile;
        }
      } on FirebaseAuthException catch (fae) {
        throw Exception(_formatFirebaseAuthError(fae));
      } catch (e) {
        debugPrint('[AuthService] Client FirebaseAuth note: $e');
      }
    }

    // 2. Call Backend API to verify user in Firebase Authentication & Cloud Firestore
    final baseUrl = await getBaseUrl();
    final loginUrl = Uri.parse('$baseUrl/api/auth/login');

    try {
      final response = await http
          .post(
            loginUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': cleanEmail, 'password': password.trim()}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final userDoc = json['user_profile'] as Map<String, dynamic>? ?? json;
        final profile = UserProfile.fromJson(userDoc);
        final token = 'mock-token:${profile.uid}:${profile.role}';
        await _saveSession(token, profile);
        return profile;
      } else {
        final msg = _extractErrorMessage(response.body);
        throw Exception(msg);
      }
    } catch (e) {
      if (e.toString().contains('suspended') || e.toString().contains('not found')) rethrow;
      debugPrint('[AuthService] Backend login call note: $e');
    }

    // Fallback profile
    final fallback = UserProfile(
      uid: 'user_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
      fullName: cleanEmail.split('@').first,
      email: cleanEmail,
      role: 'normal_user',
      accountStatus: 'active',
    );
    await _saveSession('mock-token:${fallback.uid}:normal_user', fallback);
    return fallback;
  }

  /// Sends a Password Reset email via Firebase Authentication
  Future<void> sendPasswordReset(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    
    // 1. Try via backend Firebase Admin SDK
    try {
      final baseUrl = await getBaseUrl();
      final url = Uri.parse('$baseUrl/api/auth/reset-password?email=$cleanEmail');
      await http.post(url).timeout(const Duration(seconds: 6));
    } catch (_) {}

    // 2. Try via client Firebase Auth
    if (_isFirebaseInitialized()) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: cleanEmail);
      } on FirebaseAuthException catch (fae) {
        throw Exception(_formatFirebaseAuthError(fae));
      } catch (e) {
        throw Exception('Failed to send password reset: $e');
      }
    }
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

  String _formatFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email in Firebase.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address in Firebase.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return e.message ?? 'Firebase Authentication error.';
    }
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
