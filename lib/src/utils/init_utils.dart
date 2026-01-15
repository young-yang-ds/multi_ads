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
    String? vungleAppId,
    bool debug = false,
  }) {
    final controller = StreamController<InitStatus>();

    Future<void> initGoogle() async {
      try {
        await GoogleAdsInitialize.init();
        LogUtils.log('google ads init success');
        controller.add(InitStatus(platform: AdPlatform.google, success: true));
      } catch (e) {
        LogUtils.log('google ads init failed: $e');
        controller.add(
          InitStatus(
            platform: AdPlatform.google,
            success: false,
            error: e.toString(),
          ),
        );
      }
    }

    Future<void> initPangle() async {
      if (pangleGlobalAppId == null) return;

      final config = PangleAdConfig(appId: pangleGlobalAppId, debug: debug);

      try {
        final success = await PanglePlatform.instance.initialize(config);

        if (success) {
          LogUtils.log('pga init success');
          controller.add(
            InitStatus(platform: AdPlatform.pangleGlobal, success: true),
          );
        } else {
          LogUtils.log('pga init failed');
          controller.add(
            InitStatus(
              platform: AdPlatform.pangleGlobal,
              success: false,
              error: 'initialize returned false',
            ),
          );
        }
      } catch (e) {
        LogUtils.log('pga init failed: $e');
        controller.add(
          InitStatus(
            platform: AdPlatform.pangleGlobal,
            success: false,
            error: e.toString(),
          ),
        );
      }
    }

    Future<void> initVungle() async {
      if (vungleAppId == null) return;

      final config = VungleAdConfig(appId: vungleAppId, debug: debug);

      try {
        final success = await VunglePlatform.instance.initialize(config);

        if (success) {
          LogUtils.log('vungle init success');
          controller.add(
            InitStatus(platform: AdPlatform.vungle, success: true),
          );
        } else {
          LogUtils.log('vungle init failed');
          controller.add(
            InitStatus(
              platform: AdPlatform.vungle,
              success: false,
              error: 'initialize returned false',
            ),
          );
        }
      } catch (e) {
        LogUtils.log('vungle init failed: $e');
        controller.add(
          InitStatus(
            platform: AdPlatform.vungle,
            success: false,
            error: e.toString(),
          ),
        );
      }
    }

    Future.wait([initGoogle(), initPangle(), initVungle()]).then((_) {
      controller.close();
    });

    return controller.stream;
  }
}
