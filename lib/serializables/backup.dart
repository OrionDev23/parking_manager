import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';

import '../utilities/profil_beautifier.dart';

part 'backup.g.dart';

@JsonSerializable()
class Backup extends ParcOtoDefault {
  final int vehicles;
  final int vehicledocs;
  final int vehiclesstates;
  final int drivers;
  final int driversdocs;
  final int driversstates;
  final int repairs;
  final int providers;
  final int plannings;
  final int logs;

  final String? createdBy;

  Backup({this.vehicles=0, this.vehicledocs=0, this
      .vehiclesstates=0,
  this.drivers=0, this.driversdocs=0, this.driversstates=0, this.repairs=0, this
      .providers=0, this.plannings=0, this.logs=0, this.createdBy, required
    super.id,super.createdAt,super.updatedAt});

  factory Backup.fromJson(Map<String, dynamic> json) =>
      _$BackupFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$BackupToJson(this);

}
