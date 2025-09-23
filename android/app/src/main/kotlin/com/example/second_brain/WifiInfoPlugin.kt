package com.example.second_brain

import android.content.Context
import android.net.wifi.WifiManager
import android.net.wifi.WifiInfo
import android.net.NetworkInfo
import android.net.ConnectivityManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class WifiInfoPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel
    private lateinit var context: Context
    private lateinit var wifiManager: WifiManager
    private lateinit var connectivityManager: ConnectivityManager

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "wifi_info")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        wifiManager = context.getSystemService(Context.WIFI_SERVICE) as WifiManager
        connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getWifiInfo" -> {
                getWifiInfo(result)
            }
            "isWifiConnected" -> {
                isWifiConnected(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun getWifiInfo(result: Result) {
        try {
            if (!wifiManager.isWifiEnabled) {
                result.success(null)
                return
            }

            val wifiInfo: WifiInfo? = wifiManager.connectionInfo
            if (wifiInfo == null) {
                result.success(null)
                return
            }

            val ssid = wifiInfo.ssid
            val bssid = wifiInfo.bssid
            val rssi = wifiInfo.rssi

            val wifiData = mapOf(
                "ssid" to ssid,
                "bssid" to bssid,
                "rssi" to rssi,
                "isConnected" to (ssid != "<unknown ssid>" && ssid.isNotEmpty())
            )

            result.success(wifiData)
        } catch (e: Exception) {
            result.error("WIFI_ERROR", "WiFi 정보를 가져올 수 없습니다: ${e.message}", null)
        }
    }

    private fun isWifiConnected(result: Result) {
        try {
            val networkInfo: NetworkInfo? = connectivityManager.getNetworkInfo(ConnectivityManager.TYPE_WIFI)
            val isConnected = networkInfo?.isConnected == true
            result.success(isConnected)
        } catch (e: Exception) {
            result.error("CONNECTIVITY_ERROR", "연결 상태를 확인할 수 없습니다: ${e.message}", null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}






