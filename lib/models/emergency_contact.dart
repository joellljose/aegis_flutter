class EmergencyContact {
  final String id;
  String name;
  String phone;
  String relation;
  int priority;
  List<String> channels;
  String status; // 'STANDBY' | 'SENDING' | 'DELIVERED' | 'ACKNOWLEDGED'

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relation = 'Family',
    this.priority = 1,
    List<String>? channels,
    this.status = 'STANDBY',
  }) : channels = channels ?? ['SMS', 'WhatsApp', 'CALL'];

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String? ?? json['contact_id'] as String? ?? 'c_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? json['contact_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      relation: json['relation'] as String? ?? json['relationship'] as String? ?? 'Family',
      priority: json['priority'] as int? ?? 1,
      channels: (json['channels'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['SMS', 'WhatsApp'],
      status: json['status'] as String? ?? 'STANDBY',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contact_id': id,
      'name': name,
      'contact_name': name,
      'phone': phone,
      'relation': relation,
      'relationship': relation,
      'priority': priority,
      'channels': channels,
      'status': status,
    };
  }

  EmergencyContact copyWith({
    String? name,
    String? phone,
    String? relation,
    int? priority,
    List<String>? channels,
    String? status,
  }) {
    return EmergencyContact(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relation: relation ?? this.relation,
      priority: priority ?? this.priority,
      channels: channels ?? this.channels,
      status: status ?? this.status,
    );
  }
}
