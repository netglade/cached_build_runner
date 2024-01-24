import 'package:freezed_annotation/freezed_annotation.dart';

import '../core_models/user.dart';

part 'freezed_union.freezed.dart';

@freezed
abstract class FreezedUnion with _$FreezedUnion {
  const factory FreezedUnion.home() = Home;
  const factory FreezedUnion.user(User user) = UserUnion;
}
