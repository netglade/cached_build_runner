import 'package:json_annotation/json_annotation.dart';

import 'base_class.dart';

part 'counter_model.g.dart';

@JsonSerializable()
class CounterModel extends BaseClass {
  int count;
  final String description;
  final String x;
  final String y;

  CounterModel({
    this.count = 0,
    this.description = 'descriptionx',
    required this.x,
    this.y = 'yza',
  });

  factory CounterModel.fromJson(Map<String, dynamic> json) => _$CounterModelFromJson(json);

  Map<String, dynamic> toJson() => _$CounterModelToJson(this);
}
