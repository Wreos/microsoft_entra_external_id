import 'package:entra_external_id/entra_external_id.dart';
import 'package:entra_external_id/entra_external_id_platform_interface.dart';
import 'package:entra_external_id/src/pigeon_entra_external_id_platform.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEntraExternalIdPlatform
    with MockPlatformInterfaceMixin
    implements EntraExternalIdPlatform {
  @override
  Future<NativeSdkStatus> getNativeSdkStatus() async => const NativeSdkStatus(
    platform: NativePlatform.android,
    linked: true,
    sdkVersion: 'test-version',
  );
}

void main() {
  test('$PigeonEntraExternalIdPlatform is the default instance', () {
    expect(
      EntraExternalIdPlatform.instance,
      isInstanceOf<PigeonEntraExternalIdPlatform>(),
    );
  });

  test('getNativeSdkStatus delegates to the platform implementation', () async {
    final fakePlatform = MockEntraExternalIdPlatform();
    final plugin = EntraExternalId(platform: fakePlatform);

    expect(
      await plugin.getNativeSdkStatus(),
      const NativeSdkStatus(
        platform: NativePlatform.android,
        linked: true,
        sdkVersion: 'test-version',
      ),
    );
  });
}
