import 'config/flavor_config.dart';
import 'main_common.dart';

void main() {
  FlavorConfig.initialize(Flavor.prod);
  mainCommon();
}