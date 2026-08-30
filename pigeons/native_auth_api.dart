import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/generated/native_auth_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut: 'android/src/main/kotlin/io/github/wreos/entra_external_id/NativeAuthApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'io.github.wreos.entra_external_id'),
    swiftOut:
        'ios/entra_external_id/Sources/entra_external_id/NativeAuthApi.g.swift',
    swiftOptions: SwiftOptions(),
    dartPackageName: 'entra_external_id',
  ),
)
enum NativePlatformMessage { android, ios }

class NativeSdkStatusMessage {
  NativeSdkStatusMessage({
    required this.platform,
    required this.linked,
    this.sdkVersion,
  });

  NativePlatformMessage platform;
  bool linked;
  String? sdkVersion;
}

@HostApi()
abstract class NativeAuthHostApi {
  NativeSdkStatusMessage getNativeSdkStatus();
}
