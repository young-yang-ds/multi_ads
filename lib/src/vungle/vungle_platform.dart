import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'vungle_method_channel.dart';
import 'models/vungle_ad_config.dart';

/// Platform interface for Vungle Ads
abstract class VunglePlatform extends PlatformInterface {
  VunglePlatform() : super(token: _token);

  static final Object _token = Object();

  static VunglePlatform _instance = MethodChannelVungle();

  static VunglePlatform get instance => _instance;

  static set instance(VunglePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initialize the Vungle SDK
  Future<bool> initialize(VungleAdConfig config) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Check if the SDK is initialized
  Future<bool> isInitialized() {
    throw UnimplementedError('isInitialized() has not been implemented.');
  }

  /// Load an interstitial ad
  Future<bool> loadInterstitialAd({required String placementId}) {
    throw UnimplementedError('loadInterstitialAd() has not been implemented.');
  }

  /// Show an interstitial ad
  Future<void> showInterstitialAd({required String placementId}) {
    throw UnimplementedError('showInterstitialAd() has not been implemented.');
  }

  /// Check if an interstitial ad can play
  Future<bool> canPlayInterstitialAd({required String placementId}) {
    throw UnimplementedError(
      'canPlayInterstitialAd() has not been implemented.',
    );
  }

  /// Load an app open ad (uses interstitial ad type in Vungle)
  Future<bool> loadAppOpenAd({required String placementId}) {
    throw UnimplementedError('loadAppOpenAd() has not been implemented.');
  }

  /// Show an app open ad
  Future<void> showAppOpenAd({required String placementId}) {
    throw UnimplementedError('showAppOpenAd() has not been implemented.');
  }

  /// Check if an app open ad can play
  Future<bool> canPlayAppOpenAd({required String placementId}) {
    throw UnimplementedError('canPlayAppOpenAd() has not been implemented.');
  }

  /// Load a banner ad
  Future<bool> loadBannerAd({
    required String placementId,
    required int bannerSize,
    required String listenerId,
  }) {
    throw UnimplementedError('loadBannerAd() has not been implemented.');
  }

  /// Dispose a banner ad
  Future<void> disposeBannerAd({required String listenerId}) {
    throw UnimplementedError('disposeBannerAd() has not been implemented.');
  }
}
