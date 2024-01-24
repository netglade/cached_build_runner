import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String name;
  final int age;

  int get ageX => age;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  User({
    required this.id,
    required this.name,
    required this.age,
  });
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
