import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class UserLocationResult {
  final bool success;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? speed;
  final double? altitude;
  final String? address;
  final String? error;
  final bool isPermissionDenied;

  UserLocationResult({
    required this.success,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.speed,
    this.altitude,
    this.address,
    this.error,
    this.isPermissionDenied = false,
  });
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Acquires user's current GPS position with high accuracy
  Future<UserLocationResult> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return UserLocationResult(
          success: false,
          error: 'Location services are disabled on device.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return UserLocationResult(
            success: false,
            isPermissionDenied: true,
            error: 'Location permissions denied by user.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return UserLocationResult(
          success: false,
          isPermissionDenied: true,
          error: 'Location permissions are permanently denied.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return UserLocationResult(
        success: true,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed >= 0 ? position.speed * 3.6 : 0, // km/h
        altitude: position.altitude,
      );
    } catch (e) {
      debugPrint('[LocationService] GPS acquisition error: $e');
      return UserLocationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Reverse geocodes coordinates to a human-readable street address
  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json', 'User-Agent': 'AegisOneEmergencyApp/1.0'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'] as String?;
      }
    } catch (e) {
      debugPrint('[LocationService] Reverse geocode error: $e');
    }
    return null;
  }
}
