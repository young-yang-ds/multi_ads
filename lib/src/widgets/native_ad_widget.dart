import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AdError;

import '../../multi_ads.dart';
import '../utils/log_utils.dart';

/// A widget that displays native ads. Supports multiple simultaneous instances
/// for Google platform (each manages its own NativeAd object).
///
/// For Pangle/Vungle platforms, a singleton ownership system is used since
/// those SDKs only support one native ad at a time.
///
/// Usage:
/// ```dart
/// NativeAdWidget(
///   adUnitId: 'your-ad-unit-id',
///   adPlatform: AdPlatform.google,
///   style: NativeAdStyle(height: 80, cornerRadius: 10),
///   placeholder: SizedBox(height: 80),
///   onAdLoaded: () => debugPrint('Ad loaded'),
///   onAdFailed: (error) => debugPrint('Ad failed: $error'),
/// )
/// ```
class NativeAdWidget extends StatefulWidget {
  /// The ad unit ID / slot ID / placement ID
  final String adUnitId;

  /// The ad platform to use
  final AdPlatform adPlatform;

  /// Custom style configuration (factory mode).
  /// When provided, uses native NativeAdFactory for rendering.
  final NativeAdStyle? style;

  /// Google only: Template type (ignored when [style] is provided)
  final TemplateType templateType;

  /// Google only: Custom template style (ignored when [style] is provided)
  final NativeTemplateStyle? nativeTemplateStyle;

  /// Widget to show while ad is loading or when ownership is lost.
  /// Defaults to [SizedBox.shrink] if not provided.
  final Widget? placeholder;

  /// Called when the ad is successfully loaded
  final VoidCallback? onAdLoaded;

  /// Called when the ad fails to load
  final Function(AdError error)? onAdFailed;

  /// Called when the ad is clicked
  final VoidCallback? onAdClicked;

  /// Whether to keep the widget alive when scrolled off-screen in a list.
  /// Defaults to `true` to avoid expensive ad reloads.
  /// Set to `false` if you want the ad to be disposed when not visible.
  final bool keepAlive;

  const NativeAdWidget({
    super.key,
    required this.adUnitId,
    required this.adPlatform,
    this.style,
    this.templateType = TemplateType.medium,
    this.nativeTemplateStyle,
    this.placeholder,
    this.onAdLoaded,
    this.onAdFailed,
    this.onAdClicked,
    this.keepAlive = true,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget>
    with AutomaticKeepAliveClientMixin {
  // ── Ownership tracking for Pangle/Vungle (singleton platforms) ─────────

  static final Map<AdPlatform, _NativeAdWidgetState> _activeOwners = {};
  static final Map<AdPlatform, List<_NativeAdWidgetState>> _waitingStack = {};

  // ── Instance state ─────────────────────────────────────────────────────

  bool _isAdLoaded = false;

  /// Google: each instance holds its own NativeAd object (multi-instance).
  NativeAd? _googleNativeAd;

  @override
  bool get wantKeepAlive => widget.keepAlive;

  bool get _isGoogle => widget.adPlatform == AdPlatform.google;

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (_isGoogle) {
      _loadGoogleAd();
    } else {
      _acquireOwnership();
    }
  }

  @override
  void dispose() {
    if (_isGoogle) {
      _disposeGoogleAd();
    } else {
      _releaseOwnership();
    }
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Google: Multi-instance support ─────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  void _loadGoogleAd() {
    final style = widget.style;
    final useFactory = style != null;

    LogUtils.log(
      'Loading Google native ad (instance: ${hashCode.toRadixString(16)})',
      tag: 'NativeAdWidget',
    );

    if (useFactory) {
      LogUtils.log('Native ad loading (custom style)', tag: 'google ads');
      _googleNativeAd = NativeAd(
        adUnitId: widget.adUnitId,
        factoryId: 'multiAdsNativeFactory',
        customOptions: style.toMap(),
        request: const AdRequest(),
        listener: _googleAdListener,
      )..load();
    } else {
      LogUtils.log(
        'Native ad loading (template: ${widget.templateType})',
        tag: 'google ads',
      );
      _googleNativeAd = NativeAd(
        adUnitId: widget.adUnitId,
        request: const AdRequest(),
        nativeTemplateStyle: widget.nativeTemplateStyle ??
            NativeTemplateStyle(templateType: widget.templateType),
        listener: _googleAdListener,
      )..load();
    }
  }

  NativeAdListener get _googleAdListener => NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            LogUtils.log('Native ad loaded', tag: 'google ads');
            setState(() => _isAdLoaded = true);
            widget.onAdLoaded?.call();
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _googleNativeAd = null;
          LogUtils.log(
            'Native ad load failed: ${error.code} - ${error.message}',
            tag: 'google ads',
          );
          if (mounted) {
            widget.onAdFailed?.call(
              AdError(
                code: error.code,
                message: error.message,
                platform: 'google',
              ),
            );
          }
        },
        onAdClicked: (ad) {
          LogUtils.log('Native ad clicked', tag: 'google ads');
          widget.onAdClicked?.call();
        },
        onAdImpression: (ad) {
          LogUtils.log('Native ad impression', tag: 'google ads');
        },
      );

  void _disposeGoogleAd() {
    _googleNativeAd?.dispose();
    _googleNativeAd = null;
    _isAdLoaded = false;
    LogUtils.log(
      'Disposed Google native ad (instance: ${hashCode.toRadixString(16)})',
      tag: 'NativeAdWidget',
    );
  }

  Widget _buildGoogleAdWidget() {
    if (_googleNativeAd == null || !_isAdLoaded) {
      return widget.placeholder ?? const SizedBox.shrink();
    }

    final adWidget =
        AdWidget(key: ObjectKey(_googleNativeAd!), ad: _googleNativeAd!);
    final style = widget.style;

    if (style != null) {
      return Padding(
        padding: style.margin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(style.cornerRadius),
          child: SizedBox(
            width: double.infinity,
            height: style.height,
            child: adWidget,
          ),
        ),
      );
    }

    final constraints = widget.templateType == TemplateType.small
        ? const BoxConstraints(
            minWidth: 320, minHeight: 90, maxWidth: 400, maxHeight: 200)
        : const BoxConstraints(
            minWidth: 320, minHeight: 320, maxWidth: 400, maxHeight: 400);

    return Container(
      color: Colors.white,
      child: ConstrainedBox(constraints: constraints, child: adWidget),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Pangle / Vungle: Singleton ownership system ────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  void _acquireOwnership() {
    final platform = widget.adPlatform;
    final currentOwner = _activeOwners[platform];

    if (currentOwner != null && currentOwner != this) {
      _waitingStack.putIfAbsent(platform, () => []);
      _waitingStack[platform]!.remove(currentOwner);
      _waitingStack[platform]!.add(currentOwner);
      currentOwner._onOwnershipLost();
    }

    _waitingStack[platform]?.remove(this);
    _activeOwners[platform] = this;

    LogUtils.log(
      'Acquired ownership for ${platform.name}',
      tag: 'NativeAdWidget',
    );

    _loadSingletonAd();
  }

  void _releaseOwnership() {
    final platform = widget.adPlatform;

    _waitingStack[platform]?.remove(this);

    if (_activeOwners[platform] != this) return;

    _disposeSingletonAd();
    _activeOwners.remove(platform);

    LogUtils.log(
      'Released ownership for ${platform.name}',
      tag: 'NativeAdWidget',
    );

    final stack = _waitingStack[platform];
    if (stack != null && stack.isNotEmpty) {
      final next = stack.removeLast();
      if (next.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (next.mounted) {
            next._acquireOwnership();
          }
        });
      }
    }
  }

