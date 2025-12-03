import 'package:flutter/material.dart';
import 'dart:developer' as dev;

import 'package:multi_ads/multi_ads.dart';

import '../ad_config.dart';

class PgaBannersPage extends StatefulWidget {
  const PgaBannersPage({Key? key}) : super(key: key);

  @override
  State<PgaBannersPage> createState() => _PgaBannersPageState();
}

class _PgaBannersPageState extends State<PgaBannersPage> {
  PangleBannerAd? _banner320x50;
  PangleBannerAd? _banner300x250;
  PangleBannerAd? _anchoredBanner;

  String _statusText = 'Ready to load banner ads';
  bool _showBanner320x50 = false;
  bool _showBanner300x250 = false;
  bool _showAnchoredBanner = false;

  @override
  void dispose() {
    _banner320x50?.dispose();
    _banner300x250?.dispose();
    _anchoredBanner?.dispose();
    super.dispose();
  }

  Future<void> _load320x50Banner() async {
    setState(() {
      _statusText = 'Loading 320x50 Banner...';
    });

    _banner320x50 = PangleBannerAd(
      slotId: PangleAdsConfig.bannerId,
      adSize: PangleBannerAdSize.banner320x50,
      onAdLoaded: () {
        dev.log('✅ 320x50 Banner loaded successfully');
        setState(() {
          _statusText = '320x50 Banner loaded! Tap "Show" to display it.';
        });
      },
      onAdLoadFailed: (error) {
        dev.log('❌ 320x50 Banner load failed: $error');
        setState(() {
          _statusText = '320x50 Banner load failed: ${error.message}';
        });
      },
      onAdClicked: () {
        dev.log('320x50 Banner clicked');
      },
      onAdShowed: () {
        dev.log('320x50 Banner showed');
      },
      onAdDismissed: () {
        dev.log('320x50 Banner dismissed');
        setState(() {
          _showBanner320x50 = false;
        });
      },
    );

    final success = await _banner320x50!.load();
    if (!success) {
      setState(() {
        _statusText = 'Failed to start loading 320x50 Banner';
      });
    }
  }

  Future<void> _load300x250Banner() async {
    setState(() {
      _statusText = 'Loading 300x250 Banner...';
    });

    _banner300x250 = PangleBannerAd(
      slotId: PangleAdsConfig.bannerId,
      adSize: PangleBannerAdSize.banner300x250,
      onAdLoaded: () {
        dev.log('✅ 300x250 Banner loaded successfully');
        setState(() {
          _statusText = '300x250 Banner loaded! Tap "Show" to display it.';
        });
      },
      onAdLoadFailed: (error) {
        dev.log('❌ 300x250 Banner load failed: $error');
        setState(() {
          _statusText = '300x250 Banner load failed: ${error.message}';
        });
      },
      onAdClicked: () {
        dev.log('300x250 Banner clicked');
      },
    );

    final success = await _banner300x250!.load();
    if (!success) {
      setState(() {
        _statusText = 'Failed to start loading 300x250 Banner';
      });
    }
  }

  Future<void> _loadAnchoredBanner() async {
    setState(() {
      _statusText = 'Loading Anchored Adaptive Banner...';
    });

    _anchoredBanner = PangleBannerAd(
      slotId: PangleAdsConfig.bannerId,
      adSize: PangleBannerAdSize.anchoredAdaptive,
      onAdLoaded: () {
        dev.log('✅ Anchored Banner loaded successfully');
        setState(() {
          _statusText = 'Anchored Banner loaded! Tap "Show" to display it.';
        });
      },
      onAdLoadFailed: (error) {
        dev.log('❌ Anchored Banner load failed: $error');
        setState(() {
          _statusText = 'Anchored Banner load failed: ${error.message}';
        });
      },
      onAdClicked: () {
        dev.log('Anchored Banner clicked');
      },
    );

    final success = await _anchoredBanner!.load();
    if (!success) {
      setState(() {
        _statusText = 'Failed to start loading Anchored Banner';
      });
    }
  }

  Future<void> _show320x50Banner() async {
    if (_banner320x50?.isLoaded == true) {
      final success = await _banner320x50!.show();
      if (success) {
        setState(() {
          _showBanner320x50 = true;
          _statusText = '320x50 Banner is now displayed!';
        });
      }
    } else {
      setState(() {
        _statusText = '320x50 Banner is not loaded yet';
      });
    }
  }

  Future<void> _show300x250Banner() async {
    if (_banner300x250?.isLoaded == true) {
      final success = await _banner300x250!.show();
      if (success) {
        setState(() {
          _showBanner300x250 = true;
          _statusText = '300x250 Banner is now displayed!';
        });
      }
    } else {
      setState(() {
        _statusText = '300x250 Banner is not loaded yet';
      });
    }
  }

  Future<void> _displayAnchoredBanner() async {
    if (_anchoredBanner?.isLoaded == true) {
      final success = await _anchoredBanner!.show();
      if (success) {
        setState(() {
          _showAnchoredBanner = true;
          _statusText = 'Anchored Banner is now displayed!';
        });
      }
    } else {
      setState(() {
        _statusText = 'Anchored Banner is not loaded yet';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Banner Load/Display Demo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                _statusText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // 320x50 Banner Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '320x50 Banner',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _load320x50Banner,
                            child: const Text('Load'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _banner320x50?.isLoaded == true
                                ? _show320x50Banner
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Show'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_showBanner320x50 && _banner320x50 != null)
                      PangleBannerAdContainer(bannerAd: _banner320x50!),
                  ],
                ),
              ),
            ),

            // 300x250 Banner Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '300x250 Banner',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _load300x250Banner,
                            child: const Text('Load'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _banner300x250?.isLoaded == true
                                ? _show300x250Banner
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Show'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_showBanner300x250 && _banner300x250 != null)
                      PangleBannerAdContainer(bannerAd: _banner300x250!),
                  ],
                ),
              ),
            ),

            // Anchored Banner Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Anchored Adaptive Banner',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _loadAnchoredBanner,
                            child: const Text('Load'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _anchoredBanner?.isLoaded == true
                                ? _displayAnchoredBanner
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Show'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_showAnchoredBanner && _anchoredBanner != null)
                      PangleBannerAdContainer(bannerAd: _anchoredBanner!),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
