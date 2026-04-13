package com.example.multi_ads_example

import android.content.Context
import com.example.multi_ads.NativeAdViewBuilder
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class NativeAdFactoryImpl(context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {
    private val builder = NativeAdViewBuilder(context)

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView = builder.build(nativeAd, customOptions)
}
