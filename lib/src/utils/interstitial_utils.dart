import '../google_ads/google_ads_service/google_interstitial_ad.dart';
import '../pangle_global/interstitial_ad.dart';
import 'log_utils.dart';

class InterstitialUtils {
  static bool _isLooping = false;
  static int _currentAdType = 0;
  static PangleInterstitialAd? _pangleAd;

  // adType
  // 0:google  1:pga
  static void start(
    String adUnitId,
    int adType,
    int displayInterval, {
    Function? onAdShowedHandle,
    Function? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
    Function? onAdImpressionHandle,
  }) {
    if (_isLooping) return;
    LogUtils.log('Inter ad start, adType: $adType', tag: 'interstitial');

    _isLooping = true;
    _currentAdType = adType;
    _loadAndShow(
      adUnitId,
      adType,
      displayInterval,
      onAdShowedHandle: onAdShowedHandle,
      onAdFailedToShowHandle: onAdFailedToShowHandle,
      onAdDismissHandle: onAdDismissHandle,
      onAdClickedHandle: onAdClickedHandle,
      onAdImpressionHandle: onAdImpressionHandle,
    );
  }

  static void stop() {
    _isLooping = false;
    if (_currentAdType == 0) {
      GoogleInterstitialAd.dispose();
    } else {
      _pangleAd = null;
    }
  }

  static void _loadAndShow(
    String adUnitId,
    int adType,
    int displayInterval, {
    Function? onAdShowedHandle,
    Function? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
    Function? onAdImpressionHandle,
  }) {
    if (!_isLooping) return;

    if (adType == 0) {
      _loadAndShowGoogle(
        adUnitId,
        displayInterval,
        onAdShowedHandle: onAdShowedHandle,
        onAdFailedToShowHandle: onAdFailedToShowHandle,
        onAdDismissHandle: onAdDismissHandle,
        onAdClickedHandle: onAdClickedHandle,
        onAdImpressionHandle: onAdImpressionHandle,
      );
    } else if (adType == 1) {
      _loadAndShowPangle(
        adUnitId,
        displayInterval,
        onAdShowedHandle: onAdShowedHandle,
        onAdFailedToShowHandle: onAdFailedToShowHandle,
        onAdDismissHandle: onAdDismissHandle,
        onAdClickedHandle: onAdClickedHandle,
      );
    }
  }

  static void _loadAndShowGoogle(
    String adUnitId,
    int displayInterval, {
    Function? onAdShowedHandle,
    Function? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
    Function? onAdImpressionHandle,
  }) {
    GoogleInterstitialAd.load(
      adUnitId,
      onAdLoadedHandle: () {
        GoogleInterstitialAd.show(
          onAdShowedHandle: onAdShowedHandle,
          onAdFailedToShowHandle: () {
            onAdFailedToShowHandle?.call();
            _scheduleNext(
              adUnitId,
              0,
              displayInterval,
              onAdShowedHandle: onAdShowedHandle,
              onAdFailedToShowHandle: onAdFailedToShowHandle,
              onAdDismissHandle: onAdDismissHandle,
              onAdClickedHandle: onAdClickedHandle,
              onAdImpressionHandle: onAdImpressionHandle,
            );
          },
          onAdDismissHandle: () {
            onAdDismissHandle?.call();
            _scheduleNext(
              adUnitId,
              0,
              displayInterval,
              onAdShowedHandle: onAdShowedHandle,
              onAdFailedToShowHandle: onAdFailedToShowHandle,
              onAdDismissHandle: onAdDismissHandle,
              onAdClickedHandle: onAdClickedHandle,
              onAdImpressionHandle: onAdImpressionHandle,
            );
          },
          onAdClickedHandle: onAdClickedHandle,
          onAdImpressionHandle: onAdImpressionHandle,
        );
      },
      onAdFailedToLoadHandle: () {
        onAdFailedToShowHandle?.call();
        _scheduleNext(
          adUnitId,
          0,
          displayInterval,
          onAdShowedHandle: onAdShowedHandle,
          onAdFailedToShowHandle: onAdFailedToShowHandle,
          onAdDismissHandle: onAdDismissHandle,
          onAdClickedHandle: onAdClickedHandle,
          onAdImpressionHandle: onAdImpressionHandle,
        );
      },
    );
  }

  static void _loadAndShowPangle(
    String adUnitId,
    int displayInterval, {
    Function? onAdShowedHandle,
    Function? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
  }) {
    _pangleAd = PangleInterstitialAd(
      slotId: adUnitId,
      onAdLoaded: () {
        _pangleAd?.show();
      },
      onAdLoadFailed: (error) {
        onAdFailedToShowHandle?.call();
        _scheduleNext(
          adUnitId,
          1,
          displayInterval,
          onAdShowedHandle: onAdShowedHandle,
          onAdFailedToShowHandle: onAdFailedToShowHandle,
          onAdDismissHandle: onAdDismissHandle,
          onAdClickedHandle: onAdClickedHandle,
        );
      },
      onAdShowed: () {
        onAdShowedHandle?.call();
      },
      onAdDismissed: () {
        onAdDismissHandle?.call();
        _scheduleNext(
          adUnitId,
          1,
          displayInterval,
          onAdShowedHandle: onAdShowedHandle,
          onAdFailedToShowHandle: onAdFailedToShowHandle,
          onAdDismissHandle: onAdDismissHandle,
          onAdClickedHandle: onAdClickedHandle,
        );
      },
      onAdClicked: () {
        onAdClickedHandle?.call();
      },
    );
    _pangleAd?.load();
  }

  static void _scheduleNext(
    String adUnitId,
    int adType,
    int displayInterval, {
    Function? onAdShowedHandle,
    Function? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
    Function? onAdImpressionHandle,
  }) {
    if (!_isLooping) return;
    Future.delayed(Duration(seconds: displayInterval), () {
      _loadAndShow(
        adUnitId,
        adType,
        displayInterval,
        onAdShowedHandle: onAdShowedHandle,
        onAdFailedToShowHandle: onAdFailedToShowHandle,
        onAdDismissHandle: onAdDismissHandle,
        onAdClickedHandle: onAdClickedHandle,
        onAdImpressionHandle: onAdImpressionHandle,
      );
    });
  }
}
