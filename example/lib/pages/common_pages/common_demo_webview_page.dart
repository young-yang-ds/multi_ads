import 'package:flutter/scheduler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:flutter/material.dart';
import 'package:multi_ads/multi_ads.dart';

import '../../google_service.dart';
import 'common_service.dart';

class CommonDemoWebviewPage extends StatefulWidget {
  const CommonDemoWebviewPage({super.key, required this.url});

  final String url;

  @override
  State<CommonDemoWebviewPage> createState() => _DemoWebviewPageState();
}

class _DemoWebviewPageState extends State<CommonDemoWebviewPage> {
  InAppWebViewController? inAppWebViewController;
  InAppWebViewSettings inAppWebViewSettings = InAppWebViewSettings(
    iframeAllow: "camera; microphone",
    useShouldOverrideUrlLoading: true,
    allowsInlineMediaPlayback: true,
    mediaPlaybackRequiresUserGesture: false,
    transparentBackground: true,
    iframeAllowFullscreen: true,

    /// TODO：UA标识，这个一定要加
    applicationNameForUserAgent:
        "${CommonService.appName}/${CommonService.appVersion}",
  );
  final globalKey = GlobalKey();

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
      appBar: AppBar(title: Text('')),
      body: Column(
        children: [
          Expanded(
            child: InAppWebView(
              key: globalKey,
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialSettings: inAppWebViewSettings,
              onWebViewCreated: (controller) async {
                inAppWebViewController = controller;
              },
              onLoadStop: (controller, url) async {},
              onPermissionRequest: (controller, request) async {
                return PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.GRANT,
                );
              },
              onProgressChanged: (controller, progress) {},
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                var uri = navigationAction.request.url!;
                if (![
                  "javascript",
                  "http",
                  "file",
                  "chrome",
                  "https",
                  "data",
                  "about",
                ].contains(uri.scheme)) {
                  // if (await canLaunchUrl(uri)) {
                  //   await launchUrl(
                  //     uri,
                  //   );
                  //   return NavigationActionPolicy.CANCEL;
                  // }
                }
                return NavigationActionPolicy.ALLOW;
              },
            ),
          ),
          /// Banner Widget
          BannerUtils.buildWidget(),
        ],
      ),
    );
  }
}
