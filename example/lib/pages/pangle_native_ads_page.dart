import 'package:flutter/material.dart';
import 'package:multi_ads/multi_ads.dart';

import '../ad_config.dart';

class PangleNativeAdsPage extends StatefulWidget {
  const PangleNativeAdsPage({super.key});

  @override
  State<PangleNativeAdsPage> createState() => _PangleNativeAdsPageState();
}

class _PangleNativeAdsPageState extends State<PangleNativeAdsPage> {
  bool _isAdLoaded = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    final result = await PanglePlatform.instance.initialize(
      PangleAdConfig(appId: PangleAdsConfig.appId, debug: true),
    );
    debugPrint('Pangle SDK initialized: $result');
    if (result) {
      _isInitialized = true;
      _loadNativeAd();
    }
  }

  void _loadNativeAd() {
    PangleNativeAd.load(
      PangleAdsConfig.nativeId,
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
        debugPrint('Pangle native ad load failed: ${error.code} - ${error.message}');
      },
      onAdClicked: () {
        debugPrint('Pangle native ad clicked');
      },
      onAdShowed: () {
        debugPrint('Pangle native ad showed');
      },
    );
  }

  @override
  void dispose() {
    PangleNativeAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pangle Native Ads')),
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
            child: PangleNativeAd.buildWidget(),
          ),
        ],
      ),
    );
  }
}
