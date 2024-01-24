import 'package:json_annotation/json_annotation.dart';

import '../core_models/user.dart';
import 'base_class.dart';

part 'counter_model2.g.dart';

@JsonSerializable()
class CounterModel2 extends BaseClass {
  int count;
  final String description;
  final User user;

  CounterModel2({
    this.count = 0,
    this.description = 'descriptionsadsadasaa',
    required this.user,
  });

  factory CounterModel2.fromJson(Map<String, dynamic> json) => _$CounterModel2FromJson(json);

  Map<String, dynamic> toJson() => _$CounterModel2ToJson(this);
}
