import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'models/vungle_ad_error.dart';
import 'vungle_method_channel.dart';
import 'vungle_platform.dart';

/// Banner ad sizes for Vungle
enum VungleBannerAdSize {
  /// 320x50
  banner,

  /// 300x50
  bannerShort,

  /// 728x90
  bannerLeaderboard,

  /// 300x250
  mrec,
}

/// Global callback manager for Vungle Banner Ads
class _VungleBannerCallbackManager {
  static final _VungleBannerCallbackManager _instance =
      _VungleBannerCallbackManager._internal();

  factory _VungleBannerCallbackManager() => _instance;

  static const MethodChannel _channel = MethodChannel('multi_ads/vungle');

  // For VungleBannerAd (preload mode)
  final Map<String, VungleBannerAd> _adListeners = {};

  // For VungleBannerAdWidget (widget mode)
  final Map<String, _VungleBannerAdWidgetState> _widgetListeners = {};

  bool _isInitialized = false;

  _VungleBannerCallbackManager._internal();

  void registerAd(VungleBannerAd ad) {
    _adListeners[ad.listenerId] = ad;
    _ensureInitialized();
  }

  void unregisterAd(String listenerId) {
    _adListeners.remove(listenerId);
  }

  void registerWidget(_VungleBannerAdWidgetState widget) {
    _widgetListeners[widget._listenerId] = widget;
    _ensureInitialized();
  }

  void unregisterWidget(String listenerId) {
    _widgetListeners.remove(listenerId);
  }

  void _ensureInitialized() {
    if (_isInitialized) return;
    _isInitialized = true;

    _channel.setMethodCallHandler((call) async {
      vungleLog('[VungleBannerCallbackManager] Received: ${call.method}');

      final args = call.arguments as Map?;
      final listenerId = args?['listenerId'] as String?;

      if (listenerId == null) {
        vungleLog('[VungleBannerCallbackManager] No listenerId in callback');
        return;
      }

      vungleLog('[VungleBannerCallbackManager] ListenerId: $listenerId');

      // Try to find in ad listeners first
      final ad = _adListeners[listenerId];
      if (ad != null) {
        _handleAdCallback(call.method, ad, args);
        return;
      }

      // Then try widget listeners
      final widget = _widgetListeners[listenerId];
      if (widget != null) {
        _handleWidgetCallback(call.method, widget, args);
        return;
      }

      vungleLog(
        '[VungleBannerCallbackManager] No listener found for: $listenerId',
      );
    });
  }

  void _handleAdCallback(String method, VungleBannerAd ad, Map? args) {
    switch (method) {
      case 'onBannerAdLoaded':
        ad._handleLoaded();
        break;
      case 'onBannerAdLoadFailed':
        final error = VungleAdError.fromJson(
          Map<String, dynamic>.from(args?['error'] as Map? ?? {}),
        );
        ad._handleLoadFailed(error);
        break;
      case 'onBannerAdClicked':
        ad._handleClicked();
        break;
      case 'onBannerAdShowed':
        ad._handleShowed();
        break;
      case 'onBannerAdImpression':
        ad._handleImpression();
        break;
      case 'onBannerAdClosed':
        ad._handleClosed();
        break;
    }
  }

  void _handleWidgetCallback(
    String method,
    _VungleBannerAdWidgetState widget,
    Map? args,
  ) {
    switch (method) {
      case 'onBannerAdLoaded':
        widget._handleLoaded();
        break;
      case 'onBannerAdLoadFailed':
        final error = VungleAdError.fromJson(
          Map<String, dynamic>.from(args?['error'] as Map? ?? {}),
        );
        widget._handleLoadFailed(error);
        break;
      case 'onBannerAdClicked':
        widget._handleClicked();
        break;
    }
  }
}

/// Vungle Banner Ad
class VungleBannerAd {
  final String placementId;
  final VungleBannerAdSize adSize;
  final Function()? onAdLoaded;
  final Function(VungleAdError error)? onAdLoadFailed;
  final Function()? onAdClicked;
  final Function()? onAdShowed;
  final Function()? onAdImpression;
  final Function()? onAdClosed;

  late final String _listenerId;
  bool _isLoaded = false;
  bool _isLoading = false;

