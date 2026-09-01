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

enum _AuthScenario { emailOtp, emailPassword, attributes, passwordReset, more }

extension on _AuthScenario {
  String get title => switch (this) {
    _AuthScenario.emailOtp => 'Email OTP',
    _AuthScenario.emailPassword => 'Email + Password',
    _AuthScenario.attributes => 'Attributes',
    _AuthScenario.passwordReset => 'Password Reset',
    _AuthScenario.more => 'More',
  };

  String get prompt => switch (this) {
    _AuthScenario.emailOtp =>
      'Sign in or create an account with an email verification code.',
    _AuthScenario.emailPassword =>
      'Sign in or create an account with an email and password.',
    _AuthScenario.attributes =>
      'Create an account and collect attributes required by the tenant.',
    _AuthScenario.passwordReset =>
      'Reset a password with an email verification code.',
    _AuthScenario.more =>
      'Test explicit system-browser fallback and account utilities.',
  };
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

  _AuthScenario _scenario = _AuthScenario.emailOtp;
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

  Future<void> _signIn({required bool withPassword}) async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _status = 'Enter a valid email address.');
      return;
    }
    final password = withPassword ? _passwordController.text : null;
    if (withPassword && password!.isEmpty) {
      setState(() => _status = 'Enter your password.');
      return;
    }
    _passwordController.clear();
    await _perform(
      () => password == null
          ? _plugin.signIn(email, scopes: _scopes)
          : _plugin.signInWithPassword(email, password, scopes: _scopes),
      progress: 'Starting sign in...',
    );
  }

  Future<void> _signUp({required bool withPassword}) async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _status = 'Enter a valid email address.');
      return;
    }
    final password = withPassword ? _passwordController.text : null;
    if (withPassword && password!.isEmpty) {
      setState(() => _status = 'Enter a password for the new account.');
      return;
    }
    _passwordController.clear();
    await _perform(
      () => password == null
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
      _clearInteractiveUi();
      _status = _scenario.prompt;
    });
  }

  void _selectScenario(int index) {
    if (_busy || index == _scenario.index) return;
    setState(() {
      _scenario = _AuthScenario.values[index];
      _emailController.clear();
      _clearInteractiveUi();
      _browserFailure = null;
      _status = _scenario.prompt;
    });
  }

  void _clearInteractiveUi() {
    _codeRequired = null;
    _passwordRequired = null;
    _attributesRequired = null;
    _clearAttributeControllers();
    _codeController.clear();
    _passwordController.clear();
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
        _status = _scenario.prompt;
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

  Widget _buildScenario() => switch (_scenario) {
    _AuthScenario.emailOtp => _EmailOtpScenario(
      controller: _emailController,
      busy: _busy,
      onSignIn: () => _signIn(withPassword: false),
      onSignUp: () => _signUp(withPassword: false),
    ),
    _AuthScenario.emailPassword => _EmailPasswordScenario(
      emailController: _emailController,
      passwordController: _passwordController,
      busy: _busy,
      onSignIn: () => _signIn(withPassword: true),
      onSignUp: () => _signUp(withPassword: true),
    ),
    _AuthScenario.attributes => _AttributesScenario(
      controller: _emailController,
      busy: _busy,
      onSignUp: () => _signUp(withPassword: false),
    ),
    _AuthScenario.passwordReset => _PasswordResetScenario(
      controller: _emailController,
      busy: _busy,
      onResetPassword: _resetPassword,
    ),
    _AuthScenario.more => _MoreScenario(
      controller: _emailController,
      busy: _busy,
      browserConfigured: widget.redirectUri.trim().isNotEmpty,
      apiScopeConfigured: _apiScope.isNotEmpty,
      onContinueInBrowser: _continueInBrowser,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final showStatus = _status != _scenario.prompt;
    return Scaffold(
      appBar: AppBar(title: Text(_scenario.title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (!_configured) const _ConfigurationCard(),
                if (_configured) ...[
                  if (_busy) const LinearProgressIndicator(),
                  if (showStatus) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(_status, key: const Key('status')),
                    ),
                  ],
                  if (_browserFailure != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('browserFallback'),
                      onPressed: _busy ? null : _continueInBrowser,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Continue in system browser'),
                    ),
                  ],
                  if (showStatus || _browserFailure != null)
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
                    _buildScenario(),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _configured
          ? NavigationBar(
              selectedIndex: _scenario.index,
              onDestinationSelected: _selectScenario,
              destinations: const [
                NavigationDestination(
                  key: Key('scenarioEmailOtp'),
                  icon: Icon(Icons.email_outlined),
                  selectedIcon: Icon(Icons.email),
                  label: 'Email OTP',
                ),
                NavigationDestination(
                  key: Key('scenarioPassword'),
                  icon: Icon(Icons.password_outlined),
                  selectedIcon: Icon(Icons.password),
                  label: 'Password',
                ),
                NavigationDestination(
                  key: Key('scenarioAttributes'),
                  icon: Icon(Icons.badge_outlined),
                  selectedIcon: Icon(Icons.badge),
                  label: 'Attributes',
                ),
                NavigationDestination(
                  key: Key('scenarioReset'),
                  icon: Icon(Icons.lock_reset_outlined),
                  selectedIcon: Icon(Icons.lock_reset),
                  label: 'Reset',
                ),
                NavigationDestination(
                  key: Key('scenarioMore'),
                  icon: Icon(Icons.more_horiz),
                  label: 'More',
                ),
              ],
            )
          : null,
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

class _EmailOtpScenario extends StatelessWidget {
  const _EmailOtpScenario({
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
        _EmailField(controller: controller, busy: busy),
        const SizedBox(height: 16),
        _FullWidthButton(
          key: const Key('signIn'),
          busy: busy,
          onPressed: onSignIn,
          label: 'Sign in with email code',
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            key: const Key('signUp'),
            onPressed: busy ? null : onSignUp,
            child: const Text('Sign up with email code'),
          ),
        ),
      ],
    );
  }
}

class _EmailPasswordScenario extends StatelessWidget {
  const _EmailPasswordScenario({
    required this.emailController,
    required this.passwordController,
    required this.busy,
    required this.onSignIn,
    required this.onSignUp,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool busy;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _EmailField(controller: emailController, busy: busy),
        const SizedBox(height: 16),
        TextField(
          key: const Key('password'),
          controller: passwordController,
          enabled: !busy,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Password',
          ),
        ),
        const SizedBox(height: 16),
        _FullWidthButton(
          key: const Key('signIn'),
          busy: busy,
          onPressed: onSignIn,
          label: 'Sign in',
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            key: const Key('signUp'),
            onPressed: busy ? null : onSignUp,
            child: const Text('Create password account'),
          ),
        ),
      ],
    );
  }
}

