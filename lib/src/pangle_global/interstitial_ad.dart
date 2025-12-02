import 'package:flutter/services.dart';
import 'models/ad_error.dart';
import 'pangle_method_channel.dart';

class PangleInterstitialAd {
  static const MethodChannel _channel = MethodChannel('multi_ads/pangle_global');
  static const EventChannel _eventChannel =
      EventChannel('multi_ads/pangle_global/interstitial_events');

  final String slotId;

  Function()? onAdLoaded;
  Function(PangleAdError error)? onAdLoadFailed;
  Function()? onAdClicked;
  Function()? onAdDismissed;
  Function()? onAdShowed;

  PangleInterstitialAd({
    required this.slotId,
    this.onAdLoaded,
    this.onAdLoadFailed,
    this.onAdClicked,
    this.onAdDismissed,
    this.onAdShowed,
  }) {
    _setupEventListener();
  }

  void _setupEventListener() {
    _eventChannel.receiveBroadcastStream().listen((event) {
      final Map<dynamic, dynamic> data = event as Map<dynamic, dynamic>;
      final String eventType = data['event'] as String;
      pangleLog('[Flutter Interstitial] Event received: $eventType');

      switch (eventType) {
        case 'onAdLoaded':
          pangleLog('[Flutter Interstitial] Ad loaded');
          onAdLoaded?.call();
          break;
        case 'onAdLoadFailed':
          final error =
              PangleAdError.fromJson(Map<String, dynamic>.from(data['error']));
          pangleLog(
              '[Flutter Interstitial] Ad load failed: ${error.code} - ${error.message}');
          onAdLoadFailed?.call(error);
          break;
        case 'onAdClicked':
          pangleLog('[Flutter Interstitial] Ad clicked');
          onAdClicked?.call();
          break;
        case 'onAdDismissed':
          pangleLog('[Flutter Interstitial] Ad dismissed');
          onAdDismissed?.call();
          break;
        case 'onAdShowed':
          pangleLog('[Flutter Interstitial] Ad showed');
          onAdShowed?.call();
          break;
      }
    });
  }

  Future<bool> load() async {
    try {
      pangleLog('[Flutter Interstitial] Loading ad with slotId: $slotId');
      final result = await _channel.invokeMethod<bool>('loadInterstitialAd', {
        'slotId': slotId,
      });
      pangleLog('[Flutter Interstitial] Load method called successfully');
      return result ?? false;
    } catch (e) {
      pangleLog('[Flutter Interstitial] Load method failed: $e');
      onAdLoadFailed?.call(PangleAdError(code: -1, message: e.toString()));
      return false;
    }
  }

  Future<void> show() async {
    try {
      pangleLog('[Flutter Interstitial] Showing ad');
      await _channel.invokeMethod('showInterstitialAd');
    } catch (e) {
      pangleLog('[Flutter Interstitial] Show method failed: $e');
      throw Exception('Failed to show interstitial ad: $e');
    }
  }
}
