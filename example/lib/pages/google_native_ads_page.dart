import 'package:flutter/material.dart';
import 'package:multi_ads/multi_ads.dart';

import '../ad_config.dart';

class GoogleNativeAdsPage extends StatefulWidget {
  const GoogleNativeAdsPage({super.key});

  @override
  State<GoogleNativeAdsPage> createState() => _GoogleNativeAdsPageState();
}

class _GoogleNativeAdsPageState extends State<GoogleNativeAdsPage> {
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    GoogleNativeAd.load(
      GoogleAdConfig.nativeId,
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
      onAdLoadedRefresh: () {
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
          });
        }
      },
      onAdFailedToLoadHandle: (code, message) {
        debugPrint('Native ad load failed: $code - $message');
      },
      onAdClickedHandle: () {
        debugPrint('Native ad clicked');
      },
      onAdImpressionHandle: () {
        debugPrint('Native ad impression');
      },
    );
  }

  @override
  void dispose() {
    GoogleNativeAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Native Ads')),
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
            child: GoogleNativeAd.buildWidget(),
          ),
        ],
      ),
    );
  }
}
