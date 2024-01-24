import 'package:example/core_models/core_class.dart'; // absolute import
import 'package:example/core_models/core_interface.dart'; // absolute import

import '../core_models/core_mixin.dart'; // relative import

class BaseClass extends CoreClass with CoreMixin implements CoreInterface {
  String? tag;
  String? data;

  @override
  String? interfaceData;
}
