import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'banner_ad.dart';
import 'pangle_method_channel.dart';

class PangleBannerAdContainer extends StatefulWidget {
  final PangleBannerAd bannerAd;

  final double? width;

  final double? height;

  const PangleBannerAdContainer({
    Key? key,
    required this.bannerAd,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<PangleBannerAdContainer> createState() =>
      _PangleBannerAdContainerState();
}

class _PangleBannerAdContainerState extends State<PangleBannerAdContainer> {
  Size _getAdSize() {
    switch (widget.bannerAd.adSize) {
      case PangleBannerAdSize.banner320x50:
        return const Size(320, 50);
      case PangleBannerAdSize.banner300x250:
        return const Size(300, 250);
      case PangleBannerAdSize.banner728x90:
        return const Size(728, 90);
      case PangleBannerAdSize.anchoredAdaptive:
        final screenWidth = MediaQuery.of(context).size.width;
        return Size(screenWidth, 90);
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

    pangleLog(
        '[BannerAdContainer] Building container - listenerId: ${widget.bannerAd.listenerId}, size: ${containerWidth}x$containerHeight');

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

    pangleLog(
        '[BannerAdContainer] Creating platform view with listenerId: ${widget.bannerAd.listenerId}');

    if (defaultTargetPlatform == TargetPlatform.android) {
      return PlatformViewLink(
        viewType: 'multi_ads/pangle_global/banner_container',
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
            viewType: 'multi_ads/pangle_global/banner_container',
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
        viewType: 'multi_ads/pangle_global/banner_container',
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Text('Platform not supported'),
      ),
    );
  }
}
