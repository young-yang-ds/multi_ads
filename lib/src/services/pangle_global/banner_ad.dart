import 'package:flutter/services.dart';
import 'models/ad_error.dart';
import 'pangle_method_channel.dart';
import 'pangle_platform.dart';

enum PangleBannerAdSize {
  banner320x50,
  banner300x250,
  banner728x90,
  anchoredAdaptive,
}

class _BannerAdCallbackManager {
  static final _BannerAdCallbackManager _instance =
      _BannerAdCallbackManager._internal();

  factory _BannerAdCallbackManager() => _instance;

  static const MethodChannel _channel = MethodChannel('multi_ads/pangle_global');
  final Map<String, PangleBannerAd> _listeners = {};
  bool _isInitialized = false;

  _BannerAdCallbackManager._internal();

  void register(PangleBannerAd ad) {
    _listeners[ad.listenerId] = ad;
    _ensureInitialized();
  }

  void unregister(String listenerId) {
    _listeners.remove(listenerId);
  }

  void _ensureInitialized() {
    if (_isInitialized) return;
    _isInitialized = true;

    _channel.setMethodCallHandler((call) async {
      pangleLog('[BannerAdManager] Received method call: ${call.method}');

      final args = call.arguments as Map?;
      final listenerId = args?['listenerId'] as String?;

      if (listenerId == null) {
        pangleLog('[BannerAdManager] No listenerId in callback');
        return;
      }

      final ad = _listeners[listenerId];
      if (ad == null) {
        pangleLog('[BannerAdManager] No listener found for: $listenerId');
        return;
      }

      switch (call.method) {
        case 'onBannerAdLoaded':
          ad._handleLoaded();
          break;
        case 'onBannerAdLoadFailed':
          final error = PangleAdError.fromJson(
            Map<String, dynamic>.from(args!['error'] as Map),
          );
          ad._handleLoadFailed(error);
          break;
        case 'onBannerAdClicked':
          ad._handleClicked();
          break;
        case 'onBannerAdShowed':
          ad._handleShowed();
          break;
        case 'onBannerAdDismissed':
          ad._handleDismissed();
          break;
        default:
          pangleLog('[BannerAdManager] Unknown method: ${call.method}');
      }
    });
  }
}

class PangleBannerAd {
  final String slotId;
  final PangleBannerAdSize adSize;
  final Function()? onAdLoaded;
  final Function(PangleAdError error)? onAdLoadFailed;
  final Function()? onAdClicked;
  final Function()? onAdShowed;
  final Function()? onAdDismissed;

  late final String _listenerId;
  bool _isLoaded = false;
  bool _isLoading = false;

  PangleBannerAd({
    required this.slotId,
    this.adSize = PangleBannerAdSize.banner320x50,
    this.onAdLoaded,
    this.onAdLoadFailed,
    this.onAdClicked,
    this.onAdShowed,
    this.onAdDismissed,
  }) {
    _listenerId = '${slotId}_${DateTime.now().millisecondsSinceEpoch}';
    _BannerAdCallbackManager().register(this);
  }

  void _handleLoaded() {
    _isLoaded = true;
    _isLoading = false;
    pangleLog(
        '[PangleBannerAd] Ad loaded successfully - listenerId: $_listenerId');
    onAdLoaded?.call();
  }

  void _handleLoadFailed(PangleAdError error) {
    _isLoading = false;
    pangleLog(
        '[PangleBannerAd] Ad load failed: ${error.code} - ${error.message}');
    onAdLoadFailed?.call(error);
  }

  void _handleClicked() {
    pangleLog('[PangleBannerAd] Ad clicked');
    onAdClicked?.call();
  }

  void _handleShowed() {
    pangleLog('[PangleBannerAd] Ad showed');
    onAdShowed?.call();
  }

  void _handleDismissed() {
    pangleLog('[PangleBannerAd] Ad dismissed');
    onAdDismissed?.call();
  }

  Future<bool> load() async {
    if (_isLoading) {
      pangleLog('[PangleBannerAd] Banner ad is already loading');
      return false;
    }

    if (_isLoaded) {
      pangleLog('[PangleBannerAd] Banner ad is already loaded');
      return true;
    }

    _isLoading = true;
    pangleLog(
        '[PangleBannerAd] Loading banner ad - slotId: $slotId, size: $adSize');

    try {
      final result = await PanglePlatform.instance.loadBannerAd(
        slotId: slotId,
        adSize: adSize.index,
        listenerId: _listenerId,
      );

      return result;
    } catch (e) {
      _isLoading = false;
      pangleLog('[PangleBannerAd] Failed to load banner ad: $e');
      return false;
    }
  }

  Future<bool> show() async {
    if (!_isLoaded) {
      pangleLog('[PangleBannerAd] Banner ad is not loaded yet');
      return false;
    }

    pangleLog('[PangleBannerAd] Showing banner ad');

    try {
      final result = await PanglePlatform.instance.showBannerAd(
        listenerId: _listenerId,
      );

      return result;
    } catch (e) {
      pangleLog('[PangleBannerAd] Failed to show banner ad: $e');
      return false;
    }
  }

  Future<void> hide() async {
    pangleLog('[PangleBannerAd] Hiding banner ad');

    try {
      await PanglePlatform.instance.hideBannerAd(
        listenerId: _listenerId,
      );
    } catch (e) {
      pangleLog('[PangleBannerAd] Failed to hide banner ad: $e');
    }
  }

  Future<void> dispose() async {
    pangleLog('[PangleBannerAd] Disposing banner ad');

    try {
      await PanglePlatform.instance.disposeBannerAd(
        listenerId: _listenerId,
      );
    } catch (e) {
      pangleLog('[PangleBannerAd] Failed to dispose banner ad: $e');
    }

    _BannerAdCallbackManager().unregister(_listenerId);

    _isLoaded = false;
    _isLoading = false;
  }

  bool get isLoaded => _isLoaded;

  bool get isLoading => _isLoading;

  String get listenerId => _listenerId;
}
