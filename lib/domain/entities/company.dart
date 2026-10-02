class Company {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? email;
  final String? description;
  final String? nif;
  final String? nis;
  final String? rc;
  final String? art;
  final String? logo;
  final List<String> subsidiaries;
  final List<String> directions;
  final List<String> departments;

  const Company({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.email,
    this.description,
    this.nif,
    this.nis,
    this.rc,
    this.art,
    this.logo,
    this.subsidiaries = const [],
    this.directions = const [],
    this.departments = const [],
  });

  Company copyWith({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? description,
    String? nif,
    String? nis,
    String? rc,
    String? art,
    String? logo,
    List<String>? subsidiaries,
    List<String>? directions,
    List<String>? departments,
  }) {
    return Company(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      description: description ?? this.description,
      nif: nif ?? this.nif,
      nis: nis ?? this.nis,
      rc: rc ?? this.rc,
      art: art ?? this.art,
      logo: logo ?? this.logo,
      subsidiaries: subsidiaries ?? this.subsidiaries,
      directions: directions ?? this.directions,
      departments: departments ?? this.departments,
    );
  }
}
