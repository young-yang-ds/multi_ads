import 'package:flutter_test/flutter_test.dart';
import 'package:multi_ads/multi_ads.dart';
import 'package:multi_ads/multi_ads_platform_interface.dart';
import 'package:multi_ads/multi_ads_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMultiAdsPlatform
    with MockPlatformInterfaceMixin
    implements MultiAdsPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MultiAdsPlatform initialPlatform = MultiAdsPlatform.instance;

  test('$MethodChannelMultiAds is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMultiAds>());
  });

  test('getPlatformVersion', () async {
    MultiAds multiAdsPlugin = MultiAds();
    MockMultiAdsPlatform fakePlatform = MockMultiAdsPlatform();
    MultiAdsPlatform.instance = fakePlatform;

    expect(await multiAdsPlugin.getPlatformVersion(), '42');
  });
}