class _AttributesScenario extends StatelessWidget {
  const _AttributesScenario({
    required this.controller,
    required this.busy,
    required this.onSignUp,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _EmailField(controller: controller, busy: busy),
        const SizedBox(height: 16),
        _FullWidthButton(
          key: const Key('signUp'),
          busy: busy,
          onPressed: onSignUp,
          label: 'Start attribute sign-up',
        ),
      ],
    );
  }
}

class _PasswordResetScenario extends StatelessWidget {
  const _PasswordResetScenario({
    required this.controller,
    required this.busy,
    required this.onResetPassword,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onResetPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _EmailField(controller: controller, busy: busy),
        const SizedBox(height: 16),
        _FullWidthButton(
          key: const Key('resetPassword'),
          busy: busy,
          onPressed: onResetPassword,
          label: 'Reset password',
        ),
      ],
    );
  }
}

class _MoreScenario extends StatelessWidget {
  const _MoreScenario({
    required this.controller,
    required this.busy,
    required this.browserConfigured,
    required this.apiScopeConfigured,
    required this.onContinueInBrowser,
  });

  final TextEditingController controller;
  final bool busy;
  final bool browserConfigured;
  final bool apiScopeConfigured;
  final VoidCallback onContinueInBrowser;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _EmailField(
          controller: controller,
          busy: busy,
          label: 'Login hint (optional)',
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            key: const Key('browserFallbackDirect'),
            onPressed: busy || !browserConfigured ? null : onContinueInBrowser,
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Sign in with system browser'),
          ),
        ),
        const SizedBox(height: 16),
        _ConfigurationStatus(
          icon: Icons.link,
          label: 'Redirect URI',
          configured: browserConfigured,
        ),
        const SizedBox(height: 8),
        _ConfigurationStatus(
          icon: Icons.api,
          label: 'Protected API scope',
          configured: apiScopeConfigured,
        ),
      ],
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({
    required this.controller,
    required this.busy,
    this.label = 'Email',
  });

  final TextEditingController controller;
  final bool busy;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('email'),
      controller: controller,
      enabled: !busy,
      keyboardType: TextInputType.emailAddress,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
      ),
    );
  }
}

class _FullWidthButton extends StatelessWidget {
  const _FullWidthButton({
    required super.key,
    required this.busy,
    required this.onPressed,
    required this.label,
  });

  final bool busy;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        child: Text(label),
      ),
    );
  }
}

class _ConfigurationStatus extends StatelessWidget {
  const _ConfigurationStatus({
    required this.icon,
    required this.label,
    required this.configured,
  });

  final IconData icon;
  final String label;
  final bool configured;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(configured ? 'Configured' : 'Not configured'),
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
