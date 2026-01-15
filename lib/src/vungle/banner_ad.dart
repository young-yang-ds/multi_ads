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

/// Manager for Vungle Banner Ad callbacks
class _VungleBannerAdCallbackManager {
  static final _VungleBannerAdCallbackManager _instance =
      _VungleBannerAdCallbackManager._internal();

  factory _VungleBannerAdCallbackManager() => _instance;

  static const MethodChannel _channel = MethodChannel('multi_ads/vungle');
  final Map<String, VungleBannerAd> _listeners = {};
  bool _isInitialized = false;

  _VungleBannerAdCallbackManager._internal();

  void register(VungleBannerAd ad) {
    _listeners[ad.listenerId] = ad;
    _ensureInitialized();
  }

  void unregister(String listenerId) {
    _listeners.remove(listenerId);
  }

  void _ensureInitialized() {
    if (_isInitialized) return;
    _isInitialized = true;

    _channel.setMethodCallHandler((call) async {
      vungleLog('[VungleBannerAdManager] Received method call: ${call.method}');

      final args = call.arguments as Map?;
      final listenerId = args?['listenerId'] as String?;

      if (listenerId == null) {
        vungleLog('[VungleBannerAdManager] No listenerId in callback');
        return;
      }

      final ad = _listeners[listenerId];
      if (ad == null) {
        vungleLog('[VungleBannerAdManager] No listener found for: $listenerId');
        return;
      }

      switch (call.method) {
        case 'onBannerAdLoaded':
          ad._handleLoaded();
          break;
        case 'onBannerAdLoadFailed':
          final error = VungleAdError.fromJson(
            Map<String, dynamic>.from(args!['error'] as Map? ?? {}),
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
        default:
          vungleLog('[VungleBannerAdManager] Unknown method: ${call.method}');
      }
    });
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
    _VungleBannerAdCallbackManager().register(this);
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

    _VungleBannerAdCallbackManager().unregister(_listenerId);
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

  const VungleBannerAdWidget({
    Key? key,
    required this.placementId,
    this.adSize = VungleBannerAdSize.banner,
    this.onAdLoaded,
    this.onAdLoadFailed,
    this.onAdClicked,
  }) : super(key: key);

  @override
  State<VungleBannerAdWidget> createState() => _VungleBannerAdWidgetState();
}

class _VungleBannerAdWidgetState extends State<VungleBannerAdWidget> {
  static const MethodChannel _channel = MethodChannel('multi_ads/vungle');
  late final String _listenerId;
  bool _isAdLoaded = false;
  Widget? _platformView;

  @override
  void initState() {
    super.initState();
    _listenerId =
        '${widget.placementId}_${DateTime.now().millisecondsSinceEpoch}';
    _setupChannelHandler();
  }

  void _setupChannelHandler() {
    _channel.setMethodCallHandler((call) async {
      final args = call.arguments as Map?;
      final listenerId = args?['listenerId'] as String?;

      if (listenerId != _listenerId) return;

      switch (call.method) {
        case 'onBannerAdLoaded':
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
          widget.onAdLoaded?.call();
          break;
        case 'onBannerAdLoadFailed':
          final error = VungleAdError.fromJson(
            Map<String, dynamic>.from(args!['error'] as Map? ?? {}),
          );
          widget.onAdLoadFailed?.call(error);
          break;
        case 'onBannerAdClicked':
          widget.onAdClicked?.call();
          break;
      }
    });
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
    vungleLog(
      '[VungleBannerAdWidget] Building - placementId: ${widget.placementId}, size: ${size.width}x${size.height}, loaded: $_isAdLoaded',
    );

    _platformView ??= _buildPlatformView();

    return SizedBox(
      width: size.width,
      height: _isAdLoaded ? size.height : 0,
      child: _platformView,
    );
  }

  Widget _buildPlatformView() {
    final Map<String, dynamic> creationParams = {
      'placementId': widget.placementId,
      'bannerSize': widget.adSize.index,
      'listenerId': _listenerId,
    };
    vungleLog(
      '[VungleBannerAdWidget] Creating platform view with params: $creationParams',
    );

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
