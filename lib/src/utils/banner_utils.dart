import 'package:flutter/material.dart';

import '../../multi_ads.dart';
import '../google_ads/google_ads_service/google_banner_ad.dart';
import '../pangle_global/banner_ad_widget.dart';
import '../pangle_global/models/ad_error.dart';
import 'init_utils.dart';

class BannerUtils {
  static AdPlatform _currentAdPlatform = AdPlatform.google;
  static String _adUnitId = '';
  static Function? _onAdShowedHandle;
  static Function? _onAdFailedToShowHandle;
  static Function? _onAdDismissHandle;
  static Function? _onAdClickedHandle;
  static Function? _onAdLoadedRefresh;

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
    _onAdShowedHandle = onAdShowedHandle;
    _onAdFailedToShowHandle = onAdFailedToShowHandle;
    _onAdDismissHandle = onAdDismissHandle;
    _onAdClickedHandle = onAdClickedHandle;
    _onAdLoadedRefresh = onAdLoadedRefresh;

    if (adPlatform == AdPlatform.google) {
      await GoogleBannerAd.load(
        context,
        adUnitId,
        onAdShowedHandle: onAdShowedHandle,
        onAdFailedToShowHandle: onAdFailedToShowHandle,
        onAdDismissHandle: onAdDismissHandle,
        onAdClickedHandle: onAdClickedHandle,
        onAdLoadedRefresh: onAdLoadedRefresh,
      );
    }
  }

  static Widget buildWidget() {
    if (_currentAdPlatform == AdPlatform.google) {
      return GoogleBannerAd.buildWidget();
    } else if (_currentAdPlatform == AdPlatform.pangleGlobal) {
      return PangleBannerAdWidget(
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
    return const SizedBox.shrink();
  }

  static void dispose() {
    if (_currentAdPlatform == AdPlatform.google) {
      GoogleBannerAd.dispose();
    }
    _adUnitId = '';
    _onAdShowedHandle = null;
    _onAdFailedToShowHandle = null;
    _onAdDismissHandle = null;
    _onAdClickedHandle = null;
    _onAdLoadedRefresh = null;
  }
}
