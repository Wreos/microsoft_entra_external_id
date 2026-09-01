import 'package:microsoft_entra_external_id/microsoft_entra_external_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _clientId = String.fromEnvironment('ENTRA_CLIENT_ID');
const _tenantSubdomain = String.fromEnvironment('ENTRA_TENANT_SUBDOMAIN');
const _apiScope = String.fromEnvironment('ENTRA_API_SCOPE');
const _redirectUri = String.fromEnvironment('ENTRA_REDIRECT_URI');

void main() {
  runApp(const NativeAuthExampleApp());
}

class NativeAuthExampleApp extends StatelessWidget {
  const NativeAuthExampleApp({
    super.key,
    this.clientId = _clientId,
    this.tenantSubdomain = _tenantSubdomain,
    this.redirectUri = _redirectUri,
    this.plugin,
  });

  final String clientId;
  final String tenantSubdomain;
  final String redirectUri;
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
        redirectUri: redirectUri,
        plugin: plugin,
      ),
    );
  }
}

class NativeAuthHomePage extends StatefulWidget {
  const NativeAuthHomePage({
    required this.clientId,
    required this.tenantSubdomain,
    this.redirectUri = _redirectUri,
    super.key,
    this.plugin,
  });

  final String clientId;
  final String tenantSubdomain;
  final String redirectUri;
  final MicrosoftEntraExternalId? plugin;

  @override
  State<NativeAuthHomePage> createState() => _NativeAuthHomePageState();
}

class _NativeAuthHomePageState extends State<NativeAuthHomePage> {
  late final MicrosoftEntraExternalId _plugin;
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _busy = false;
  String _status = 'Initializing native authentication...';
  NativeAuthCodeRequired? _codeRequired;
  NativeAuthPasswordRequired? _passwordRequired;
  NativeAuthAttributesRequired? _attributesRequired;
  NativeAuthSignedIn? _signedIn;
  NativeAuthFailure? _browserFailure;
  final _attributeControllers = <String, TextEditingController>{};

