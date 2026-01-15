import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as dev;
import 'vungle_platform.dart';
import 'models/vungle_ad_config.dart';

bool _isDebugEnabled = false;

void vungleLog(String message) {
  if (kDebugMode && _isDebugEnabled) {
    dev.log(message, name: 'vungleLog');
  }
}

/// Method Channel implementation for Vungle Ads
class MethodChannelVungle extends VunglePlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('multi_ads/vungle');

  @override
  Future<bool> initialize(VungleAdConfig config) async {
    _isDebugEnabled = config.debug;
    vungleLog('[Vungle] Initializing SDK with appId: ${config.appId}');
    final result = await methodChannel.invokeMethod<bool>(
      'initialize',
      config.toJson(),
    );
    vungleLog('[Vungle] Initialize result: $result');
    return result ?? false;
  }

  @override
  Future<bool> isInitialized() async {
    final result = await methodChannel.invokeMethod<bool>('isInitialized');
    return result ?? false;
  }

  @override
  Future<bool> loadInterstitialAd({required String placementId}) async {
    vungleLog('[Vungle] Loading interstitial ad for placement: $placementId');
    final result = await methodChannel.invokeMethod<bool>(
      'loadInterstitialAd',
      {'placementId': placementId},
    );
    return result ?? false;
  }

  @override
  Future<void> showInterstitialAd({required String placementId}) async {
    vungleLog('[Vungle] Showing interstitial ad for placement: $placementId');
    await methodChannel.invokeMethod('showInterstitialAd', {
      'placementId': placementId,
    });
  }

  @override
  Future<bool> canPlayInterstitialAd({required String placementId}) async {
    final result = await methodChannel.invokeMethod<bool>(
      'canPlayInterstitialAd',
      {'placementId': placementId},
    );
    return result ?? false;
  }

  @override
  Future<bool> loadAppOpenAd({required String placementId}) async {
    vungleLog('[Vungle] Loading app open ad for placement: $placementId');
    final result = await methodChannel.invokeMethod<bool>('loadAppOpenAd', {
      'placementId': placementId,
    });
    return result ?? false;
  }

  @override
  Future<void> showAppOpenAd({required String placementId}) async {
    vungleLog('[Vungle] Showing app open ad for placement: $placementId');
    await methodChannel.invokeMethod('showAppOpenAd', {
      'placementId': placementId,
    });
  }

  @override
  Future<bool> canPlayAppOpenAd({required String placementId}) async {
    final result = await methodChannel.invokeMethod<bool>('canPlayAppOpenAd', {
      'placementId': placementId,
    });
    return result ?? false;
  }

  @override
  Future<bool> loadBannerAd({
    required String placementId,
    required int bannerSize,
    required String listenerId,
  }) async {
    vungleLog(
      '[Vungle] Loading banner ad for placement: $placementId, size: $bannerSize',
    );
    final result = await methodChannel.invokeMethod<bool>('loadBannerAd', {
      'placementId': placementId,
      'bannerSize': bannerSize,
      'listenerId': listenerId,
    });
    return result ?? false;
  }

  @override
  Future<void> disposeBannerAd({required String listenerId}) async {
    vungleLog('[Vungle] Disposing banner ad: $listenerId');
    await methodChannel.invokeMethod('disposeBannerAd', {
      'listenerId': listenerId,
    });
  }
}
