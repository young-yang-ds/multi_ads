package com.example.multi_ads

import android.app.Activity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.example.multi_ads.pangle_global.PangleAdsHandler

/** MultiAdsPlugin */
class MultiAdsPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private var pangleAdsHandler: PangleAdsHandler? = null
    private var activity: Activity? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "multi_ads")
        channel.setMethodCallHandler(this)
        
        // Initialize Pangle Ads Handler
        pangleAdsHandler = PangleAdsHandler(flutterPluginBinding)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        pangleAdsHandler?.dispose()
        pangleAdsHandler = null
    }
    
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        pangleAdsHandler?.setActivity(activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
        pangleAdsHandler?.setActivity(null)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        pangleAdsHandler?.setActivity(activity)
    }

    override fun onDetachedFromActivity() {
        activity = null
        pangleAdsHandler?.setActivity(null)
    }
}
