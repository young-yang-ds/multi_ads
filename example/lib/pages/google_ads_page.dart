import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:multi_ads/multi_ads.dart';

import '../google_service.dart';
import 'demo_webview_page.dart';

class GoogleAdsPage extends StatefulWidget {
  const GoogleAdsPage({super.key});

  @override
  State<GoogleAdsPage> createState() => _GoogleAdsPageState();
}

class _GoogleAdsPageState extends State<GoogleAdsPage> {
  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => const DemoWebviewPage(
      //       url: 'https://www.baidu.com',
      //     ),
      //   ),
      // );

      GoogleService().bannerLoad(
        context,
        onAdLoadedRefresh: () {
          if (mounted) setState(() {});
        },
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google ads')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      GoogleService().openShow();
                    },
                    child: const Text('Load Open Ad'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      GoogleService().interstitialStart();
                    },
                    child: const Text('Load Interstitial Ad'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DemoWebviewPage(
                            url: 'https://www.baidu.com',
                          ),
                        ),
                      );
                    },
                    child: const Text('baidu'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          GoogleBannerAd.buildWidget(),
        ],
      ),
    );
  }
}
