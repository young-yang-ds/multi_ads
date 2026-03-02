import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as dev;
import 'pangle_platform.dart';
import 'models/ad_config.dart';

bool _isDebugEnabled = false;

void pangleLog(String message) {
  if (kDebugMode && _isDebugEnabled) {
    dev.log(message, name: 'pangleLog');
  }
}

class MethodChannelPangle extends PanglePlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('multi_ads/pangle_global');

  @override
  Future<bool> initialize(PangleAdConfig config) async {
    _isDebugEnabled = config.debug;
    final result =
        await methodChannel.invokeMethod<bool>('initialize', config.toJson());
    return result ?? false;
  }

  @override
  Future<void> loadSplashAd({
    required String slotId,
    required int timeout,
  }) async {
    await methodChannel.invokeMethod('loadSplashAd', {
      'slotId': slotId,
      'timeout': timeout,
    });
  }

  @override
  Future<bool> loadInterstitialAd({
    required String slotId,
  }) async {
    final result =
        await methodChannel.invokeMethod<bool>('loadInterstitialAd', {
      'slotId': slotId,
    });
    return result ?? false;
  }

  @override
  Future<void> showInterstitialAd() async {
    await methodChannel.invokeMethod('showInterstitialAd');
  }

  @override
  Future<bool> loadBannerAd({
    required String slotId,
    required int adSize,
    required String listenerId,
  }) async {
    final result = await methodChannel.invokeMethod<bool>('loadBannerAd', {
      'slotId': slotId,
      'adSize': adSize,
      'listenerId': listenerId,
    });
    return result ?? false;
  }

  @override
  Future<bool> showBannerAd({
    required String listenerId,
  }) async {
    final result = await methodChannel.invokeMethod<bool>('showBannerAd', {
      'listenerId': listenerId,
    });
    return result ?? false;
  }

  @override
  Future<void> hideBannerAd({
    required String listenerId,
  }) async {
    await methodChannel.invokeMethod('hideBannerAd', {
      'listenerId': listenerId,
    });
  }

  @override
  Future<void> disposeBannerAd({
    required String listenerId,
  }) async {
    await methodChannel.invokeMethod('disposeBannerAd', {
      'listenerId': listenerId,
    });
  }
}
