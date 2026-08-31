import 'package:microsoft_entra_external_id/microsoft_entra_external_id.dart';
import 'package:microsoft_entra_external_id/microsoft_entra_external_id_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:microsoft_entra_external_id_example/main.dart';

final class FakeNativeAuthPlatform extends MicrosoftEntraExternalIdPlatform {
  FakeNativeAuthPlatform({this.requirePasswordContinuation = false});

  final bool requirePasswordContinuation;
  int signInCalls = 0;
  int submitCodeCalls = 0;
  int submitPasswordCalls = 0;
  int refreshTokenCalls = 0;
  String? submittedPassword;

  @override
  Future<NativeSdkStatus> getNativeSdkStatus() async => const NativeSdkStatus(
    platform: NativePlatform.android,
    linked: true,
    sdkVersion: 'test',
  );

  @override
  Future<NativeAuthState> initialize(
    NativeAuthConfiguration configuration,
  ) async => const NativeAuthInitialized();

  @override
  Future<NativeAuthState> getCurrentAccount() async =>
      const NativeAuthSignedOut();

  @override
  Future<NativeAuthState> signIn(
    String username, {
    String? password,
    List<String> scopes = const [],
  }) async {
    signInCalls += 1;
    if (password != null) {
      submittedPassword = password;
      return _signedIn();
    }
    if (requirePasswordContinuation) {
      return const NativeAuthPasswordRequired(
        operation: NativeAuthOperation.signIn,
        continuationId: 'password-id',
      );
    }
    return const NativeAuthCodeRequired(
      operation: NativeAuthOperation.signIn,
      continuationId: 'sign-in-id',
      sentTo: 'u***@example.com',
      codeLength: 6,
    );
  }

  @override
  Future<NativeAuthState> signUp(String username) async =>
      const NativeAuthCodeRequired(
        operation: NativeAuthOperation.signUp,
        continuationId: 'sign-up-id',
        codeLength: 6,
      );

  @override
  Future<NativeAuthState> submitCode(String continuationId, String code) async {
    submitCodeCalls += 1;
    return _signedIn();
  }

  @override
  Future<NativeAuthState> submitPassword(
    String continuationId,
    String password,
  ) async {
    submitPasswordCalls += 1;
    submittedPassword = password;
    return _signedIn();
  }

  @override
  Future<NativeAuthState> resendCode(String continuationId) async =>
      const NativeAuthCodeRequired(
        operation: NativeAuthOperation.signIn,
        continuationId: 'resent-id',
        codeLength: 6,
      );

  @override
  Future<NativeAuthState> getAccessToken({
    List<String> scopes = const [],
    bool forceRefresh = false,
  }) async {
    refreshTokenCalls += 1;
    return _signedIn(scopes: scopes);
  }

  @override
  Future<NativeAuthState> signOut() async => const NativeAuthSignedOut();

  NativeAuthSignedIn _signedIn({List<String> scopes = const ['openid']}) =>
      NativeAuthSignedIn(
        account: const NativeAuthAccount(
          username: 'user@example.com',
          idToken: 'id-token',
        ),
        token: NativeAuthToken(
          accessToken: 'access-token',
          scopes: scopes,
          expiresAt: DateTime.utc(2030),
        ),
      );
}

void main() {
  testWidgets('explains how to configure the example', (tester) async {
    await tester.pumpWidget(const NativeAuthExampleApp());

    expect(find.text('Configuration required'), findsOneWidget);
    expect(find.byKey(const Key('signIn')), findsNothing);
  });

  testWidgets('runs the email OTP sign-in UI flow', (tester) async {
    final platform = FakeNativeAuthPlatform();
    final plugin = MicrosoftEntraExternalId(platform: platform);
    await tester.pumpWidget(
      NativeAuthExampleApp(
        clientId: 'client-id',
        tenantSubdomain: 'contoso',
        plugin: plugin,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('email')), findsOneWidget);
    await tester.tap(find.byKey(const Key('signIn')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(platform.signInCalls, 0);

    await tester.enterText(find.byKey(const Key('email')), 'user@example.com');
    await tester.tap(find.byKey(const Key('signIn')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('code')), findsOneWidget);
    expect(
      find.text('Verification code sent to u***@example.com.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('useAnotherEmail')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('email')), findsOneWidget);

    await tester.tap(find.byKey(const Key('signIn')));
    await tester.pumpAndSettle();
    expect(platform.signInCalls, 2);

    await tester.tap(find.byKey(const Key('verifyCode')));
    await tester.pumpAndSettle();
    expect(find.text('Enter the 6-digit verification code.'), findsOneWidget);
    expect(platform.submitCodeCalls, 0);

    await tester.enterText(find.byKey(const Key('code')), '123456');
    await tester.tap(find.byKey(const Key('verifyCode')));
    await tester.pumpAndSettle();
    expect(platform.submitCodeCalls, 1);

    expect(find.text('Signed in successfully.'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.text('ID token: available'), findsOneWidget);
    await tester.tap(find.byKey(const Key('refreshToken')));
    await tester.pumpAndSettle();
    expect(platform.refreshTokenCalls, 1);
    await tester.tap(find.byKey(const Key('signOut')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('email')), findsOneWidget);
  });

  testWidgets('runs direct password sign-in without persisting the password', (
    tester,
  ) async {
    final platform = FakeNativeAuthPlatform();
    await tester.pumpWidget(
      NativeAuthExampleApp(
        clientId: 'client-id',
        tenantSubdomain: 'contoso',
        plugin: MicrosoftEntraExternalId(platform: platform),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('email')), 'user@example.com');
    await tester.enterText(find.byKey(const Key('password')), 'secret value');
    await tester.tap(find.byKey(const Key('signIn')));
    await tester.pumpAndSettle();

    expect(platform.submittedPassword, 'secret value');
    expect(find.text('Signed in successfully.'), findsOneWidget);
    expect(find.text('secret value'), findsNothing);
  });

  testWidgets('submits a server-driven password continuation', (tester) async {
    final platform = FakeNativeAuthPlatform(requirePasswordContinuation: true);
    await tester.pumpWidget(
      NativeAuthExampleApp(
        clientId: 'client-id',
        tenantSubdomain: 'contoso',
        plugin: MicrosoftEntraExternalId(platform: platform),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('email')), 'user@example.com');
    await tester.tap(find.byKey(const Key('signIn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('requiredPassword')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('requiredPassword')),
      'secret value',
    );
    await tester.tap(find.byKey(const Key('submitPassword')));
    await tester.pumpAndSettle();

    expect(platform.submitPasswordCalls, 1);
    expect(platform.submittedPassword, 'secret value');
    expect(find.text('Signed in successfully.'), findsOneWidget);
  });
}
