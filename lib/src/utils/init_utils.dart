import 'dart:async';

import 'package:multi_ads/src/utils/log_utils.dart';

import '../../multi_ads.dart';

class InitStatus {
  final AdPlatform platform;
  final bool success;
  final String? error;

  InitStatus({required this.platform, required this.success, this.error});

  Map<String, dynamic> toJson() => {
    'platform': platform.name,
    'success': success,
    'error': error,
  };

  @override
  String toString() => toJson().toString();
}

class InitUtils {
  static Stream<InitStatus> init({
    String? pangleGlobalAppId,
    bool debug = false,
  }) async* {
    // Google Ads 初始化
    try {
      await GoogleAdsInitialize.init();
      LogUtils.log('google ads init success');
      yield InitStatus(platform: AdPlatform.google, success: true);
    } catch (e) {
      LogUtils.log('google ads init failed: $e');
      yield InitStatus(
        platform: AdPlatform.google,
        success: false,
        error: e.toString(),
      );
    }

    // Pangle 初始化
    if (pangleGlobalAppId != null) {
      final config = PangleAdConfig(appId: pangleGlobalAppId, debug: debug);

      try {
        final success = await PanglePlatform.instance.initialize(config);

        if (success) {
          LogUtils.log('pga init success');
          yield InitStatus(platform: AdPlatform.pangleGlobal, success: true);
        } else {
          LogUtils.log('pga init failed');
          yield InitStatus(
            platform: AdPlatform.pangleGlobal,
            success: false,
            error: 'initialize returned false',
          );
        }
      } catch (e) {
        LogUtils.log('pga init failed: $e');
        yield InitStatus(
          platform: AdPlatform.pangleGlobal,
          success: false,
          error: e.toString(),
        );
      }
    }
  }
}
