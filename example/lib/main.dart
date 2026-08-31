import 'package:microsoft_entra_external_id/microsoft_entra_external_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _clientId = String.fromEnvironment('ENTRA_CLIENT_ID');
const _tenantSubdomain = String.fromEnvironment('ENTRA_TENANT_SUBDOMAIN');

void main() {
  runApp(const NativeAuthExampleApp());
}

class NativeAuthExampleApp extends StatelessWidget {
  const NativeAuthExampleApp({
    super.key,
    this.clientId = _clientId,
    this.tenantSubdomain = _tenantSubdomain,
    this.plugin,
  });

  final String clientId;
  final String tenantSubdomain;
  final MicrosoftEntraExternalId? plugin;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Microsoft Entra External ID Native Auth',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: NativeAuthHomePage(
        clientId: clientId,
        tenantSubdomain: tenantSubdomain,
        plugin: plugin,
      ),
    );
  }
}

class NativeAuthHomePage extends StatefulWidget {
  const NativeAuthHomePage({
    required this.clientId,
    required this.tenantSubdomain,
    super.key,
    this.plugin,
  });

  final String clientId;
  final String tenantSubdomain;
  final MicrosoftEntraExternalId? plugin;

  @override
  State<NativeAuthHomePage> createState() => _NativeAuthHomePageState();
}

class _NativeAuthHomePageState extends State<NativeAuthHomePage> {
  late final MicrosoftEntraExternalId _plugin;
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  bool _busy = false;
  String _status = 'Initializing native authentication...';
  NativeAuthCodeRequired? _codeRequired;
  NativeAuthSignedIn? _signedIn;

  bool get _configured =>
      widget.clientId.trim().isNotEmpty &&
      widget.tenantSubdomain.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _plugin = widget.plugin ?? MicrosoftEntraExternalId();
    if (_configured) {
      _initialize();
    } else {
      _status = 'Add your External ID app configuration to run the example.';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _perform(() async {
      final initialized = await _plugin.initialize(
        NativeAuthConfiguration(
          clientId: widget.clientId,
          tenantSubdomain: widget.tenantSubdomain,
        ),
      );
      if (initialized is NativeAuthFailure) return initialized;
      return _plugin.getCurrentAccount();
    });
  }

  Future<void> _signIn() =>
      _startEmailFlow(_plugin.signIn, progress: 'Starting sign in...');

  Future<void> _signUp() =>
      _startEmailFlow(_plugin.signUp, progress: 'Starting sign up...');

