import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'pangle_method_channel.dart';
import 'models/ad_config.dart';

abstract class PanglePlatform extends PlatformInterface {
  PanglePlatform() : super(token: _token);

  static final Object _token = Object();

  static PanglePlatform _instance = MethodChannelPangle();

  static PanglePlatform get instance => _instance;

  static set instance(PanglePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> initialize(PangleAdConfig config) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<void> loadSplashAd({
    required String slotId,
    required int timeout,
  }) {
    throw UnimplementedError('loadSplashAd() has not been implemented.');
  }

  Future<bool> loadInterstitialAd({
    required String slotId,
  }) {
    throw UnimplementedError('loadInterstitialAd() has not been implemented.');
  }

  Future<void> showInterstitialAd() {
    throw UnimplementedError('showInterstitialAd() has not been implemented.');
  }

  Future<bool> loadBannerAd({
    required String slotId,
    required int adSize,
    required String listenerId,
  }) {
    throw UnimplementedError('loadBannerAd() has not been implemented.');
  }

  Future<bool> showBannerAd({
    required String listenerId,
  }) {
    throw UnimplementedError('showBannerAd() has not been implemented.');
  }

  Future<void> hideBannerAd({
    required String listenerId,
  }) {
    throw UnimplementedError('hideBannerAd() has not been implemented.');
  }

  Future<void> disposeBannerAd({
    required String listenerId,
  }) {
    throw UnimplementedError('disposeBannerAd() has not been implemented.');
  }
}
