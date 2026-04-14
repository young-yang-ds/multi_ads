import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AdError;

import '../../multi_ads.dart';
import '../utils/log_utils.dart';

/// A lifecycle-aware widget that automatically manages native ad loading,
/// displaying, and disposal across multiple pages.
///
/// Solves the singleton limitation where only one native ad instance per
/// platform can exist at a time. When navigating between pages:
///
/// 1. **Push**: New page's widget takes ownership → loads ad.
///    Previous page's widget yields → shows [placeholder].
/// 2. **Pop**: Current page disposed → previous page automatically reloads.
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
  // ── Ownership tracking (per platform) ──────────────────────────────────

  /// The widget instance that currently owns each platform's ad slot.
  static final Map<AdPlatform, _NativeAdWidgetState> _activeOwners = {};

  /// LIFO stack of previous owners waiting to reload when the current
  /// owner is disposed (e.g. page popped).
  static final Map<AdPlatform, List<_NativeAdWidgetState>> _waitingStack = {};

  // ── Instance state ─────────────────────────────────────────────────────

  bool _isAdLoaded = false;

  @override
  bool get wantKeepAlive => widget.keepAlive;

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _acquireOwnership();
  }

  @override
  void dispose() {
    _releaseOwnership();
    super.dispose();
  }

  // ── Ownership management ───────────────────────────────────────────────

  /// Claim the ad slot for [widget.adPlatform].
  /// If another widget currently owns it, push them onto the waiting stack.
  void _acquireOwnership() {
    final platform = widget.adPlatform;
    final currentOwner = _activeOwners[platform];

    if (currentOwner != null && currentOwner != this) {
      // Push old owner to the waiting stack
      _waitingStack.putIfAbsent(platform, () => []);
      _waitingStack[platform]!.remove(currentOwner);
      _waitingStack[platform]!.add(currentOwner);
      // Notify old owner: it should show placeholder
      currentOwner._onOwnershipLost();
    }

    // Remove self from waiting stack (if we were waiting)
    _waitingStack[platform]?.remove(this);

    // Become the active owner
    _activeOwners[platform] = this;

    LogUtils.log(
      'Acquired ownership for ${platform.name}',
      tag: 'NativeAdWidget',
    );

    _loadAd();
  }

  /// Release ownership when this widget is disposed.
  /// If there is a previous owner on the stack, let it reload.
  void _releaseOwnership() {
    final platform = widget.adPlatform;

    // Clean up from waiting stack regardless
    _waitingStack[platform]?.remove(this);

    // Only the active owner should dispose the ad
    if (_activeOwners[platform] != this) return;

    _disposePlatformAd();
    _activeOwners.remove(platform);

    LogUtils.log(
      'Released ownership for ${platform.name}',
      tag: 'NativeAdWidget',
    );

    // Notify the previous waiting widget to take over
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

  /// Called when another widget takes ownership from us.
  void _onOwnershipLost() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _isAdLoaded = false);
        }
      });
    }
  }

  // ── Ad loading / disposal ──────────────────────────────────────────────

  /// Dispose existing ad (awaiting async platforms), then load a fresh one.
  Future<void> _loadAd() async {
    if (!mounted) return;
    setState(() => _isAdLoaded = false);

    // Fully dispose previous ad to clear singleton state
    await _disposePlatformAdAsync();

    // Guard: still alive and still the owner?
    if (!mounted || _activeOwners[widget.adPlatform] != this) return;

    _loadPlatformAd();
  }

  /// Fire-and-forget dispose (used in [_releaseOwnership] which is sync).
  void _disposePlatformAd() {
    final platform = widget.adPlatform;
    if (platform == AdPlatform.google) {
      GoogleNativeAd.dispose();
    } else if (platform == AdPlatform.pangleGlobal) {
      PangleNativeAd.dispose(); // Future – fire & forget
    } else if (platform == AdPlatform.vungle) {
      VungleNativeAd.dispose(); // Future – fire & forget
    }
  }

  /// Awaitable dispose (ensures async method-channel call completes before
  /// we call [load] again – avoids flag race conditions).
  Future<void> _disposePlatformAdAsync() async {
    final platform = widget.adPlatform;
    if (platform == AdPlatform.google) {
      GoogleNativeAd.dispose();
    } else if (platform == AdPlatform.pangleGlobal) {
      await PangleNativeAd.dispose();
    } else if (platform == AdPlatform.vungle) {
      await VungleNativeAd.dispose();
    }
  }

  /// Route to the correct platform-specific [load] with unified callbacks.
  void _loadPlatformAd() {
    final platform = widget.adPlatform;

    if (platform == AdPlatform.google) {
      GoogleNativeAd.load(
        widget.adUnitId,
        style: widget.style,
        templateType: widget.templateType,
        nativeTemplateStyle: widget.nativeTemplateStyle,
        onAdLoadedRefresh: _handleAdLoaded,
        onAdFailedToLoadHandle: (code, message) => _handleAdFailed(
          AdError(code: code, message: message, platform: 'google'),
        ),
        onAdClickedHandle: () => widget.onAdClicked?.call(),
      );
    } else if (platform == AdPlatform.pangleGlobal) {
      PangleNativeAd.load(
        widget.adUnitId,
        style: widget.style,
        onAdLoaded: _handleAdLoaded,
        onAdLoadFailed: (error) => _handleAdFailed(
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
        onAdLoaded: _handleAdLoaded,
        onAdLoadFailed: (error) => _handleAdFailed(
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

  // ── Callbacks ──────────────────────────────────────────────────────────

  void _handleAdLoaded() {
    if (mounted && _activeOwners[widget.adPlatform] == this) {
      setState(() => _isAdLoaded = true);
      widget.onAdLoaded?.call();
    }
  }

  void _handleAdFailed(AdError error) {
    if (mounted && _activeOwners[widget.adPlatform] == this) {
      LogUtils.log(
        'Ad load failed: ${error.code} - ${error.message}',
        tag: 'NativeAdWidget',
      );
      widget.onAdFailed?.call(error);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  /// Build the ad widget for the current platform.
  Widget _buildAdWidget() {
    final platform = widget.adPlatform;
    if (platform == AdPlatform.google) {
      return GoogleNativeAd.buildWidget();
    } else if (platform == AdPlatform.pangleGlobal) {
      return PangleNativeAd.buildWidget();
    } else if (platform == AdPlatform.vungle) {
      return VungleNativeAd.buildWidget();
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    if (_isAdLoaded && _activeOwners[widget.adPlatform] == this) {
      return _buildAdWidget();
    }
    return widget.placeholder ?? const SizedBox.shrink();
  }
}