  List<String> get _scopes => _apiScope.isEmpty ? const [] : [_apiScope];

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
    _passwordController.dispose();
    for (final controller in _attributeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    await _perform(() async {
      final initialized = await _plugin.initialize(
        NativeAuthConfiguration(
          clientId: widget.clientId,
          tenantSubdomain: widget.tenantSubdomain,
          redirectUri: widget.redirectUri.isEmpty ? null : widget.redirectUri,
        ),
      );
      if (initialized is NativeAuthFailure) return initialized;
      return _plugin.getCurrentAccount();
    });
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _status = 'Enter a valid email address.');
      return;
    }
    final password = _passwordController.text;
    _passwordController.clear();
    await _perform(
      () => password.isEmpty
          ? _plugin.signIn(email, scopes: _scopes)
          : _plugin.signInWithPassword(email, password, scopes: _scopes),
      progress: 'Starting sign in...',
    );
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _status = 'Enter a valid email address.');
      return;
    }
    final password = _passwordController.text;
    _passwordController.clear();
    await _perform(
      () => password.isEmpty
          ? _plugin.signUp(email)
          : _plugin.signUpWithPassword(email, password),
      progress: 'Starting sign up...',
    );
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _status = 'Enter a valid email address.');
      return;
    }
    _passwordController.clear();
    await _perform(
      () => _plugin.resetPassword(email, scopes: _scopes),
      progress: 'Starting password reset...',
    );
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

  Future<void> _submitPassword() async {
    final continuation = _passwordRequired;
    if (continuation == null) return;
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _status = 'Enter your password.');
      return;
    }
    _passwordController.clear();
    await _perform(
      () => _plugin.submitPassword(continuation, password),
      progress: 'Verifying password...',
    );
  }

  Future<void> _submitAttributes() async {
    final state = _attributesRequired;
    if (state == null) return;
    final attributes = <String, String>{
      for (final entry in _attributeControllers.entries)
        entry.key: entry.value.text,
    };
    for (final controller in _attributeControllers.values) {
      controller.clear();
    }
    await _perform(
      () => _plugin.submitAttributes(state, attributes),
      progress: 'Submitting account details...',
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

  Future<void> _refreshToken() => _perform(
    () => _plugin.getAccessToken(scopes: _scopes, forceRefresh: true),
    progress: 'Refreshing access token...',
  );

  Future<void> _continueInBrowser() {
    final loginHint = _emailController.text.trim();
    final scopes = _scopes.isEmpty
        ? const ['openid', 'profile', 'email']
        : _scopes;
    return _perform(
      () => _plugin.signInWithBrowser(loginHint: loginHint, scopes: scopes),
      progress: 'Opening system browser...',
    );
  }

  void _useAnotherEmail() {
    if (_busy) return;
    setState(() {
      _codeRequired = null;
      _passwordRequired = null;
      _attributesRequired = null;
      _clearAttributeControllers();
      _codeController.clear();
      _passwordController.clear();
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
        _browserFailure = null;
        _status = 'Native authentication is ready.';
      case NativeAuthSignedOut():
        _browserFailure = null;
        _signedIn = null;
        _codeRequired = null;
        _passwordRequired = null;
        _attributesRequired = null;
        _clearAttributeControllers();
        _codeController.clear();
        _passwordController.clear();
        _status = 'Enter an email to sign in or create an account.';
      case final NativeAuthCodeRequired state:
        _browserFailure = null;
        _codeRequired = state;
        _passwordRequired = null;
        _attributesRequired = null;
        _clearAttributeControllers();
        _status = state.sentTo == null
            ? 'Enter the verification code.'
            : 'Verification code sent to ${state.sentTo}.';
      case final NativeAuthPasswordRequired state:
        _browserFailure = null;
        _passwordRequired = state;
        _codeRequired = null;
        _attributesRequired = null;
        _clearAttributeControllers();
        _status = 'Enter the password for this account.';
      case final NativeAuthAttributesRequired state:
        _browserFailure = null;
        _attributesRequired = state;
        _codeRequired = null;
        _passwordRequired = null;
        _signedIn = null;
        _clearAttributeControllers();
        for (final attribute in state.requiredAttributes) {
          _attributeControllers[attribute.name] = TextEditingController();
        }
        _status = state.invalidAttributeNames.isEmpty
            ? 'Enter the required account details.'
            : 'Some account details were rejected. Check the highlighted fields.';
      case final NativeAuthSignedIn state:
        _browserFailure = null;
        _signedIn = state;
        _codeRequired = null;
        _passwordRequired = null;
        _attributesRequired = null;
        _clearAttributeControllers();
        _codeController.clear();
        _passwordController.clear();
        _status = 'Signed in successfully.';
      case final NativeAuthFailure state:
        _browserFailure = state.browserRequired ? state : null;
        _status = state.browserRequired
            ? '${state.message} System-browser fallback is required.'
            : state.message;
    }
  }

  void _clearAttributeControllers() {
    for (final controller in _attributeControllers.values) {
      controller.dispose();
    }
    _attributeControllers.clear();
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
                  if (_browserFailure != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('browserFallback'),
                      onPressed: _busy ? null : _continueInBrowser,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Continue in system browser'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_signedIn case final account?)
                    _SignedInCard(
                      username: account.username,
                      hasIdToken: account.idToken != null,
                      scopes: account.token.scopes,
                      expiresAt: account.token.expiresAt,
                      busy: _busy,
                      onRefreshToken: _refreshToken,
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
                  else if (_passwordRequired != null)
                    _PasswordForm(
                      controller: _passwordController,
                      operation: _passwordRequired!.operation,
                      busy: _busy,
                      onSubmit: _submitPassword,
                      onUseAnotherEmail: _useAnotherEmail,
                    )
                  else if (_attributesRequired case final attributesState?)
                    _AttributesForm(
                      state: attributesState,
                      controllers: _attributeControllers,
                      busy: _busy,
                      onSubmit: _submitAttributes,
                      onUseAnotherEmail: _useAnotherEmail,
                    )
                  else
                    _EmailForm(
                      controller: _emailController,
                      passwordController: _passwordController,
                      busy: _busy,
                      onSignIn: _signIn,
                      onSignUp: _signUp,
                      onResetPassword: _resetPassword,
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
              '--dart-define=ENTRA_TENANT_SUBDOMAIN=<tenant-prefix> '
              '--dart-define=ENTRA_REDIRECT_URI=<registered-redirect-uri>',
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
    required this.passwordController,
    required this.busy,
    required this.onSignIn,
    required this.onSignUp,
    required this.onResetPassword,
  });

  final TextEditingController controller;
  final TextEditingController passwordController;
  final bool busy;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;
  final VoidCallback onResetPassword;

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
        TextField(
          key: const Key('password'),
          controller: passwordController,
          enabled: !busy,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Password (leave empty for email OTP)',
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
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const Key('resetPassword'),
            onPressed: busy ? null : onResetPassword,
            child: const Text('Forgot password?'),
          ),
        ),
      ],
    );
  }
}

