import 'package:entra_external_id/entra_external_id.dart';
import 'package:entra_external_id/entra_external_id_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:entra_external_id_example/main.dart';

final class FakeNativeAuthPlatform extends EntraExternalIdPlatform {
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
  Future<NativeAuthState> signIn(String username) async =>
      const NativeAuthCodeRequired(
        operation: NativeAuthOperation.signIn,
        continuationId: 'sign-in-id',
        sentTo: 'u***@example.com',
        codeLength: 6,
      );

  @override
  Future<NativeAuthState> signUp(String username) async =>
      const NativeAuthCodeRequired(
        operation: NativeAuthOperation.signUp,
        continuationId: 'sign-up-id',
        codeLength: 6,
      );

  @override
  Future<NativeAuthState> submitCode(
    String continuationId,
    String code,
  ) async => const NativeAuthSignedIn(username: 'user@example.com');

  @override
  Future<NativeAuthState> resendCode(String continuationId) async =>
      const NativeAuthCodeRequired(
        operation: NativeAuthOperation.signIn,
        continuationId: 'resent-id',
        codeLength: 6,
      );

  @override
  Future<NativeAuthState> signOut() async => const NativeAuthSignedOut();
}

void main() {
  testWidgets('explains how to configure the example', (tester) async {
    await tester.pumpWidget(const NativeAuthExampleApp());

    expect(find.text('Configuration required'), findsOneWidget);
    expect(find.byKey(const Key('signIn')), findsNothing);
  });

  testWidgets('runs the email OTP sign-in UI flow', (tester) async {
    final plugin = EntraExternalId(platform: FakeNativeAuthPlatform());
    await tester.pumpWidget(
      NativeAuthExampleApp(
        clientId: 'client-id',
        tenantSubdomain: 'contoso',
        plugin: plugin,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('email')), findsOneWidget);
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
    await tester.enterText(find.byKey(const Key('code')), '123456');
    await tester.tap(find.byKey(const Key('verifyCode')));
    await tester.pumpAndSettle();

    expect(find.text('Signed in successfully.'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    await tester.tap(find.byKey(const Key('signOut')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('email')), findsOneWidget);
  });
}
