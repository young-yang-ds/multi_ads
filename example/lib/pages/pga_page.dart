import 'package:flutter/material.dart';
import 'package:multi_ads/multi_ads.dart';
import 'package:multi_ads_example/ad_config.dart';
import 'package:multi_ads_example/pages/pga_banners_page.dart';

class PgaPage extends StatefulWidget {
  const PgaPage({super.key});

  @override
  State<PgaPage> createState() => _PgaPageState();
}

class _PgaPageState extends State<PgaPage> {
  bool _isInitialized = false;
  PangleInterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();

    _initializePangleAds();
  }

  Future<void> _initializePangleAds() async {
    final config = PangleAdConfig(appId: PangleAdsConfig.appId, debug: false);

    try {
      final success = await PanglePlatform.instance.initialize(config);

      if (success) {
        setState(() {
          _isInitialized = true;
        });
      } else {}
    } catch (e) {}
  }

  void _loadSplashAd() async {
    if (!_isInitialized) {
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    const slotId = PangleAdsConfig.openId;

    final splashAd = PangleSplashAd(
      slotId: slotId,
      timeout: 3000,
      onAdLoaded: () {},
      onAdLoadFailed: (error) {},
      onAdClicked: () {},
      onAdDismissed: () {},
    );

    splashAd.load();
  }

  Future<void> _loadInterstitialAd() async {
    if (!_isInitialized) {
      return;
    }

    _interstitialAd = PangleInterstitialAd(
      slotId: PangleAdsConfig.interId,
      onAdLoaded: () {
        _showInterstitialAd();
      },
      onAdLoadFailed: (error) {},
      onAdClicked: () {},
      onAdDismissed: () {},
      onAdShowed: () {},
    );

    final success = await _interstitialAd?.load() ?? false;
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null) {
      return;
    }
    _interstitialAd?.show();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pangle Ads Demo')),
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
              // onPressed: _loadInterstitialAd,
              onPressed: () {
                InterstitialUtils.start(
                  PangleAdsConfig.interId,
                  AdPlatform.pangleGlobal,
                  5,
                );
              },
              child: const Text('Show Interstitial Ad'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PgaBannersPage(),
                  ),
                );
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
                slotId: PangleAdsConfig.bannerId,
                adSize: BannerAdSize.anchoredAdaptive,
                // 使用锚定自适应 Banner
                onAdLoaded: () {},
                onAdLoadFailed: (error) {},
                onAdClicked: () {},
              ),
          ],
        ),
      ),
    );
  }
}
