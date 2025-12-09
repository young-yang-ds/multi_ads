import 'package:flutter/cupertino.dart';
import 'package:multi_ads/multi_ads.dart';

import '../../ad_config.dart';
import '../../main.dart';

class CommonService {
  static const String appName = 'appName';
  static const String appVersion = 'appVersion';

  /// 广告平台
  static const AdPlatform adPlatform = AdPlatform.google;

  /// 广告单元id
  static String openId = adPlatform == AdPlatform.google
      ? GoogleAdConfig.openId
      : PangleAdsConfig.openId;
  static String bannerId = adPlatform == AdPlatform.google
      ? GoogleAdConfig.bannerId
      : PangleAdsConfig.bannerId;
  static String interId = adPlatform == AdPlatform.google
      ? GoogleAdConfig.interId
      : PangleAdsConfig.interId;

  /// 所有平台的广告 初始化
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