  VungleBannerAd({
    required this.placementId,
    this.adSize = VungleBannerAdSize.banner,
    this.onAdLoaded,
    this.onAdLoadFailed,
    this.onAdClicked,
    this.onAdShowed,
    this.onAdImpression,
    this.onAdClosed,
  }) {
    _listenerId = '${placementId}_${DateTime.now().millisecondsSinceEpoch}';
    _VungleBannerCallbackManager().registerAd(this);
  }

  void _handleLoaded() {
    _isLoaded = true;
    _isLoading = false;
    vungleLog('[VungleBannerAd] Ad loaded - listenerId: $_listenerId');
    onAdLoaded?.call();
  }

  void _handleLoadFailed(VungleAdError error) {
    _isLoading = false;
    vungleLog(
      '[VungleBannerAd] Ad load failed: ${error.code} - ${error.message}',
    );
    onAdLoadFailed?.call(error);
  }

  void _handleClicked() {
    vungleLog('[VungleBannerAd] Ad clicked');
    onAdClicked?.call();
  }

  void _handleShowed() {
    vungleLog('[VungleBannerAd] Ad showed');
    onAdShowed?.call();
  }

  void _handleImpression() {
    vungleLog('[VungleBannerAd] Ad impression');
    onAdImpression?.call();
  }

  void _handleClosed() {
    vungleLog('[VungleBannerAd] Ad closed');
    onAdClosed?.call();
  }

  /// Load the banner ad
  Future<bool> load() async {
    if (_isLoading) {
      vungleLog('[VungleBannerAd] Already loading');
      return false;
    }

    if (_isLoaded) {
      vungleLog('[VungleBannerAd] Already loaded');
      return true;
    }

    _isLoading = true;
    vungleLog(
      '[VungleBannerAd] Loading ad - placementId: $placementId, size: $adSize',
    );

    try {
      final result = await VunglePlatform.instance.loadBannerAd(
        placementId: placementId,
        bannerSize: adSize.index,
        listenerId: _listenerId,
      );
      return result;
    } catch (e) {
      _isLoading = false;
      vungleLog('[VungleBannerAd] Load error: $e');
      return false;
    }
  }

  /// Dispose the banner ad
  Future<void> dispose() async {
    vungleLog('[VungleBannerAd] Disposing banner ad');

    try {
      await VunglePlatform.instance.disposeBannerAd(listenerId: _listenerId);
    } catch (e) {
      vungleLog('[VungleBannerAd] Dispose error: $e');
    }

    _VungleBannerCallbackManager().unregisterAd(_listenerId);
    _isLoaded = false;
    _isLoading = false;
  }

  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  String get listenerId => _listenerId;
}

/// Widget to display a Vungle Banner Ad
class VungleBannerAdWidget extends StatefulWidget {
  final String placementId;
  final VungleBannerAdSize adSize;
  final Function()? onAdLoaded;
  final Function(VungleAdError error)? onAdLoadFailed;
  final Function()? onAdClicked;
  final Color? backgroundColor;

