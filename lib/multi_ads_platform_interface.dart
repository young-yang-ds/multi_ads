import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'multi_ads_method_channel.dart';

abstract class MultiAdsPlatform extends PlatformInterface {
  /// Constructs a MultiAdsPlatform.
  MultiAdsPlatform() : super(token: _token);

  static final Object _token = Object();

  static MultiAdsPlatform _instance = MethodChannelMultiAds();

  /// The default instance of [MultiAdsPlatform] to use.
  ///
  /// Defaults to [MethodChannelMultiAds].
  static MultiAdsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MultiAdsPlatform] when
  /// they register themselves.
  static set instance(MultiAdsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
