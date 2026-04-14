import 'package:flutter/material.dart';
import 'package:multi_ads/multi_ads.dart';

import '../ad_config.dart';

class PangleNativeAdsPage extends StatefulWidget {
  const PangleNativeAdsPage({super.key});

  @override
  State<PangleNativeAdsPage> createState() => _PangleNativeAdsPageState();
}

class _PangleNativeAdsPageState extends State<PangleNativeAdsPage> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initSdk();
  }

  Future<void> _initSdk() async {
    final result = await PanglePlatform.instance.initialize(
      PangleAdConfig(appId: PangleAdsConfig.appId, debug: true),
    );
    debugPrint('Pangle SDK initialized: $result');
    if (result && mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pangle Native Ads')),
      body: Column(
        children: [
          const Expanded(
            child: Center(
              child: Text('Pangle Native Ad Demo', style: TextStyle(fontSize: 16)),
            ),
          ),
          if (_isInitialized)
            NativeAdWidget(
              adUnitId: PangleAdsConfig.nativeId,
              adPlatform: AdPlatform.pangleGlobal,
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
              onAdLoaded: () => debugPrint('Pangle native ad loaded'),
              onAdFailed: (error) => debugPrint('Pangle native ad failed: $error'),
              onAdClicked: () => debugPrint('Pangle native ad clicked'),
            )
          else
            const SizedBox(height: 80),
        ],
      ),
    );
  }
}