  const VungleBannerAdWidget({
    Key? key,
    required this.placementId,
    this.adSize = VungleBannerAdSize.banner,
    this.onAdLoaded,
    this.onAdLoadFailed,
    this.onAdClicked,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<VungleBannerAdWidget> createState() => _VungleBannerAdWidgetState();
}

class _VungleBannerAdWidgetState extends State<VungleBannerAdWidget> {
  late final String _listenerId;
  bool _isAdLoaded = false;
  Widget? _platformView;

  @override
  void initState() {
    super.initState();
    _listenerId =
        '${widget.placementId}_${DateTime.now().millisecondsSinceEpoch}';
    _VungleBannerCallbackManager().registerWidget(this);
  }

  @override
  void dispose() {
    _VungleBannerCallbackManager().unregisterWidget(_listenerId);
    super.dispose();
  }

  void _handleLoaded() {
    vungleLog('[VungleBannerAdWidget] Ad loaded - listenerId: $_listenerId');
    if (mounted) {
      setState(() {
        _isAdLoaded = true;
      });
    }
    widget.onAdLoaded?.call();
  }

  void _handleLoadFailed(VungleAdError error) {
    vungleLog(
      '[VungleBannerAdWidget] Ad load failed: ${error.code} - ${error.message}',
    );
    widget.onAdLoadFailed?.call(error);
  }

  void _handleClicked() {
    vungleLog('[VungleBannerAdWidget] Ad clicked');
    widget.onAdClicked?.call();
  }

  Size _getAdSize() {
    switch (widget.adSize) {
      case VungleBannerAdSize.banner:
        return const Size(320, 50);
      case VungleBannerAdSize.bannerShort:
        return const Size(300, 50);
      case VungleBannerAdSize.bannerLeaderboard:
        return const Size(728, 90);
      case VungleBannerAdSize.mrec:
        return const Size(300, 250);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = _getAdSize();

    _platformView ??= _buildPlatformView();

    if (!_isAdLoaded) {
      return Offstage(
        offstage: true,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: _platformView,
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: size.height,
      color: widget.backgroundColor,
      alignment: Alignment.center,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: _platformView,
      ),
    );
  }

  Widget _buildPlatformView() {
    final Map<String, dynamic> creationParams = {
      'placementId': widget.placementId,
      'bannerSize': widget.adSize.index,
      'listenerId': _listenerId,
    };

    if (defaultTargetPlatform == TargetPlatform.android) {
      return PlatformViewLink(
        viewType: 'multi_ads/vungle/banner',
        surfaceFactory: (context, controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (params) {
          return PlatformViewsService.initSurfaceAndroidView(
              id: params.id,
              viewType: 'multi_ads/vungle/banner',
              layoutDirection: TextDirection.ltr,
              creationParams: creationParams,
              creationParamsCodec: const StandardMessageCodec(),
              onFocus: () {
                params.onFocusChanged(true);
              },
            )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..create();
        },
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'multi_ads/vungle/banner',
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return Container(
      color: Colors.grey[300],
      child: const Center(child: Text('Platform not supported')),
    );
  }
}

/// Container widget to display pre-loaded Vungle Banner Ads
class VungleBannerAdContainer extends StatefulWidget {
  final VungleBannerAd bannerAd;
  final double? width;
  final double? height;

  const VungleBannerAdContainer({
    Key? key,
    required this.bannerAd,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<VungleBannerAdContainer> createState() =>
      _VungleBannerAdContainerState();
}

class _VungleBannerAdContainerState extends State<VungleBannerAdContainer> {
  Size _getAdSize() {
    switch (widget.bannerAd.adSize) {
      case VungleBannerAdSize.banner:
        return const Size(320, 50);
      case VungleBannerAdSize.bannerShort:
        return const Size(300, 50);
      case VungleBannerAdSize.bannerLeaderboard:
        return const Size(728, 90);
      case VungleBannerAdSize.mrec:
        return const Size(300, 250);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.bannerAd.isLoaded) {
      return const SizedBox.shrink();
    }

    final size = _getAdSize();
    final containerWidth = widget.width ?? size.width;
    final containerHeight = widget.height ?? size.height;

    vungleLog(
      '[VungleBannerAdContainer] Building - listenerId: ${widget.bannerAd.listenerId}, size: ${containerWidth}x$containerHeight',
    );

    return SizedBox(
      width: containerWidth,
      height: containerHeight,
      child: _buildPlatformView(),
    );
  }

  Widget _buildPlatformView() {
    final Map<String, dynamic> creationParams = {
      'listenerId': widget.bannerAd.listenerId,
    };

    vungleLog(
      '[VungleBannerAdContainer] Creating platform view with listenerId: ${widget.bannerAd.listenerId}',
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      return PlatformViewLink(
        viewType: 'multi_ads/vungle/banner_container',
        surfaceFactory: (context, controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (params) {
          return PlatformViewsService.initSurfaceAndroidView(
              id: params.id,
              viewType: 'multi_ads/vungle/banner_container',
              layoutDirection: TextDirection.ltr,
              creationParams: creationParams,
              creationParamsCodec: const StandardMessageCodec(),
              onFocus: () {
                params.onFocusChanged(true);
              },
            )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..create();
        },
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'multi_ads/vungle/banner_container',
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return Container(
      color: Colors.grey[300],
      child: const Center(child: Text('Platform not supported')),
    );
  }
}
