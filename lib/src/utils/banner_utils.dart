import 'package:flutter/material.dart';

import '../../multi_ads.dart';

class BannerUtils {
  static AdPlatform _currentAdPlatform = AdPlatform.google;
  static String _adUnitId = '';
  static Function? _onAdFailedToShowHandle;
  static Function? _onAdClickedHandle;
  static Function? _onAdLoadedRefresh;
  static Widget? _cachedWidget;
  static bool _isAdLoaded = false;

  static Future<void> load(
      BuildContext context,
      String adUnitId,
      AdPlatform adPlatform, {
        Function? onAdShowedHandle,
        Function? onAdFailedToShowHandle,
        Function? onAdDismissHandle,
        Function? onAdClickedHandle,
        Function? onAdLoadedRefresh,
      }) async {
    _currentAdPlatform = adPlatform;
    _adUnitId = adUnitId;
    _onAdFailedToShowHandle = onAdFailedToShowHandle;
    _onAdClickedHandle = onAdClickedHandle;
    _onAdLoadedRefresh = onAdLoadedRefresh;
    _cachedWidget = null;
    _isAdLoaded = false;

    if (adPlatform == AdPlatform.google) {
      await GoogleBannerAd.load(
        context,
        adUnitId,
        onAdShowedHandle: onAdShowedHandle,
        onAdFailedToShowHandle: () {
          _isAdLoaded = false;
          onAdFailedToShowHandle?.call();
        },
        onAdDismissHandle: onAdDismissHandle,
        onAdClickedHandle: onAdClickedHandle,
        onAdLoadedRefresh: () {
          _isAdLoaded = true;
          onAdLoadedRefresh?.call();
        },
      );
    }
  }

  static Widget buildWidget() {
    if (_currentAdPlatform == AdPlatform.google && !_isAdLoaded) {
      return const SizedBox.shrink();
    }

    if (_cachedWidget != null) {
      return _cachedWidget!;
    }

    if (_currentAdPlatform == AdPlatform.google) {
      _cachedWidget = GoogleBannerAd.buildWidget();
    } else if (_currentAdPlatform == AdPlatform.pangleGlobal) {
      _cachedWidget = PangleBannerAdWidget(
        slotId: _adUnitId,
        adSize: BannerAdSize.anchoredAdaptive,
        onAdLoaded: () {
          _onAdLoadedRefresh?.call();
        },
        onAdLoadFailed: (PangleAdError error) {
          _onAdFailedToShowHandle?.call();
        },
        onAdClicked: () {
          _onAdClickedHandle?.call();
        },
      );
    }

    return _cachedWidget ?? const SizedBox.shrink();
  }

  static void dispose() {
    if (_currentAdPlatform == AdPlatform.google) {
      GoogleBannerAd.dispose();
    }
    _adUnitId = '';
    _onAdFailedToShowHandle = null;
    _onAdClickedHandle = null;
    _onAdLoadedRefresh = null;
    _cachedWidget = null;
    _isAdLoaded = false;
  }
}
