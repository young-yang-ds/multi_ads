import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'multi_ads_platform_interface.dart';

/// An implementation of [MultiAdsPlatform] that uses method channels.
class MethodChannelMultiAds extends MultiAdsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('multi_ads');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
