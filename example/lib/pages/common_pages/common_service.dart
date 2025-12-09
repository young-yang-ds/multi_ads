import 'package:flutter/cupertino.dart';
import 'package:multi_ads/multi_ads.dart';

import '../../ad_config.dart';
import '../../main.dart';

class CommonService {
  static const AdPlatform adPlatform = AdPlatform.google;

  static String openId = adPlatform == AdPlatform.google
      ? GoogleAdConfig.openId
      : PangleAdsConfig.openId;
  static String bannerId = adPlatform == AdPlatform.google
      ? GoogleAdConfig.bannerId
      : PangleAdsConfig.bannerId;
  static String interId = adPlatform == AdPlatform.google
      ? GoogleAdConfig.interId
      : PangleAdsConfig.interId;

  void init(BuildContext context, Function onRefresh) {
    InitUtils.init(
      pangleGlobalAppId: PangleAdsConfig.appId,
      debug: true,
    ).listen((status) {
      demoLog(status.toString());
      switch (status.platform) {
        case AdPlatform.google:
          BannerUtils.load(
            context,
            bannerId,
            adPlatform,
            onAdLoadedRefresh: () {
              onRefresh();
            },
          );
        case AdPlatform.pangleGlobal:
          onRefresh();
      }
    });
  }
}
