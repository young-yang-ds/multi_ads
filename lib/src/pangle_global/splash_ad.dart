import 'package:flutter/services.dart';
import 'models/ad_error.dart';
import 'pangle_method_channel.dart';

class PangleSplashAd {
  static const MethodChannel _channel = MethodChannel('multi_ads/pangle_global');
  static const EventChannel _eventChannel =
      EventChannel('multi_ads/pangle_global/splash_events');

  final String slotId;
  final int timeout;

  Function()? onAdLoaded;
  Function(PangleAdError error)? onAdLoadFailed;
  Function()? onAdClicked;
  Function()? onAdSkipped;
  Function()? onAdDismissed;

  PangleSplashAd({
    required this.slotId,
    this.timeout = 3000,
    this.onAdLoaded,
    this.onAdLoadFailed,
    this.onAdClicked,
    this.onAdSkipped,
    this.onAdDismissed,
  }) {
    _setupEventListener();
  }

  void _setupEventListener() {
    _eventChannel.receiveBroadcastStream().listen((event) {
      final Map<dynamic, dynamic> data = event as Map<dynamic, dynamic>;
      final String eventType = data['event'] as String;
      pangleLog('[Flutter Splash] Event received: $eventType');

      switch (eventType) {
        case 'onAdLoaded':
          pangleLog('[Flutter Splash] Ad loaded');
          onAdLoaded?.call();
          break;
        case 'onAdLoadFailed':
          final error =
              PangleAdError.fromJson(Map<String, dynamic>.from(data['error']));
          pangleLog(
              '[Flutter Splash] Ad load failed: ${error.code} - ${error.message}');
          onAdLoadFailed?.call(error);
          break;
        case 'onAdClicked':
          pangleLog('[Flutter Splash] Ad clicked');
          onAdClicked?.call();
          break;
        case 'onAdSkipped':
          pangleLog('[Flutter Splash] Ad skipped');
          onAdSkipped?.call();
          break;
        case 'onAdDismissed':
          pangleLog('[Flutter Splash] Ad dismissed');
          onAdDismissed?.call();
          break;
      }
    });
  }

  Future<void> load() async {
    try {
      pangleLog('[Flutter Splash] Loading ad with slotId: $slotId');
      await _channel.invokeMethod('loadSplashAd', {
        'slotId': slotId,
        'timeout': timeout,
      });
      pangleLog('[Flutter Splash] Load method called successfully');
    } catch (e) {
      pangleLog('[Flutter Splash] Load method failed: $e');
      onAdLoadFailed?.call(PangleAdError(code: -1, message: e.toString()));
    }
  }
}
