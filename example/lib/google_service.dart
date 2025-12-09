import 'package:flutter/cupertino.dart';
import 'package:multi_ads/multi_ads.dart';
import 'package:multi_ads_example/ad_config.dart';

class GoogleService {
  void openShow() => GoogleOpenAd.loadAndShow(GoogleAdConfig.openId);

  void interstitialStart() =>
      InterstitialUtils.start(GoogleAdConfig.interId, AdPlatform.google, 5);

  Future<void> bannerLoad(
    BuildContext context, {
    Function? onAdLoadedRefresh,
  }) => GoogleBannerAd.load(
    context,
    GoogleAdConfig.bannerId,
    onAdLoadedRefresh: onAdLoadedRefresh,
  );
}
