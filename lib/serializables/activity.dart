import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';

import '../utilities/profil_beautifier.dart';

part 'activity.g.dart';

@JsonSerializable()
class Activity extends ParcOtoDefault {
  int type;
  String docID;
  String? personName;
  String? createdBy;
  String? docName;

  Activity(
      {required super.id,
      super.createdAt,
      super.updatedAt,
      required this.type,
      required this.docID,
      this.personName,
      this.createdBy,
      this.docName});

  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ActivityToJson(this);

}
