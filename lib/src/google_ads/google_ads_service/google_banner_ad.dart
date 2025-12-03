import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:multi_ads/src/log_utils.dart';

class GoogleBannerAd {
  static BannerAd? _bannerAd;
  static bool _isLoading = false;

  static Future<void> load(
    BuildContext context,
    String adUnitId, {
    Function? onAdShowedHandle,
    Function? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
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
          // await Future.delayed(const Duration(seconds: 2));
          onAdLoadedRefresh?.call();

          _isLoading = false;
          LogUtils.log('Banner ad loaded', tag: 'google ads');
        },
        onAdClicked: (ad) {
          onAdClickedHandle?.call();
        },
        onAdFailedToLoad: (ad, err) {
          onAdFailedToShowHandle?.call();
          _isLoading = false;
          ad.dispose();
          _bannerAd = null;

          LogUtils.log('Banner ad load failed: $err', tag: 'google ads');
        },
        onAdClosed: (ad) {
          onAdDismissHandle?.call();
          LogUtils.log('banner ad dismiss', tag: 'Google_ads');
        },
        onAdOpened: (ad) {
          LogUtils.log('banner ad showed', tag: 'Google_ads');
          onAdShowedHandle?.call();
        },
      ),
    );
    _bannerAd!.load();
  }

  static Widget buildWidget() {
    if (_bannerAd == null) {
      return const SizedBox.shrink();
    }
    return _BannerAdWidget(bannerAd: _bannerAd!);
  }

  static void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }
}

class _BannerAdWidget extends StatefulWidget {
  final BannerAd bannerAd;

  const _BannerAdWidget({required this.bannerAd});

  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  static _BannerAdWidgetState? _currentOwner;
  bool _isOwner = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _tryClaimOwnership();
      }
    });
  }

  @override
  void dispose() {
    if (_currentOwner == this) {
      _currentOwner = null;
    }
    super.dispose();
  }

  void _tryClaimOwnership() {
    if (!mounted) return;

    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;

    if (isCurrentRoute && !_isOwner) {
      if (_currentOwner == null || !_currentOwner!.mounted) {
        _currentOwner = this;
        setState(() {
          _isOwner = true;
        });
      } else if (_currentOwner != this) {
        final oldOwner = _currentOwner!;
        _currentOwner = this;

        oldOwner._releaseOwnership();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
            setState(() {
              _isOwner = true;
            });
          }
        });
      }
    } else if (!isCurrentRoute && _isOwner) {
      _releaseOwnership();
    }
  }

  void _releaseOwnership() {
    if (_isOwner && mounted) {
      if (_currentOwner == this) {
        _currentOwner = null;
      }
      setState(() {
        _isOwner = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOwner) {
      return SizedBox(
        width: widget.bannerAd.size.width.toDouble(),
        height: widget.bannerAd.size.height.toDouble(),
      );
    }
    return SizedBox(
      width: widget.bannerAd.size.width.toDouble(),
      height: widget.bannerAd.size.height.toDouble(),
      child: AdWidget(key: ObjectKey(widget.bannerAd), ad: widget.bannerAd),
    );
  }
}
