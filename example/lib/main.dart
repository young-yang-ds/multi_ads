import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import 'dart:convert';
import 'package:multi_ads/multi_ads.dart';

import 'ad_config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pangle Ads Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isInitialized = false;
  PangleInterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _initializePangleAds();
  }

  Future<void> _initializePangleAds() async {
    // 初始化 Pangle SDK
    final config = PangleAdConfig(
      appId: AdConfig.appId,
      debug: true,
    );

    try {
      final success = await PanglePlatform.instance.initialize(config);

      if (success) {
        // 等待 SDK 完全初始化
        await Future.delayed(const Duration(seconds: 1));

        setState(() {
          _isInitialized = true;
        });
        dev.log('Pangle Ads initialized successfully');
      } else {
        dev.log('Pangle Ads initialization returned false');
      }
    } catch (e) {
      dev.log('Failed to initialize Pangle Ads: $e');
    }
  }

  void _loadSplashAd() async {
    if (!_isInitialized) {
      dev.log('Please initialize Pangle Ads first');
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    const slotId = AdConfig.openId;
    dev.log('Loading splash ad with slot ID: $slotId');

    final splashAd = PangleSplashAd(
      slotId: slotId,
      timeout: 3000,
      onAdLoaded: () {
        dev.log('✅ Splash ad loaded successfully');
      },
      onAdLoadFailed: (error) {
        dev.log('❌ Splash ad load failed: $error');
      },
      onAdClicked: () {
        dev.log('Splash ad clicked');
      },
      onAdDismissed: () {
        dev.log('Splash ad dismissed');
      },
    );

    splashAd.load();
  }

  Future<void> _loadInterstitialAd() async {
    if (!_isInitialized) {
      return;
    }

    _interstitialAd = PangleInterstitialAd(
      slotId: AdConfig.interId,
      onAdLoaded: () {
        dev.log('Interstitial ad loaded');
        _showInterstitialAd();
      },
      onAdLoadFailed: (error) {
        dev.log('Interstitial ad load failed: $error');
      },
      onAdClicked: () {
        dev.log('Interstitial ad clicked');
      },
      onAdDismissed: () {
        dev.log('Interstitial ad dismissed');
      },
      onAdShowed: () {
        dev.log('Interstitial ad showed');
      },
    );

    final success = await _interstitialAd?.load() ?? false;
    dev.log('Interstitial ad load request: ${success ? 'success' : 'failed'}');
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null) {
      return;
    }
    _interstitialAd?.show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pangle Ads Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isInitialized ? 'Pangle Ads Initialized ✓' : 'Initializing...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isInitialized ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _loadSplashAd,
              child: const Text('Load Splash Ad'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadInterstitialAd,
              child: const Text('Load Interstitial Ad'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showInterstitialAd,
              child: const Text('Show Interstitial Ad'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //       builder: (context) => const BannerDemoPage()),
                // );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Banner Load/Display Demo'),
            ),
            const SizedBox(height: 40),
            const Text(
              'Banner Ad:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_isInitialized)
              PangleBannerAdWidget(
                slotId: AdConfig.bannerId,
                adSize: BannerAdSize.anchoredAdaptive,
                // 使用锚定自适应 Banner
                onAdLoaded: () {
                  dev.log('✅ Banner ad loaded successfully');
                },
                onAdLoadFailed: (error) {
                  dev.log('❌ Banner ad load failed: $error');
                },
                onAdClicked: () {
                  dev.log('Banner ad clicked');
                },
              ),
          ],
        ),
      ),
    );
  }
}
