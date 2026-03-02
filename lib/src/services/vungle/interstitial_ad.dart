import 'package:flutter/services.dart';
import 'models/vungle_ad_error.dart';
import 'vungle_method_channel.dart';
import 'vungle_platform.dart';

/// Vungle Interstitial Ad
class VungleInterstitialAd {
  static const EventChannel _eventChannel = EventChannel(
    'multi_ads/vungle/interstitial_events',
  );

  final String placementId;

  Function()? onAdLoaded;
  Function(VungleAdError error)? onAdLoadFailed;
  Function()? onAdClicked;
  Function()? onAdDismissed;
  Function()? onAdShowed;
  Function()? onAdImpression;
  Function(VungleAdError error)? onAdFailedToPlay;

  bool _isLoaded = false;
  bool _isLoading = false;

  VungleInterstitialAd({
    required this.placementId,
    this.onAdLoaded,
    this.onAdLoadFailed,
    this.onAdClicked,
    this.onAdDismissed,
    this.onAdShowed,
    this.onAdImpression,
    this.onAdFailedToPlay,
  }) {
    _setupEventListener();
  }

  void _setupEventListener() {
    _eventChannel.receiveBroadcastStream().listen((event) {
      final Map<dynamic, dynamic> data = event as Map<dynamic, dynamic>;
      final String eventType = data['event'] as String;
      final String eventPlacementId = data['placementId'] as String? ?? '';

      // Only handle events for this placement
      if (eventPlacementId != placementId) return;

      vungleLog('[VungleInterstitialAd] Event received: $eventType');

      switch (eventType) {
        case 'onAdLoaded':
          _isLoaded = true;
          _isLoading = false;
          vungleLog('[VungleInterstitialAd] Ad loaded');
          onAdLoaded?.call();
          break;
        case 'onAdLoadFailed':
          _isLoading = false;
          final error = VungleAdError.fromJson(
            Map<String, dynamic>.from(data['error'] ?? {}),
          );
          vungleLog(
            '[VungleInterstitialAd] Ad load failed: ${error.code} - ${error.message}',
          );
          onAdLoadFailed?.call(error);
          break;
        case 'onAdClicked':
          vungleLog('[VungleInterstitialAd] Ad clicked');
          onAdClicked?.call();
          break;
        case 'onAdDismissed':
          _isLoaded = false;
          vungleLog('[VungleInterstitialAd] Ad dismissed');
          onAdDismissed?.call();
          break;
        case 'onAdShowed':
          vungleLog('[VungleInterstitialAd] Ad showed');
          onAdShowed?.call();
          break;
        case 'onAdImpression':
          vungleLog('[VungleInterstitialAd] Ad impression');
          onAdImpression?.call();
          break;
        case 'onAdFailedToPlay':
          _isLoaded = false;
          final error = VungleAdError.fromJson(
            Map<String, dynamic>.from(data['error'] ?? {}),
          );
          vungleLog(
            '[VungleInterstitialAd] Ad failed to play: ${error.code} - ${error.message}',
          );
          onAdFailedToPlay?.call(error);
          break;
      }
    });
  }

  /// Load the interstitial ad
  Future<bool> load() async {
    if (_isLoading) {
      vungleLog('[VungleInterstitialAd] Already loading');
      return false;
    }

    if (_isLoaded) {
      vungleLog('[VungleInterstitialAd] Already loaded');
      return true;
    }

    _isLoading = true;
    vungleLog('[VungleInterstitialAd] Loading ad for placement: $placementId');

    try {
      final result = await VunglePlatform.instance.loadInterstitialAd(
        placementId: placementId,
      );
      return result;
    } catch (e) {
      _isLoading = false;
      vungleLog('[VungleInterstitialAd] Load error: $e');
      onAdLoadFailed?.call(VungleAdError(code: -1, message: e.toString()));
      return false;
    }
  }

  /// Show the interstitial ad
  Future<void> show() async {
    if (!_isLoaded) {
      vungleLog('[VungleInterstitialAd] Ad not loaded');
      onAdFailedToPlay?.call(VungleAdError(code: -1, message: 'Ad not loaded'));
      return;
    }

    vungleLog('[VungleInterstitialAd] Showing ad');
    try {
      await VunglePlatform.instance.showInterstitialAd(
        placementId: placementId,
      );
    } catch (e) {
      vungleLog('[VungleInterstitialAd] Show error: $e');
      onAdFailedToPlay?.call(VungleAdError(code: -1, message: e.toString()));
    }
  }

  /// Check if the ad can be played
  Future<bool> canPlayAd() async {
    return await VunglePlatform.instance.canPlayInterstitialAd(
      placementId: placementId,
    );
  }

  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
}
