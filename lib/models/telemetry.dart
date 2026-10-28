class TelemetryData {
  bool isPaired;
  String? deviceId;
  String bleDeviceName;
  bool bleConnected;
  int battery;
  int batteryDaysRemaining;
  bool isCharging;
  bool gpsLocked;
  String network;
  String waterproofRating;
  bool fallDetectionEnabled;
  bool silentAlarm;
  String firmwareVersion;
  int rssi;
  DateTime? lastSyncTime;
  int? incidentStartTime;

  TelemetryData({
    this.isPaired = false,
    this.deviceId,
    this.bleDeviceName = 'AEGIS One Smart Wearable',
    this.bleConnected = false,
    this.battery = 92,
    this.batteryDaysRemaining = 5,
    this.isCharging = false,
    this.gpsLocked = false,
    this.network = 'BLE Link / Cloud Relay',
    this.waterproofRating = 'IP67',
    this.fallDetectionEnabled = true,
    this.silentAlarm = false,
    this.firmwareVersion = 'v2.1.0-secure',
    this.rssi = -62,
    this.lastSyncTime,
    this.incidentStartTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'isPaired': isPaired,
      'deviceId': deviceId,
      'bleDeviceName': bleDeviceName,
      'bleConnected': bleConnected,
      'battery': battery,
      'batteryDaysRemaining': batteryDaysRemaining,
      'isCharging': isCharging,
      'gpsLocked': gpsLocked,
      'network': network,
      'waterproofRating': waterproofRating,
      'fallDetectionEnabled': fallDetectionEnabled,
      'silentAlarm': silentAlarm,
      'firmwareVersion': firmwareVersion,
      'rssi': rssi,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'incidentStartTime': incidentStartTime,
    };
  }
}
