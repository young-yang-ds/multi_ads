import 'package:flutter/material.dart';
import 'package:multi_ads/multi_ads.dart';

import '../ad_config.dart';

class GoogleNativeAdsPage extends StatelessWidget {
  const GoogleNativeAdsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Native Ads')),
      body: Column(
        children: [
          const Expanded(
            child: Center(
              child: Text('Google Native Ad Demo', style: TextStyle(fontSize: 16)),
            ),
          ),
          NativeAdWidget(
            adUnitId: GoogleAdConfig.nativeId,
            adPlatform: AdPlatform.google,
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
            onAdLoaded: () => debugPrint('Google native ad loaded'),
            onAdFailed: (error) => debugPrint('Google native ad failed: $error'),
            onAdClicked: () => debugPrint('Google native ad clicked'),
          ),
        ],
      ),
    );
  }
}