class _PasswordForm extends StatelessWidget {
  const _PasswordForm({
    required this.controller,
    required this.operation,
    required this.busy,
    required this.onSubmit,
    required this.onUseAnotherEmail,
  });

  final TextEditingController controller;
  final NativeAuthOperation operation;
  final bool busy;
  final VoidCallback onSubmit;
  final VoidCallback onUseAnotherEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          key: const Key('requiredPassword'),
          controller: controller,
          enabled: !busy,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onSubmitted: busy ? null : (_) => onSubmit(),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Password',
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('submitPassword'),
            onPressed: busy ? null : onSubmit,
            child: Text(switch (operation) {
              NativeAuthOperation.signIn => 'Sign in',
              NativeAuthOperation.signUp => 'Create account',
              NativeAuthOperation.passwordReset => 'Set new password',
            }),
          ),
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

class _AttributesForm extends StatelessWidget {
  const _AttributesForm({
    required this.state,
    required this.controllers,
    required this.busy,
    required this.onSubmit,
    required this.onUseAnotherEmail,
  });

  final NativeAuthAttributesRequired state;
  final Map<String, TextEditingController> controllers;
  final bool busy;
  final VoidCallback onSubmit;
  final VoidCallback onUseAnotherEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final attribute in state.requiredAttributes) ...[
          TextField(
            key: Key('attribute_${attribute.name}'),
            controller: controllers[attribute.name],
            enabled: !busy,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: attribute.name,
              helperText: attribute.regex == null
                  ? attribute.type
                  : '${attribute.type} · ${attribute.regex}',
              errorText: state.invalidAttributeNames.contains(attribute.name)
                  ? 'This value was rejected.'
                  : null,
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('submitAttributes'),
            onPressed: busy ? null : onSubmit,
            child: const Text('Continue'),
          ),
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
    required this.hasIdToken,
    required this.scopes,
    required this.expiresAt,
    required this.busy,
    required this.onRefreshToken,
    required this.onSignOut,
  });

  final String? username;
  final bool hasIdToken;
  final List<String> scopes;
  final DateTime? expiresAt;
  final bool busy;
  final VoidCallback onRefreshToken;
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
            const SizedBox(height: 8),
            Text('ID token: ${hasIdToken ? 'available' : 'not returned'}'),
            Text('Access token scopes: ${scopes.length}'),
            if (expiresAt case final value?)
              Text('Access token expires: ${value.toLocal()}'),
            const SizedBox(height: 16),
            FilledButton.tonal(
              key: const Key('refreshToken'),
              onPressed: busy ? null : onRefreshToken,
              child: const Text('Refresh access token'),
            ),
            const SizedBox(height: 8),
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
