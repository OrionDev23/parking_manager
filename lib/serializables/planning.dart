import 'package:fluent_ui/fluent_ui.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';

import '../utilities/profil_beautifier.dart';
part 'planning.g.dart';

@JsonSerializable()
class Planning extends ParcOtoDefault {
  @JsonKey(toJson: dateToIntJson, fromJson: dateFromIntJsonNonNull)
  DateTime startTime;

  @JsonKey(toJson: dateToIntJson, fromJson: dateFromIntJsonNonNull)
  DateTime endTime;
  String? recurrenceRule;
  bool isAllDay;
  String subject;

  int type;

  String? createdBy;

  @JsonKey(toJson: colorToInt, fromJson: colorFromInt)
  Color? color;

  String? notes;
  String? location;
  List<String>? resourceIds;

  Planning(
      {required super.id,
      super.createdAt,
      super.updatedAt,
      required this.subject,
      required this.startTime,
      required this.endTime,
      this.resourceIds,
      this.type = 0,
      this.location,
      this.notes,
      this.color,
      this.createdBy,
      this.isAllDay = false,
      this.recurrenceRule});

  factory Planning.fromJson(Map<String, dynamic> json) =>
      _$PlanningFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PlanningToJson(this);
}
