import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:multi_ads/src/log_utils.dart';

class GoogleBannerAd {
  static BannerAd? _bannerAd;
  static bool _isLoading = false;

  static Future<void> load(
    BuildContext context,
    String adUnitId, {
    Function? onAdShowed,
    Function? onAdFailedToShow,
    Function? onAdDismiss,
    Function? onAdClicked,
    Function? onAdLoadedRefresh,
  }) async {
    if (_isLoading || _bannerAd != null) return;
    _isLoading = true;
    LogUtils.log('Banner ad loading', tag: 'google ads');

    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.sizeOf(context).width.truncate(),
    );

    if (size == null) {
      _isLoading = false;
      LogUtils.log('Banner ad size null', tag: 'google ads');
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(extras: {"collapsible": "bottom"}),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) async {
          await Future.delayed(const Duration(seconds: 5));
          onAdLoadedRefresh?.call();
          _isLoading = false;
          LogUtils.log('Banner ad loaded', tag: 'google ads');
        },
        onAdClicked: (ad) {
          onAdClicked?.call();
        },
        onAdFailedToLoad: (ad, err) {
          onAdFailedToShow?.call();
          _isLoading = false;
          ad.dispose();
          _bannerAd = null;

          LogUtils.log('Banner ad load failed: $err', tag: 'google ads');
        },
        onAdClosed: (ad) {
          onAdDismiss?.call();
          LogUtils.log('banner ad dismiss', tag: 'Google_ad');
        },
        onAdOpened: (ad) {
          LogUtils.log('banner ad showed', tag: 'Google_ad');
          onAdShowed?.call();
        },
      ),
    );
    _bannerAd!.load();
  }

  static Widget buildWidget() {
    if (_bannerAd == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(key: ObjectKey(_bannerAd), ad: _bannerAd!),
    );
  }

  static void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }
}
