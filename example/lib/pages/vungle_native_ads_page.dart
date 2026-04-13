import 'package:flutter/material.dart';
import 'package:multi_ads/multi_ads.dart';

import '../ad_config.dart';

class VungleNativeAdsPage extends StatefulWidget {
  const VungleNativeAdsPage({super.key});

  @override
  State<VungleNativeAdsPage> createState() => _VungleNativeAdsPageState();
}

class _VungleNativeAdsPageState extends State<VungleNativeAdsPage> {
  bool _isAdLoaded = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    final result = await VunglePlatform.instance.initialize(
      VungleAdConfig(appId: VungleAdsConfig.appId, debug: true),
    );
    debugPrint('Vungle SDK initialized: $result');
    if (result) {
      _isInitialized = true;
      _loadNativeAd();
    }
  }

  void _loadNativeAd() {
    VungleNativeAd.load(
      VungleAdsConfig.nativeId,
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
      ),
      onAdLoaded: () {
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
          });
        }
      },
      onAdLoadFailed: (error) {
        debugPrint('Vungle native ad load failed: ${error.code} - ${error.message}');
      },
      onAdClicked: () {
        debugPrint('Vungle native ad clicked');
      },
      onAdImpression: () {
        debugPrint('Vungle native ad impression');
      },
    );
  }

  @override
  void dispose() {
    VungleNativeAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vungle Native Ads')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                _isAdLoaded ? 'Native Ad Loaded' : 'Loading...',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            child: VungleNativeAd.buildWidget(),
          ),
        ],
      ),
    );
  }
}