  Future<void> _startEmailFlow(
    Future<NativeAuthState> Function(String username) action, {
    required String progress,
  }) async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _status = 'Enter a valid email address.');
      return;
    }
    await _perform(() => action(email), progress: progress);
  }

  Future<void> _submitCode() async {
    final continuation = _codeRequired;
    if (continuation == null) return;
    final code = _codeController.text.trim();
    final expectedLength = continuation.codeLength;
    if (code.isEmpty ||
        (expectedLength != null && code.length != expectedLength)) {
      setState(() {
        _status = expectedLength == null
            ? 'Enter the verification code.'
            : 'Enter the $expectedLength-digit verification code.';
      });
      return;
    }
    _codeController.clear();
    await _perform(
      () => _plugin.submitCode(continuation, code),
      progress: 'Verifying code...',
    );
  }

  Future<void> _resendCode() async {
    final continuation = _codeRequired;
    if (continuation == null) return;
    _codeController.clear();
    await _perform(
      () => _plugin.resendCode(continuation),
      progress: 'Sending a new code...',
    );
  }

  Future<void> _signOut() =>
      _perform(_plugin.signOut, progress: 'Signing out...');

  void _useAnotherEmail() {
    if (_busy) return;
    setState(() {
      _codeRequired = null;
      _codeController.clear();
      _status = 'Enter an email to sign in or create an account.';
    });
  }

  Future<void> _perform(
    Future<NativeAuthState> Function() action, {
    String? progress,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      if (progress != null) _status = progress;
    });

    try {
      final result = await action();
      if (!mounted) return;
      setState(() => _apply(result));
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _status = 'Unexpected error: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _apply(NativeAuthState state) {
    switch (state) {
      case NativeAuthInitialized():
        _status = 'Native authentication is ready.';
      case NativeAuthSignedOut():
        _signedIn = null;
        _codeRequired = null;
        _codeController.clear();
        _status = 'Enter an email to sign in or create an account.';
      case final NativeAuthCodeRequired state:
        _codeRequired = state;
        _status = state.sentTo == null
            ? 'Enter the verification code.'
            : 'Verification code sent to ${state.sentTo}.';
      case final NativeAuthSignedIn state:
        _signedIn = state;
        _codeRequired = null;
        _codeController.clear();
        _status = 'Signed in successfully.';
      case final NativeAuthFailure state:
        _status = state.browserRequired
            ? '${state.message} System-browser fallback is required.'
            : state.message;
    }
  }

  static bool _isValidEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Microsoft Entra External ID')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Native Authentication',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Custom Flutter UI backed directly by the official MSAL '
                  'Android and iOS SDKs. No embedded WebView.',
                ),
                const SizedBox(height: 24),
                if (!_configured)
                  const _ConfigurationCard()
                else ...[
                  if (_busy) const LinearProgressIndicator(),
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Text(_status, key: const Key('status')),
                  ),
                  const SizedBox(height: 24),
                  if (_signedIn case final account?)
                    _SignedInCard(
                      username: account.username,
                      busy: _busy,
                      onSignOut: _signOut,
                    )
                  else if (_codeRequired case final codeState?)
                    _CodeForm(
                      controller: _codeController,
                      codeLength: codeState.codeLength,
                      busy: _busy,
                      onSubmit: _submitCode,
                      onResend: _resendCode,
                      onUseAnotherEmail: _useAnotherEmail,
                    )
                  else
                    _EmailForm(
                      controller: _emailController,
                      busy: _busy,
                      onSignIn: _signIn,
                      onSignUp: _signUp,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfigurationCard extends StatelessWidget {
  const _ConfigurationCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration required',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const SelectableText(
              'flutter run --dart-define=ENTRA_CLIENT_ID=<client-id> '
              '--dart-define=ENTRA_TENANT_SUBDOMAIN=<tenant-prefix>',
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailForm extends StatelessWidget {
  const _EmailForm({
    required this.controller,
    required this.busy,
    required this.onSignIn,
    required this.onSignUp,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          key: const Key('email'),
          controller: controller,
          enabled: !busy,
          keyboardType: TextInputType.emailAddress,
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Email',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                key: const Key('signIn'),
                onPressed: busy ? null : onSignIn,
                child: const Text('Sign in'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                key: const Key('signUp'),
                onPressed: busy ? null : onSignUp,
                child: const Text('Sign up'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CodeForm extends StatelessWidget {
  const _CodeForm({
    required this.controller,
    required this.codeLength,
    required this.busy,
    required this.onSubmit,
    required this.onResend,
    required this.onUseAnotherEmail,
  });

  final TextEditingController controller;
  final int? codeLength;
  final bool busy;
  final VoidCallback onSubmit;
  final VoidCallback onResend;
  final VoidCallback onUseAnotherEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          key: const Key('code'),
          controller: controller,
          enabled: !busy,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.done,
          onSubmitted: busy ? null : (_) => onSubmit(),
          autofillHints: const [AutofillHints.oneTimeCode],
          maxLength: codeLength,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Verification code',
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('verifyCode'),
            onPressed: busy ? null : onSubmit,
            child: const Text('Verify code'),
          ),
        ),
        TextButton(
          key: const Key('resendCode'),
          onPressed: busy ? null : onResend,
          child: const Text('Resend code'),
        ),
        TextButton(
          key: const Key('useAnotherEmail'),
          onPressed: busy ? null : onUseAnotherEmail,
          child: const Text('Use another email'),
        ),
      ],
    );
  }
}

class _SignedInCard extends StatelessWidget {
  const _SignedInCard({
    required this.username,
    required this.busy,
    required this.onSignOut,
  });

  final String? username;
  final bool busy;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.verified_user, size: 48),
            const SizedBox(height: 12),
            Text(username ?? 'Signed-in account'),
            const SizedBox(height: 16),
            FilledButton.tonal(
              key: const Key('signOut'),
              onPressed: busy ? null : onSignOut,
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
