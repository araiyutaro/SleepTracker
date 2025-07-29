// Default entry point - redirects to dev flavor for backward compatibility
import 'config/flavor_config.dart';
import 'main_common.dart';

void main() {
  // デフォルトではDev環境として動作（後方互換性のため）
  FlavorConfig.initialize(Flavor.dev);
  mainCommon();
}
