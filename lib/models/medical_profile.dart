class MedicalProfile {
  String fullName;
  String bloodGroup;
  String allergies;
  String conditions;
  String emergencyNotes;
  String nationalId;

  MedicalProfile({
    this.fullName = 'Alex Morgan',
    this.bloodGroup = 'O+ Positive',
    this.allergies = 'Penicillin, Peanuts',
    this.conditions = 'Mild Asthma',
    this.emergencyNotes = 'Carries inhaler in backpack. Organ donor.',
    this.nationalId = 'AEGIS-ID-9821',
  });

  factory MedicalProfile.fromJson(Map<String, dynamic> json) {
    return MedicalProfile(
      fullName: json['fullName'] as String? ?? 'Alex Morgan',
      bloodGroup: json['bloodGroup'] as String? ?? 'O+ Positive',
      allergies: json['allergies'] as String? ?? 'None',
      conditions: json['conditions'] as String? ?? 'None',
      emergencyNotes: json['emergencyNotes'] as String? ?? '',
      nationalId: json['nationalId'] as String? ?? 'AEGIS-ID-9821',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'conditions': conditions,
      'emergencyNotes': emergencyNotes,
      'nationalId': nationalId,
    };
  }

  String toQrString() {
    return 'AEGIS MEDICAL ID\n'
        'Name: $fullName\n'
        'Blood Group: $bloodGroup\n'
        'Allergies: $allergies\n'
        'Conditions: $conditions\n'
        'Notes: $emergencyNotes\n'
        'ID: $nationalId';
  }
}
