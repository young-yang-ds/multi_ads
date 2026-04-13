import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:multi_ads/multi_ads.dart';
import 'package:multi_ads_example/google_service.dart';
import 'package:multi_ads_example/pages/common_pages/common_page.dart';
import 'package:multi_ads_example/pages/google_ads_page.dart';
import 'package:multi_ads_example/pages/google_native_ads_page.dart';
import 'package:multi_ads_example/pages/pga_page.dart';
import 'dart:developer' as dev;

demoLog(dynamic message, {String tag = 'demo-log'}) {
  dev.log('$message', name: tag);
}

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // GoogleAdsInitialize.init().then((value) {
  //   dev.log('${value.adapterStatuses}');
  // });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pangle Ads Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
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
  @override
  void initState() {
    super.initState();

    FlutterNativeSplash.remove();
    // SchedulerBinding.instance.addPostFrameCallback((_) async {
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(builder: (context) => const CommonPage()),
    //   );
    // });

    // showGoogleOpen();
  }

  // void showGoogleOpen() {
  //   Future.delayed(Duration(seconds: 3), () {
  //     FlutterNativeSplash.remove();
  //   });
  //
  //   GoogleService().openShow();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GoogleAdsPage(),
                  ),
                );
              },
              child: const Text('Google ads'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PgaPage()),
                );
              },
              child: const Text('pga'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CommonPage()),
                );
              },
              child: const Text('Common'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GoogleNativeAdsPage(),
                  ),
                );
              },
              child: const Text('Google Native Ads'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
