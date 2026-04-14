import 'package:flutter/material.dart';
import 'package:multi_ads/multi_ads.dart';

import '../ad_config.dart';

class VungleNativeAdsPage extends StatefulWidget {
  const VungleNativeAdsPage({super.key});

  @override
  State<VungleNativeAdsPage> createState() => _VungleNativeAdsPageState();
}

class _VungleNativeAdsPageState extends State<VungleNativeAdsPage> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initSdk();
  }

  Future<void> _initSdk() async {
    final result = await VunglePlatform.instance.initialize(
      VungleAdConfig(appId: VungleAdsConfig.appId, debug: true),
    );
    debugPrint('Vungle SDK initialized: $result');
    if (result && mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vungle Native Ads')),
      body: Column(
        children: [
          const Expanded(
            child: Center(
              child: Text('Vungle Native Ad Demo', style: TextStyle(fontSize: 16)),
            ),
          ),
          if (_isInitialized)
            NativeAdWidget(
              adUnitId: VungleAdsConfig.nativeId,
              adPlatform: AdPlatform.vungle,
              style: const NativeAdStyle(
                height: 80,
                imageWidth: 120,
                titleFontSize: 14,
                titleColor: Color(0xFF202124),
                titleMaxLines: 2,
                bodyFontSize: 10,
                bodyColor: Color(0xFF999999),
                backgroundColor: Color(0xFFFFFFFF),
                cornerRadius: 10,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              ),
              placeholder: const SizedBox(height: 80),
              onAdLoaded: () => debugPrint('Vungle native ad loaded'),
              onAdFailed: (error) => debugPrint('Vungle native ad failed: $error'),
              onAdClicked: () => debugPrint('Vungle native ad clicked'),
            )
          else
            const SizedBox(height: 80),
        ],
      ),
    );
  }
}
