import '../entra_external_id_platform_interface.dart';
import 'generated/native_auth_api.g.dart' as pigeon;
import 'native_sdk_status.dart';

/// Pigeon-backed implementation of the platform bridge.
final class PigeonEntraExternalIdPlatform extends EntraExternalIdPlatform {
  PigeonEntraExternalIdPlatform({pigeon.NativeAuthHostApi? hostApi})
    : _hostApi = hostApi ?? pigeon.NativeAuthHostApi();

  final pigeon.NativeAuthHostApi _hostApi;

  @override
  Future<NativeSdkStatus> getNativeSdkStatus() async {
    final message = await _hostApi.getNativeSdkStatus();
    return NativeSdkStatus(
      platform: switch (message.platform) {
        pigeon.NativePlatformMessage.android => NativePlatform.android,
        pigeon.NativePlatformMessage.ios => NativePlatform.ios,
      },
      linked: message.linked,
      sdkVersion: message.sdkVersion,
    );
  }
}
