
import 'package:json_annotation/json_annotation.dart';

part 'task_group.g.dart';

@JsonSerializable()
class TaskGroup{
  String numero;
  List<String> tasks;
  double time;

  @JsonKey(includeFromJson: false,includeToJson: false)
  bool selected=false;
  TaskGroup({required this.numero,this.tasks=const [''],this.time=0.00});

  factory TaskGroup.fromJson(Map<String, dynamic> json) =>
      _$TaskGroupFromJson(json);

  Map<String, dynamic> toJson() => _$TaskGroupToJson(this);

}