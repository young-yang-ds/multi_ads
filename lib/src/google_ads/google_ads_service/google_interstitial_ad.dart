import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../log_utils.dart';

class GoogleInterstitialAd {
  static InterstitialAd? _interstitialAd;
  static bool _isLoading = false;
  static bool _isLooping = false;

  static void start(
    String adUnitId,
    int displayInterval, {
    Function? onAdShowedHandle,
    Function? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
  }) {
    if (_isLooping) return;
    LogUtils.log('Inter ad start', tag: 'google ads');

    _isLooping = true;
    _loadAndShow(
      adUnitId,
      displayInterval,
      onAdShowedHandle: onAdShowedHandle,
      onAdFailedToShowHandle: onAdFailedToShowHandle,
      onAdDismissHandle: onAdDismissHandle,
      onAdClickedHandle: onAdClickedHandle,
    );
  }

  static void stop() {
    _isLooping = false;
    _isLoading = false;
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

  static void _loadAndShow(
    String adUnitId,
    int displayInterval, {
    Function? onAdShowedHandle,
    Function? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
  }) {
    if (!_isLooping || _isLoading) return;
    _isLoading = true;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _isLoading = false;
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              onAdShowedHandle?.call();

              LogUtils.log('Inter ad showed', tag: 'google ads');
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              onAdFailedToShowHandle?.call();
              ad.dispose();
              _interstitialAd = null;
              _scheduleNext(
                adUnitId,
                displayInterval,
                onAdShowedHandle: onAdShowedHandle,
              );

              LogUtils.log('Inter ad failed show: $err', tag: 'google ads');
            },
            onAdDismissedFullScreenContent: (ad) {
              onAdDismissHandle?.call();
              ad.dispose();
              _interstitialAd = null;
              _scheduleNext(
                adUnitId,
                displayInterval,
                onAdShowedHandle: onAdShowedHandle,
              );

              LogUtils.log('Inter ad dismiss', tag: 'google ads');
            },
            onAdImpression: (ad) {},
            onAdClicked: (ad) {
              onAdClickedHandle?.call();
            },
          );
          _interstitialAd?.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          onAdFailedToShowHandle?.call();
          _isLoading = false;
          _scheduleNext(
            adUnitId,
            displayInterval,
            onAdShowedHandle: onAdShowedHandle,
          );

          LogUtils.log('Inter ad load failed: $error', tag: 'google ads');
        },
      ),
    );
  }

  static void _scheduleNext(
    String adUnitId,
    int displayInterval, {
    Function? onAdShowedHandle,
    Function? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
  }) {
    if (!_isLooping) return;
    Future.delayed(Duration(seconds: displayInterval), () {
      _loadAndShow(
        adUnitId,
        displayInterval,
        onAdShowedHandle: onAdShowedHandle,
        onAdFailedToShowHandle: onAdFailedToShowHandle,
        onAdDismissHandle: onAdDismissHandle,
        onAdClickedHandle: onAdClickedHandle,
      );
    });
  }
}
