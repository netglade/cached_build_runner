import 'package:json_annotation/json_annotation.dart';
import 'base_class.dart';

part 'counter_model.g.dart';

@JsonSerializable()
class CounterModel extends BaseClass {
  int count;
  final String description;

  CounterModel({
    this.count = 0,
    this.description = 'description',
  });

  factory CounterModel.fromJson(Map<String, dynamic> json) =>
      _$CounterModelFromJson(json);

  Map<String, dynamic> toJson() => _$CounterModelToJson(this);
}
