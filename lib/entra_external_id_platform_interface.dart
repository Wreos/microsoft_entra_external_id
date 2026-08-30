import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'src/native_sdk_status.dart';
import 'src/pigeon_entra_external_id_platform.dart';

abstract class EntraExternalIdPlatform extends PlatformInterface {
  /// Constructs a EntraExternalIdPlatform.
  EntraExternalIdPlatform() : super(token: _token);

  static final Object _token = Object();

  static EntraExternalIdPlatform _instance = PigeonEntraExternalIdPlatform();

  /// The default instance of [EntraExternalIdPlatform] to use.
  ///
  /// Defaults to [PigeonEntraExternalIdPlatform].
  static EntraExternalIdPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [EntraExternalIdPlatform] when
  /// they register themselves.
  static set instance(EntraExternalIdPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<NativeSdkStatus> getNativeSdkStatus() {
    throw UnimplementedError('getNativeSdkStatus() has not been implemented.');
  }
}
