package io.github.wreos.entra_external_id

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** Pigeon host implementation for the Entra External ID plugin. */
class EntraExternalIdPlugin : FlutterPlugin, NativeAuthHostApi {
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        NativeAuthHostApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun getNativeSdkStatus() =
        NativeSdkStatusMessage(
            platform = NativePlatformMessage.ANDROID,
            linked = false,
            sdkVersion = null,
        )

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        NativeAuthHostApi.setUp(binding.binaryMessenger, null)
    }
}
