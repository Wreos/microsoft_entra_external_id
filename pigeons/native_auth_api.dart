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

enum NativeAuthOperationMessage { signIn, signUp }

enum NativeAuthResultTypeMessage {
  initialized,
  signedOut,
  codeRequired,
  signedIn,
  error,
  browserRequired,
}

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

class NativeAuthConfigurationMessage {
  NativeAuthConfigurationMessage({
    required this.clientId,
    required this.tenantSubdomain,
  });

  String clientId;
  String tenantSubdomain;
}

class NativeAuthResultMessage {
  NativeAuthResultMessage({
    required this.type,
    this.operation,
    this.continuationId,
    this.username,
    this.sentTo,
    this.codeLength,
    this.errorCode,
    this.errorMessage,
  });

  NativeAuthResultTypeMessage type;
  NativeAuthOperationMessage? operation;
  String? continuationId;
  String? username;
  String? sentTo;
  int? codeLength;
  String? errorCode;
  String? errorMessage;
}

@HostApi()
abstract class NativeAuthHostApi {
  NativeSdkStatusMessage getNativeSdkStatus();

  @async
  NativeAuthResultMessage initialize(
    NativeAuthConfigurationMessage configuration,
  );

  @async
  NativeAuthResultMessage getCurrentAccount();

  @async
  NativeAuthResultMessage startSignIn(String username);

  @async
  NativeAuthResultMessage startSignUp(String username);

  @async
  NativeAuthResultMessage submitCode(String continuationId, String code);

  @async
  NativeAuthResultMessage resendCode(String continuationId);

  @async
  NativeAuthResultMessage signOut();
}
