class TelemetryData {
  int battery;
  int batteryDaysRemaining;
  bool isCharging;
  bool bleConnected;
  String bleDeviceName;
  bool gpsLocked;
  String network;
  String waterproofRating;
  int? incidentStartTime;

  TelemetryData({
    this.battery = 94,
    this.batteryDaysRemaining = 5,
    this.isCharging = false,
    this.bleConnected = true,
    this.bleDeviceName = 'AEGIS One #882',
    this.gpsLocked = true,
    this.network = 'LTE-M / 4G Active',
    this.waterproofRating = 'IP67',
    this.incidentStartTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'battery': battery,
      'batteryDaysRemaining': batteryDaysRemaining,
      'isCharging': isCharging,
      'bleConnected': bleConnected,
      'bleDeviceName': bleDeviceName,
      'gpsLocked': gpsLocked,
      'network': network,
      'waterproofRating': waterproofRating,
      'incidentStartTime': incidentStartTime,
    };
  }
}
