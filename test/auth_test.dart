import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aegis_flutter/models/user_profile.dart';
import 'package:aegis_flutter/services/auth_service.dart';
import 'package:aegis_flutter/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AEGIS Auth Model & Service Tests', () {
    test('UserProfile JSON serialization and copyWith', () {
      final profile = UserProfile(
        uid: 'user_test_999',
        fullName: 'Jane Doe',
        email: 'jane@aegis-one.org',
        phone: '+1234567890',
        role: 'normal_user',
        accountStatus: 'active',
        emergencyProfile: {'blood_group': 'AB+'},
      );

      final json = profile.toJson();
      expect(json['uid'], 'user_test_999');
      expect(json['full_name'], 'Jane Doe');
      expect(json['role'], 'normal_user');
      expect(json['emergency_profile']['blood_group'], 'AB+');

      final deserialized = UserProfile.fromJson(json);
      expect(deserialized.uid, profile.uid);
      expect(deserialized.email, profile.email);

      final updated = deserialized.copyWith(fullName: 'Jane Updated');
      expect(updated.fullName, 'Jane Updated');
      expect(updated.uid, 'user_test_999');
    });

    test('AuthService registers and saves session locally', () async {
      final authService = AuthService();
      final user = await authService.register(
        email: 'test@aegis-one.org',
        password: 'Password123!',
        fullName: 'Test User',
        phone: '+1555000111',
      );

      expect(user.email, 'test@aegis-one.org');
      expect(user.fullName, 'Test User');
      expect(authService.isAuthenticated, isTrue);
      expect(authService.token, isNotNull);

      // Verify sign out
      await authService.signOut();
      expect(authService.isAuthenticated, isFalse);
      expect(authService.token, isNull);
    });

    test('AuthProvider lifecycle: login, state update, and logout', () async {
      final provider = AuthProvider();
      expect(provider.isAuthenticated, isFalse);

      final success = await provider.login(
        email: 'alice@aegis-one.org',
        password: 'Password123!',
      );

      expect(success, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser?.email, 'alice@aegis-one.org');

      await provider.logout();
      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);
    });
  });
}
