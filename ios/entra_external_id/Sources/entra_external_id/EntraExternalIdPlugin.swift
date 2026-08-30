import Flutter

public class EntraExternalIdPlugin: NSObject, FlutterPlugin, NativeAuthHostApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = EntraExternalIdPlugin()
    NativeAuthHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  func getNativeSdkStatus() throws -> NativeSdkStatusMessage {
    NativeSdkStatusMessage(platform: .ios, linked: false, sdkVersion: nil)
  }
}
