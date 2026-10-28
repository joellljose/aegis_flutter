enum AlertType {
  police,
  medical,
  contact,
  crash;

  String get displayName {
    switch (this) {
      case AlertType.police:
        return 'POLICE EMERGENCY';
      case AlertType.medical:
        return 'MEDICAL EMERGENCY';
      case AlertType.contact:
        return 'CUSTOM CONTACT SOS';
      case AlertType.crash:
        return 'VEHICLE CRASH IMPACT';
    }
  }

  String get shortCode {
    switch (this) {
      case AlertType.police:
        return 'POLICE';
      case AlertType.medical:
        return 'MEDICAL';
      case AlertType.contact:
        return 'CONTACT';
      case AlertType.crash:
        return 'CRASH';
    }
  }

  static AlertType fromString(String val) {
    switch (val.toUpperCase()) {
      case 'POLICE':
        return AlertType.police;
      case 'MEDICAL':
        return AlertType.medical;
      case 'CONTACT':
        return AlertType.contact;
      case 'CRASH':
        return AlertType.crash;
      default:
        return AlertType.police;
    }
  }
}
