import 'package:flutter/cupertino.dart';
import 'package:multi_ads/multi_ads.dart';

import '../../ad_config.dart';
import '../../main.dart';

class CommonService {
  static const String appName = 'appName';
  static const String appVersion = 'appVersion';

  /// 广告平台
  static const AdPlatform adPlatform = AdPlatform.vungle;

  /// 广告单元id
  static String get openId {
    switch (adPlatform) {
      case AdPlatform.google:
        return GoogleAdConfig.openId;
      case AdPlatform.pangleGlobal:
        return PangleAdsConfig.openId;
      case AdPlatform.vungle:
        return VungleAdsConfig.openId;
    }
  }

  static String get bannerId {
    switch (adPlatform) {
      case AdPlatform.google:
        return GoogleAdConfig.bannerId;
      case AdPlatform.pangleGlobal:
        return PangleAdsConfig.bannerId;
      case AdPlatform.vungle:
        return VungleAdsConfig.bannerId;
    }
  }

  static String get interId {
    switch (adPlatform) {
      case AdPlatform.google:
        return GoogleAdConfig.interId;
      case AdPlatform.pangleGlobal:
        return PangleAdsConfig.interId;
      case AdPlatform.vungle:
        return VungleAdsConfig.interId;
    }
  }

  /// 所有平台的广告 初始化
  void init(BuildContext context, Function onRefresh) {
    InitUtils.init(
      pangleGlobalAppId: PangleAdsConfig.appId,
      vungleAppId: VungleAdsConfig.appId,
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
        case AdPlatform.vungle:
          onRefresh();
      }
    });
  }
}
