class Driver {
  final String id;
  final String companyId;
  final String? siteId;
  final String firstName;
  final String lastName;
  final String registration;
  final String? email;
  final String? phone;
  final String? address;
  final String? profession;
  final DateTime? birthDate;
  final String? createdBy;
  final String? currentStateId;
  final int state;
  final String? subsidiary;
  final String? direction;
  final String? department;
  final List<String> vehicleIds;
  final bool service;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Driver({
    required this.id, required this.companyId, this.siteId,
    required this.firstName, required this.lastName, required this.registration,
    this.email, this.phone, this.address, this.profession, this.birthDate,
    this.createdBy, this.currentStateId, this.state = 0, this.subsidiary,
    this.direction, this.department, this.vehicleIds = const [], this.service = false,
    required this.createdAt, required this.updatedAt,
  });

  Driver copyWith({
    String? currentStateId, int? state, List<String>? vehicleIds,
    String? email, String? phone, String? address, String? profession,
    String? subsidiary, String? direction, String? department, bool? service,
    DateTime? updatedAt,
  }) => Driver.fromMap({
    ...toMap(),
    'currentStateId': currentStateId ?? this.currentStateId,
    'state': state ?? this.state,
    'vehicleIds': vehicleIds ?? this.vehicleIds,
    'email': email ?? this.email,
    'phone': phone ?? this.phone,
    'address': address ?? this.address,
    'profession': profession ?? this.profession,
    'subsidiary': subsidiary ?? this.subsidiary,
    'direction': direction ?? this.direction,
    'department': department ?? this.department,
    'service': service ?? this.service,
    'updatedAt': (updatedAt ?? DateTime.now().toUtc()).toIso8601String(),
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'companyId': companyId, 'siteId': siteId,
    'firstName': firstName, 'lastName': lastName, 'registration': registration,
    'email': email, 'phone': phone, 'address': address, 'profession': profession,
    'birthDate': birthDate?.toIso8601String(), 'createdBy': createdBy,
    'currentStateId': currentStateId, 'state': state, 'subsidiary': subsidiary,
    'direction': direction, 'department': department, 'vehicleIds': vehicleIds,
    'service': service, 'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Driver.fromMap(Map<String, dynamic> map) => Driver(
    id: map['id'] as String, companyId: map['companyId'] as String,
    siteId: map['siteId'] as String?,
    firstName: map['firstName'] as String? ?? '',
    lastName: map['lastName'] as String? ?? '',
    registration: map['registration'] as String? ?? '',
    email: map['email'] as String?, phone: map['phone'] as String?,
    address: map['address'] as String?, profession: map['profession'] as String?,
    birthDate: _date(map['birthDate']), createdBy: map['createdBy'] as String?,
    currentStateId: map['currentStateId'] as String?,
    state: (map['state'] as num?)?.toInt() ?? 0,
    subsidiary: map['subsidiary'] as String?, direction: map['direction'] as String?,
    department: map['department'] as String?,
    vehicleIds: List<String>.from(map['vehicleIds'] as List? ?? const []),
    service: map['service'] as bool? ?? false,
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
  );

  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}
