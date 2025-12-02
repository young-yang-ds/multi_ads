
import 'multi_ads_platform_interface.dart';

class MultiAds {
  Future<String?> getPlatformVersion() {
    return MultiAdsPlatform.instance.getPlatformVersion();
  }
}
