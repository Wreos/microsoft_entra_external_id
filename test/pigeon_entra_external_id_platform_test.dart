import 'package:entra_external_id/entra_external_id.dart';
import 'package:entra_external_id/src/generated/native_auth_api.g.dart'
    as pigeon;
import 'package:entra_external_id/src/pigeon_entra_external_id_platform.dart';
import 'package:flutter_test/flutter_test.dart';

final class FakeNativeAuthHostApi extends pigeon.NativeAuthHostApi {
  FakeNativeAuthHostApi(this.message);

  final pigeon.NativeSdkStatusMessage message;

  @override
  Future<pigeon.NativeSdkStatusMessage> getNativeSdkStatus() async => message;
}

void main() {
  test('maps Android SDK status without exposing generated types', () async {
    final platform = PigeonEntraExternalIdPlatform(
      hostApi: FakeNativeAuthHostApi(
        pigeon.NativeSdkStatusMessage(
          platform: pigeon.NativePlatformMessage.android,
          linked: false,
        ),
      ),
    );

    expect(
      await platform.getNativeSdkStatus(),
      const NativeSdkStatus(platform: NativePlatform.android, linked: false),
    );
  });

  test('maps iOS SDK version when linked', () async {
    final platform = PigeonEntraExternalIdPlatform(
      hostApi: FakeNativeAuthHostApi(
        pigeon.NativeSdkStatusMessage(
          platform: pigeon.NativePlatformMessage.ios,
          linked: true,
          sdkVersion: 'test-version',
        ),
      ),
    );

    expect(
      await platform.getNativeSdkStatus(),
      const NativeSdkStatus(
        platform: NativePlatform.ios,
        linked: true,
        sdkVersion: 'test-version',
      ),
    );
  });
}
