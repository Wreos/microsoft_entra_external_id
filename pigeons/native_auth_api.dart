import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/generated/native_auth_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut: 'android/src/main/kotlin/io/github/wreos/microsoft_entra_external_id/NativeAuthApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'io.github.wreos.microsoft_entra_external_id',
    ),
    swiftOut: 'ios/microsoft_entra_external_id/Sources/microsoft_entra_external_id/NativeAuthApi.g.swift',
    swiftOptions: SwiftOptions(),
    dartPackageName: 'microsoft_entra_external_id',
  ),
)
enum NativePlatformMessage { android, ios }

enum NativeAuthOperationMessage { signIn, signUp }

enum NativeAuthResultTypeMessage {
  initialized,
  signedOut,
  codeRequired,
  passwordRequired,
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

class NativeAuthSignInParametersMessage {
  NativeAuthSignInParametersMessage({
    required this.username,
    required this.scopes,
    this.password,
  });

  String username;
  String? password;
  List<String> scopes;
}

class NativeAuthAccessTokenParametersMessage {
  NativeAuthAccessTokenParametersMessage({
    required this.scopes,
    required this.forceRefresh,
  });

  List<String> scopes;
  bool forceRefresh;
}

class NativeAuthResultMessage {
  NativeAuthResultMessage({
    required this.type,
    this.operation,
    this.continuationId,
    this.username,
    this.idToken,
    this.accessToken,
    this.scopes,
    this.expiresAtEpochMilliseconds,
    this.sentTo,
    this.codeLength,
    this.errorCode,
    this.errorMessage,
  });

  NativeAuthResultTypeMessage type;
  NativeAuthOperationMessage? operation;
  String? continuationId;
  String? username;
  String? idToken;
  String? accessToken;
  List<String>? scopes;
  int? expiresAtEpochMilliseconds;
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
  NativeAuthResultMessage startSignIn(
    NativeAuthSignInParametersMessage parameters,
  );

  @async
  NativeAuthResultMessage startSignUp(String username);

  @async
  NativeAuthResultMessage submitCode(String continuationId, String code);

  @async
  NativeAuthResultMessage submitPassword(
    String continuationId,
    String password,
  );

  @async
  NativeAuthResultMessage resendCode(String continuationId);

  @async
  NativeAuthResultMessage getAccessToken(
    NativeAuthAccessTokenParametersMessage parameters,
  );

  @async
  NativeAuthResultMessage signOut();
}
