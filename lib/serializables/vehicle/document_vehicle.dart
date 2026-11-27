import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';
import 'package:parc_oto/utilities/profil_beautifier.dart';
part 'document_vehicle.g.dart';

@JsonSerializable()
class DocumentVehicle extends ParcOtoDefault {
  @JsonKey(
    name: "date_expiration",
    fromJson: dateFromIntJson,
    toJson: dateToIntJson,
  )
  DateTime? dateExpiration;
  String nom;
  String? vehicle;

  String? vehiclemat;
  String? createdBy;
  String? documentType;
  String? fileId;
  String? fileName;
  String? mimeType;
  int? fileSize;
  @JsonKey(fromJson: dateFromIntJson, toJson: dateToIntJson)
  DateTime? issueDate;
  String? notes;

  DocumentVehicle({
    required super.id,
    required this.nom,
    this.vehiclemat,
    this.vehicle,
    this.dateExpiration,
    this.createdBy,
    this.documentType,
    this.fileId,
    this.fileName,
    this.mimeType,
    this.fileSize,
    this.issueDate,
    this.notes,
    super.createdAt,
    super.updatedAt,
  });

  factory DocumentVehicle.fromJson(Map<String, dynamic> json) =>
      _$DocumentVehicleFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$DocumentVehicleToJson(this);
}