  void _onOwnershipLost() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _isAdLoaded = false);
        }
      });
    }
  }

  // ── Singleton ad loading / disposal ────────────────────────────────────

  Future<void> _loadSingletonAd() async {
    if (!mounted) return;
    setState(() => _isAdLoaded = false);

    await _disposeSingletonAdAsync();

    if (!mounted || _activeOwners[widget.adPlatform] != this) return;

    _loadSingletonPlatformAd();
  }

  void _disposeSingletonAd() {
    final platform = widget.adPlatform;
    if (platform == AdPlatform.pangleGlobal) {
      PangleNativeAd.dispose();
    } else if (platform == AdPlatform.vungle) {
      VungleNativeAd.dispose();
    }
  }

  Future<void> _disposeSingletonAdAsync() async {
    final platform = widget.adPlatform;
    if (platform == AdPlatform.pangleGlobal) {
      await PangleNativeAd.dispose();
    } else if (platform == AdPlatform.vungle) {
      await VungleNativeAd.dispose();
    }
  }

  void _loadSingletonPlatformAd() {
    final platform = widget.adPlatform;

    if (platform == AdPlatform.pangleGlobal) {
      PangleNativeAd.load(
        widget.adUnitId,
        style: widget.style,
        onAdLoaded: _handleSingletonAdLoaded,
        onAdLoadFailed: (error) => _handleSingletonAdFailed(
          AdError(
            code: error.code,
            message: error.message,
            platform: 'pangleGlobal',
          ),
        ),
        onAdClicked: () => widget.onAdClicked?.call(),
      );
    } else if (platform == AdPlatform.vungle) {
      VungleNativeAd.load(
        widget.adUnitId,
        style: widget.style,
        onAdLoaded: _handleSingletonAdLoaded,
        onAdLoadFailed: (error) => _handleSingletonAdFailed(
          AdError(
            code: error.code,
            message: error.message,
            platform: 'vungle',
          ),
        ),
        onAdClicked: () => widget.onAdClicked?.call(),
      );
    }
  }

  void _handleSingletonAdLoaded() {
    if (mounted && _activeOwners[widget.adPlatform] == this) {
      setState(() => _isAdLoaded = true);
      widget.onAdLoaded?.call();
    }
  }

  void _handleSingletonAdFailed(AdError error) {
    if (mounted && _activeOwners[widget.adPlatform] == this) {
      LogUtils.log(
        'Ad load failed: ${error.code} - ${error.message}',
        tag: 'NativeAdWidget',
      );
      widget.onAdFailed?.call(error);
    }
  }

  Widget _buildSingletonAdWidget() {
    final platform = widget.adPlatform;
    if (platform == AdPlatform.pangleGlobal) {
      return PangleNativeAd.buildWidget();
    } else if (platform == AdPlatform.vungle) {
      return VungleNativeAd.buildWidget();
    }
    return const SizedBox.shrink();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Build ──────────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    if (_isGoogle) {
      if (_isAdLoaded) {
        return _buildGoogleAdWidget();
      }
      return widget.placeholder ?? const SizedBox.shrink();
    }

    // Pangle / Vungle
    if (_isAdLoaded && _activeOwners[widget.adPlatform] == this) {
      return _buildSingletonAdWidget();
    }
    return widget.placeholder ?? const SizedBox.shrink();
  }
}
