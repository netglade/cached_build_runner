import 'package:json_annotation/json_annotation.dart';

part 'counter_model.g.dart';

@JsonSerializable()
class CounterModel {
  int count;
  String? description;

  CounterModel({
    this.count = 0,
    this.description,
  });

  factory CounterModel.fromJson(Map<String, dynamic> json) =>
      _$CounterModelFromJson(json);

  Map<String, dynamic> toJson() => _$CounterModelToJson(this);
}
