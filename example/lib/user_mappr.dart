import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:example/core_models/user.dart';
import 'package:example/core_models/user_dto.dart';

import 'user_mappr.auto_mappr.dart';

@AutoMappr([
  MapType<UserDto, User>(), //ad
])
class UserMappr extends $UserMappr {}
