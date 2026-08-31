import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'src/native_auth_state.dart';
import 'src/native_sdk_status.dart';
import 'src/pigeon_microsoft_entra_external_id_platform.dart';

abstract class MicrosoftEntraExternalIdPlatform extends PlatformInterface {
  /// Constructs a MicrosoftEntraExternalIdPlatform.
  MicrosoftEntraExternalIdPlatform() : super(token: _token);

  static final Object _token = Object();

  static MicrosoftEntraExternalIdPlatform _instance =
      PigeonMicrosoftEntraExternalIdPlatform();

  /// The default instance of [MicrosoftEntraExternalIdPlatform] to use.
  ///
  /// Defaults to [PigeonMicrosoftEntraExternalIdPlatform].
  static MicrosoftEntraExternalIdPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MicrosoftEntraExternalIdPlatform] when
  /// they register themselves.
  static set instance(MicrosoftEntraExternalIdPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<NativeSdkStatus> getNativeSdkStatus() {
    throw UnimplementedError('getNativeSdkStatus() has not been implemented.');
  }

  Future<NativeAuthState> initialize(NativeAuthConfiguration configuration) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<NativeAuthState> getCurrentAccount() {
    throw UnimplementedError('getCurrentAccount() has not been implemented.');
  }

  Future<NativeAuthState> signIn(
    String username, {
    String? password,
    List<String> scopes = const [],
  }) {
    throw UnimplementedError('signIn() has not been implemented.');
  }

  Future<NativeAuthState> signUp(String username) {
    throw UnimplementedError('signUp() has not been implemented.');
  }

  Future<NativeAuthState> submitCode(String continuationId, String code) {
    throw UnimplementedError('submitCode() has not been implemented.');
  }

  Future<NativeAuthState> submitPassword(
    String continuationId,
    String password,
  ) {
    throw UnimplementedError('submitPassword() has not been implemented.');
  }

  Future<NativeAuthState> resendCode(String continuationId) {
    throw UnimplementedError('resendCode() has not been implemented.');
  }

  Future<NativeAuthState> getAccessToken({
    List<String> scopes = const [],
    bool forceRefresh = false,
  }) {
    throw UnimplementedError('getAccessToken() has not been implemented.');
  }

  Future<NativeAuthState> signOut() {
    throw UnimplementedError('signOut() has not been implemented.');
  }
}
