import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:multi_ads/src/log_utils.dart';

class GoogleBannerAd {
  static BannerAd? _bannerAd;
  static bool _isLoading = false;
  static _BannerAdWidgetState? _currentOwner;

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
        onAdLoaded: (ad) {
          onAdLoadedRefresh?.call();
          _isLoading = false;
          LogUtils.log('Banner ad loaded', tag: 'google ads');
        },
        // onAdLoaded: (ad) async {
        //   await Future.delayed(const Duration(seconds: 5));
        //   onAdLoadedRefresh?.call();
        //   _isLoading = false;
        //   LogUtils.log('Banner ad loaded', tag: 'google ads');
        // },
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
          LogUtils.log('banner ad dismiss', tag: 'Google_ads');
        },
        onAdOpened: (ad) {
          LogUtils.log('banner ad showed', tag: 'Google_ads');
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
    return _BannerAdWidget(bannerAd: _bannerAd!);
  }

  static void _claimOwnership(_BannerAdWidgetState newOwner) {
    if (_currentOwner != null && _currentOwner != newOwner) {
      _currentOwner!._releaseAd();
      // Delay setting new owner to ensure old widget rebuilds first
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (newOwner.mounted) {
          _currentOwner = newOwner;
          newOwner._finishClaim();
        }
      });
    } else {
      _currentOwner = newOwner;
      newOwner._finishClaim();
    }
  }

  static void _releaseOwnership(_BannerAdWidgetState owner) {
    if (_currentOwner == owner) {
      _currentOwner = null;
      // Notify other waiting widgets to try claiming ownership
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyWaitingWidgets();
      });
    }
  }

  static final Set<_BannerAdWidgetState> _waitingWidgets = {};

  static void _registerWaiting(_BannerAdWidgetState widget) {
    _waitingWidgets.add(widget);
  }

  static void _unregisterWaiting(_BannerAdWidgetState widget) {
    _waitingWidgets.remove(widget);
  }

  static void _notifyWaitingWidgets() {
    if (_currentOwner == null && _waitingWidgets.isNotEmpty) {
      final widget = _waitingWidgets.first;
      if (widget.mounted) {
        widget._claimOwnership();
      }
    }
  }

  static void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _currentOwner = null;
    _waitingWidgets.clear();
  }
}

class _BannerAdWidget extends StatefulWidget {
  final BannerAd bannerAd;

  const _BannerAdWidget({required this.bannerAd});

  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    GoogleBannerAd._registerWaiting(this);
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _claimOwnership();
      }
    });
  }

  @override
  void dispose() {
    GoogleBannerAd._unregisterWaiting(this);
    if (_isOwner) {
      GoogleBannerAd._releaseOwnership(this);
    }
    super.dispose();
  }

  void _claimOwnership() {
    if (!_isOwner) {
      GoogleBannerAd._unregisterWaiting(this);
      GoogleBannerAd._claimOwnership(this);
    }
  }

  void _finishClaim() {
    if (mounted && !_isOwner) {
      setState(() {
        _isOwner = true;
      });
    }
  }

  void _releaseAd() {
    if (_isOwner && mounted) {
      GoogleBannerAd._registerWaiting(this);
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
