import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoogleAdsInitialize {
  static Future<InitializationStatus> init() async =>
      await MobileAds.instance.initialize();
}
