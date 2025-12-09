import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:multi_ads/multi_ads.dart';
import 'package:multi_ads_example/main.dart';
import 'package:multi_ads_example/pages/common_pages/common_service.dart';

import '../../ad_config.dart';
import 'common_demo_webview_page.dart';

class CommonPage extends StatefulWidget {
  const CommonPage({super.key});

  @override
  State<CommonPage> createState() => _CommonPageState();
}

class _CommonPageState extends State<CommonPage> {
  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      CommonService().init(context, () {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Common')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      OpenUtils.loadAndShow(
                        CommonService.openId,
                        CommonService.adPlatform,
                      );
                    },
                    child: const Text('Load Open Ad'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      InterstitialUtils.start(
                        CommonService.interId,
                        CommonService.adPlatform,
                        5,
                      );
                    },
                    child: const Text('Load Interstitial Ad'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CommonDemoWebviewPage(
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
          BannerUtils.buildWidget(),
        ],
      ),
    );
  }
}
