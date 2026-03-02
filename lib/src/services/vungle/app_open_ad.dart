import 'package:flutter/services.dart';
import 'models/vungle_ad_error.dart';
import 'vungle_method_channel.dart';
import 'vungle_platform.dart';

/// Vungle App Open Ad (uses InterstitialAd type in Vungle SDK)
class VungleAppOpenAd {
  static const EventChannel _eventChannel = EventChannel(
    'multi_ads/vungle/appopen_events',
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

  VungleAppOpenAd({
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

      vungleLog('[VungleAppOpenAd] Event received: $eventType');

      switch (eventType) {
        case 'onAdLoaded':
          _isLoaded = true;
          _isLoading = false;
          vungleLog('[VungleAppOpenAd] Ad loaded');
          onAdLoaded?.call();
          break;
        case 'onAdLoadFailed':
          _isLoading = false;
          final error = VungleAdError.fromJson(
            Map<String, dynamic>.from(data['error'] ?? {}),
          );
          vungleLog(
            '[VungleAppOpenAd] Ad load failed: ${error.code} - ${error.message}',
          );
          onAdLoadFailed?.call(error);
          break;
        case 'onAdClicked':
          vungleLog('[VungleAppOpenAd] Ad clicked');
          onAdClicked?.call();
          break;
        case 'onAdDismissed':
          _isLoaded = false;
          vungleLog('[VungleAppOpenAd] Ad dismissed');
          onAdDismissed?.call();
          break;
        case 'onAdShowed':
          vungleLog('[VungleAppOpenAd] Ad showed');
          onAdShowed?.call();
          break;
        case 'onAdImpression':
          vungleLog('[VungleAppOpenAd] Ad impression');
          onAdImpression?.call();
          break;
        case 'onAdFailedToPlay':
          _isLoaded = false;
          final error = VungleAdError.fromJson(
            Map<String, dynamic>.from(data['error'] ?? {}),
          );
          vungleLog(
            '[VungleAppOpenAd] Ad failed to play: ${error.code} - ${error.message}',
          );
          onAdFailedToPlay?.call(error);
          break;
      }
    });
  }

  /// Load the app open ad
  Future<bool> load() async {
    if (_isLoading) {
      vungleLog('[VungleAppOpenAd] Already loading');
      return false;
    }

    if (_isLoaded) {
      vungleLog('[VungleAppOpenAd] Already loaded');
      return true;
    }

    _isLoading = true;
    vungleLog('[VungleAppOpenAd] Loading ad for placement: $placementId');

    try {
      final result = await VunglePlatform.instance.loadAppOpenAd(
        placementId: placementId,
      );
      return result;
    } catch (e) {
      _isLoading = false;
      vungleLog('[VungleAppOpenAd] Load error: $e');
      onAdLoadFailed?.call(VungleAdError(code: -1, message: e.toString()));
      return false;
    }
  }

  /// Show the app open ad
  Future<void> show() async {
    if (!_isLoaded) {
      vungleLog('[VungleAppOpenAd] Ad not loaded');
      onAdFailedToPlay?.call(VungleAdError(code: -1, message: 'Ad not loaded'));
      return;
    }

    vungleLog('[VungleAppOpenAd] Showing ad');
    try {
      await VunglePlatform.instance.showAppOpenAd(placementId: placementId);
    } catch (e) {
      vungleLog('[VungleAppOpenAd] Show error: $e');
      onAdFailedToPlay?.call(VungleAdError(code: -1, message: e.toString()));
    }
  }

  /// Check if the ad can be played
  Future<bool> canPlayAd() async {
    return await VunglePlatform.instance.canPlayAppOpenAd(
      placementId: placementId,
    );
  }

  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
}
