import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:multi_ads/src/utils/log_utils.dart';

class GoogleBannerAd {
  static BannerAd? _bannerAd;
  static bool _isLoading = false;

  static Future<void> load(
    BuildContext context,
    String adUnitId, {
    Function? onAdShowedHandle,
    Function(int code, String message)? onAdFailedToShowHandle,
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
          onAdLoadedRefresh?.call();

          _isLoading = false;
          LogUtils.log('Banner ad loaded', tag: 'google ads');
        },
        onAdClicked: (ad) {
          onAdClickedHandle?.call();
        },
        onAdFailedToLoad: (ad, err) {
          onAdFailedToShowHandle?.call(err.code, err.message);
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

class _BannerAdWidgetState extends State<_BannerAdWidget>
    with SingleTickerProviderStateMixin {
  static _BannerAdWidgetState? _currentOwner;
  bool _isOwner = false;

  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

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
    _fadeCtrl.dispose();
    if (_currentOwner == this) {
      _currentOwner = null;
    }
    super.dispose();
  }

  void _tryClaimOwnership() {
    if (!mounted) return;

    final route = ModalRoute.of(context);
    final isCurrentRoute = route?.isCurrent ?? false;

    if (isCurrentRoute && !_isOwner) {
      // 检查 secondaryAnimation：子页面 pop 时底层路由的 secondaryAnimation
      // 从 completed → dismissed，在此期间 slide 动画正在进行，native UIView 处于平移中。
      // 必须等 secondaryAnimation.isDismissed 才能插入 AdWidget，否则 collapsible
      // banner SDK 会在错误的屏幕坐标缓存基点，导致展开偏移。
      final secAnim = route?.secondaryAnimation;
      if (secAnim != null && !secAnim.isDismissed) {
        void onSecStatus(AnimationStatus s) {
          if (s == AnimationStatus.dismissed) {
            secAnim.removeStatusListener(onSecStatus);
            if (mounted) _tryClaimOwnership();
          }
        }

        secAnim.addStatusListener(onSecStatus);
        return;
      }
      if (_currentOwner == null || !_currentOwner!.mounted) {
        _currentOwner = this;
        setState(() => _isOwner = true);
        _fadeCtrl.forward(from: 0.0);
      } else if (_currentOwner != this) {
        final oldOwner = _currentOwner!;
        _currentOwner = this;

        oldOwner._releaseOwnership();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
            setState(() => _isOwner = true);
            _fadeCtrl.forward(from: 0.0);
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
    final w = widget.bannerAd.size.width.toDouble();
    final h = widget.bannerAd.size.height.toDouble();
    if (!_isOwner) return const SizedBox.shrink();
    // FadeTransition from 0→1，隐藏 platform view 初始化时的灰色背景
    return FadeTransition(
      opacity: _fadeCtrl,
      child: SizedBox(
        width: w,
        height: h,
        child: AdWidget(key: ObjectKey(widget.bannerAd), ad: widget.bannerAd),
      ),
    );
  }
}
