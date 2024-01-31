part of '../json_part.dart';

@JsonSerializable() //x
class JsonDartPartOf {
  final int id;

  factory JsonDartPartOf.fromJson(Map<String, dynamic> json) => _$JsonDartPartOfFromJson(json);

  JsonDartPartOf({required this.id});
  Map<String, dynamic> toJson() => _$JsonDartPartOfToJson(this);
}
