import 'entra_external_id_platform_interface.dart';
import 'src/native_sdk_status.dart';

export 'src/native_sdk_status.dart';

/// Entry point for the Entra External ID native authentication bridge.
///
/// The bootstrap exposes only native SDK linkage diagnostics. Authentication
/// methods are added after the cross-platform contract gate is complete.
class EntraExternalId {
  EntraExternalId({EntraExternalIdPlatform? platform})
    : _platform = platform ?? EntraExternalIdPlatform.instance;

  final EntraExternalIdPlatform _platform;

  /// Returns whether the official MSAL SDK is linked on the current platform.
  Future<NativeSdkStatus> getNativeSdkStatus() =>
      _platform.getNativeSdkStatus();
}
