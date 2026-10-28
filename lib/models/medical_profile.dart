class MedicalProfile {
  String fullName;
  String bloodGroup;
  String allergies;
  String conditions;
  String emergencyNotes;
  String nationalId;

  MedicalProfile({
    this.fullName = '',
    this.bloodGroup = 'Not set',
    this.allergies = 'None reported',
    this.conditions = 'None reported',
    this.emergencyNotes = '',
    this.nationalId = '',
  });

  factory MedicalProfile.fromJson(Map<String, dynamic> json) {
    return MedicalProfile(
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      bloodGroup: json['bloodGroup'] as String? ?? json['blood_group'] as String? ?? 'Not set',
      allergies: json['allergies'] as String? ?? json['allergies'] as String? ?? 'None reported',
      conditions: json['conditions'] as String? ?? json['medical_notes'] as String? ?? 'None reported',
      emergencyNotes: json['emergencyNotes'] as String? ?? json['emergency_note'] as String? ?? '',
      nationalId: json['nationalId'] as String? ?? json['uid'] as String? ?? '',
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
        'Name: ${fullName.isNotEmpty ? fullName : "AEGIS User"}\n'
        'Blood Group: $bloodGroup\n'
        'Allergies: $allergies\n'
        'Conditions: $conditions\n'
        'Notes: ${emergencyNotes.isNotEmpty ? emergencyNotes : "None"}\n'
        'ID: ${nationalId.isNotEmpty ? nationalId : "UNPAIRED"}';
  }
}
