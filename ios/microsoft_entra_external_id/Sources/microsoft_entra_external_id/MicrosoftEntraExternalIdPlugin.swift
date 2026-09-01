import Flutter
import MSAL
import UIKit

public class MicrosoftEntraExternalIdPlugin: NSObject, FlutterPlugin, NativeAuthHostApi {
  private var nativeAuth: MSALNativeAuthPublicClientApplication?
  private weak var presentingViewController: UIViewController?
  private var accountResult: MSALNativeAuthUserAccountResult?
  private var continuations: [String: AuthContinuation] = [:]
  private var activeDelegates: [UUID: AnyObject] = [:]

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MicrosoftEntraExternalIdPlugin()
    instance.presentingViewController = registrar.viewController
    NativeAuthHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  func getNativeSdkStatus() throws -> NativeSdkStatusMessage {
    NativeSdkStatusMessage(platform: .ios, linked: true, sdkVersion: "2.15.0")
  }

  func initialize(
    configuration: NativeAuthConfigurationMessage
  ) async throws -> NativeAuthResultMessage {
    do {
      let config = try MSALNativeAuthPublicClientApplicationConfig(
        clientId: configuration.clientId,
        tenantSubdomain: configuration.tenantSubdomain,
        challengeTypes: [.OOB, .password]
      )
      config.redirectUri = configuration.redirectUri
      nativeAuth = try MSALNativeAuthPublicClientApplication(nativeAuthConfiguration: config)
      accountResult = nil
      continuations.removeAll()
      return NativeAuthResultMessage(type: .initialized)
    } catch {
      return failure(
        code: "initialization_failed",
        message: error.localizedDescription
      )
    }
  }

  func acquireTokenWithBrowser(
    parameters: NativeAuthWebFallbackParametersMessage
  ) async throws -> NativeAuthResultMessage {
    guard let nativeAuth else { return notInitialized() }
    guard let presentingViewController else {
      return failure(
        code: "view_controller_unavailable",
        message: "A foreground view controller is required for browser authentication."
      )
    }
    guard !parameters.scopes.isEmpty else {
      return failure(code: "invalid_scopes", message: "At least one browser scope is required.")
    }

    let webParameters = MSALWebviewParameters(
      authPresentationViewController: presentingViewController
    )
    let tokenParameters = MSALInteractiveTokenParameters(
      scopes: parameters.scopes,
      webviewParameters: webParameters
    )
    tokenParameters.loginHint = parameters.loginHint

    return await withCheckedContinuation { continuation in
      nativeAuth.acquireToken(with: tokenParameters) { result, error in
        guard let result else {
          continuation.resume(
            returning: self.failure(
              code: "browser_auth_failed",
              message: error?.localizedDescription ?? "Browser authentication failed."
            )
          )
          return
        }

        let expiresAt = result.expiresOn.map {
          Int64(($0.timeIntervalSince1970 * 1_000).rounded())
        }
        continuation.resume(
          returning: NativeAuthResultMessage(
            type: .signedIn,
            username: result.account.username,
            idToken: result.idToken,
            accessToken: result.accessToken,
            scopes: result.scopes,
            expiresAtEpochMilliseconds: expiresAt
          )
        )
      }
    }
  }

  func getCurrentAccount() async throws -> NativeAuthResultMessage {
    guard let nativeAuth else { return notInitialized() }
    accountResult = nativeAuth.getNativeAuthUserAccount()
    guard let accountResult else {
      return NativeAuthResultMessage(type: .signedOut)
    }
    return await signedIn(accountResult)
  }

  func startSignIn(
    parameters: NativeAuthSignInParametersMessage
  ) async throws -> NativeAuthResultMessage {
    guard let nativeAuth else { return notInitialized() }
    continuations.removeAll()
    let nativeParameters = MSALNativeAuthSignInParameters(username: parameters.username)
    nativeParameters.password = parameters.password
    nativeParameters.scopes = parameters.scopes.isEmpty ? nil : parameters.scopes
    let event: SignInStartEvent = await withCheckedContinuation { continuation in
      let delegateId = UUID()
      let delegate = SignInStartHandler { [weak self] event in
        self?.activeDelegates.removeValue(forKey: delegateId)
        continuation.resume(returning: event)
      }
      activeDelegates[delegateId] = delegate
      nativeAuth.signIn(parameters: nativeParameters, delegate: delegate)
    }
    nativeParameters.password = nil
    return await map(event, scopes: parameters.scopes)
  }

  func startSignUp(
    parameters: NativeAuthSignUpParametersMessage
  ) async throws -> NativeAuthResultMessage {
    guard let nativeAuth else { return notInitialized() }
    continuations.removeAll()
    let nativeParameters = MSALNativeAuthSignUpParameters(username: parameters.username)
    nativeParameters.password = parameters.password
    nativeParameters.attributes = parameters.attributes.reduce(into: [:]) { result, attribute in
      result[attribute.name] = attribute.value
    }
    let event: SignUpStartEvent = await withCheckedContinuation { continuation in
      let delegateId = UUID()
      let delegate = SignUpStartHandler { [weak self] event in
        self?.activeDelegates.removeValue(forKey: delegateId)
        continuation.resume(returning: event)
      }
      activeDelegates[delegateId] = delegate
      nativeAuth.signUp(parameters: nativeParameters, delegate: delegate)
    }
    nativeParameters.password = nil
    nativeParameters.attributes = nil
    return map(event)
  }

  func startResetPassword(
    parameters: NativeAuthResetPasswordParametersMessage
  ) async throws -> NativeAuthResultMessage {
    guard let nativeAuth else { return notInitialized() }
    continuations.removeAll()
    let nativeParameters = MSALNativeAuthResetPasswordParameters(username: parameters.username)
    let event: ResetPasswordStartEvent = await withCheckedContinuation { continuation in
      let delegateId = UUID()
      let delegate = ResetPasswordStartHandler { [weak self] event in
        self?.activeDelegates.removeValue(forKey: delegateId)
        continuation.resume(returning: event)
      }
      activeDelegates[delegateId] = delegate
      nativeAuth.resetPassword(parameters: nativeParameters, delegate: delegate)
    }
    switch event {
    case .error(let error):
      return failure(error)
    case .codeRequired(let state, let sentTo, let codeLength):
      let continuationId = UUID().uuidString
      continuations[continuationId] = .resetPasswordCode(state, scopes: parameters.scopes)
      return codeRequired(
        operation: .passwordReset,
        continuationId: continuationId,
        sentTo: sentTo,
        codeLength: codeLength
      )
    }
  }

  func submitCode(
    continuationId: String,
    code: String
  ) async throws -> NativeAuthResultMessage {
    guard let flow = continuations[continuationId] else {
      return invalidContinuation()
    }

    switch flow {
    case .signInCode(let state, let scopes):
      let event: SignInVerifyEvent = await withCheckedContinuation { continuation in
        let delegateId = UUID()
        let delegate = SignInVerifyHandler { [weak self] event in
          self?.activeDelegates.removeValue(forKey: delegateId)
          continuation.resume(returning: event)
        }
        activeDelegates[delegateId] = delegate
        state.submitCode(code: code, delegate: delegate)
      }
      switch event {
      case .error(let error, let newState):
        if let newState {
          continuations[continuationId] = .signInCode(newState, scopes: scopes)
        }
        return failure(error)
      case .completed(let result):
        continuations.removeValue(forKey: continuationId)
        accountResult = result
        return await signedIn(result, scopes: scopes)
      case .unsupported(let code, let message):
        return failure(code: code, message: message)
      }

    case .signUpCode(let state):
      let event: SignUpVerifyEvent = await withCheckedContinuation { continuation in
        let delegateId = UUID()
        let delegate = SignUpVerifyHandler { [weak self] event in
          self?.activeDelegates.removeValue(forKey: delegateId)
          continuation.resume(returning: event)
        }
        activeDelegates[delegateId] = delegate
        state.submitCode(code: code, delegate: delegate)
      }
      switch event {
      case .error(let error, let newState):
        if let newState {
          continuations[continuationId] = .signUpCode(newState)
        }
        return failure(error)
      case .completed(let state):
        continuations.removeValue(forKey: continuationId)
        return await signInAfterSignUp(state)
      case .passwordRequired(let state):
        continuations[continuationId] = .signUpPassword(state)
        return passwordRequired(operation: .signUp, continuationId: continuationId)
      case .attributesRequired(let attributes, let state):
        continuations[continuationId] = .signUpAttributes(state, required: attributes)
        return attributesRequired(
          continuationId: continuationId,
          requiredAttributes: attributes
        )
      case .unsupported(let code, let message):
        return failure(code: code, message: message)
      }

    case .resetPasswordCode(let state, let scopes):
      let event: ResetPasswordVerifyEvent = await withCheckedContinuation { continuation in
        let delegateId = UUID()
        let delegate = ResetPasswordVerifyHandler { [weak self] event in
          self?.activeDelegates.removeValue(forKey: delegateId)
          continuation.resume(returning: event)
        }
        activeDelegates[delegateId] = delegate
        state.submitCode(code: code, delegate: delegate)
      }
      switch event {
      case .error(let error, let newState):
        if let newState {
          continuations[continuationId] = .resetPasswordCode(newState, scopes: scopes)
        }
        return failure(error)
      case .passwordRequired(let state):
        continuations[continuationId] = .resetPasswordPassword(state, scopes: scopes)
        return passwordRequired(operation: .passwordReset, continuationId: continuationId)
      }

    case .signInPassword, .signUpPassword, .signUpAttributes, .resetPasswordPassword:
      return invalidContinuation()
    }
  }

  func submitPassword(
    continuationId: String,
    password: String
  ) async throws -> NativeAuthResultMessage {
    guard let flow = continuations[continuationId] else {
      return invalidContinuation()
    }

    switch flow {
    case .signInPassword(let state, let scopes):
      let event: SignInPasswordEvent = await withCheckedContinuation { continuation in
        let delegateId = UUID()
        let delegate = SignInPasswordHandler { [weak self] event in
          self?.activeDelegates.removeValue(forKey: delegateId)
          continuation.resume(returning: event)
        }
        activeDelegates[delegateId] = delegate
        state.submitPassword(password: password, delegate: delegate)
      }
      switch event {
      case .error(let error, let newState):
        if let newState {
          continuations[continuationId] = .signInPassword(newState, scopes: scopes)
        }
        return failure(error)
      case .completed(let result):
        continuations.removeValue(forKey: continuationId)
        accountResult = result
        return await signedIn(result, scopes: scopes)
      case .unsupported(let code, let message):
        return failure(code: code, message: message)
      }

    case .signUpPassword(let state):
      let event: SignUpPasswordEvent = await withCheckedContinuation { continuation in
        let delegateId = UUID()
        let delegate = SignUpPasswordHandler { [weak self] event in
          self?.activeDelegates.removeValue(forKey: delegateId)
          continuation.resume(returning: event)
        }
        activeDelegates[delegateId] = delegate
        state.submitPassword(password: password, delegate: delegate)
      }
      switch event {
      case .error(let error, let newState):
        if let newState {
          continuations[continuationId] = .signUpPassword(newState)
        }
        return failure(error)
      case .attributesRequired(let attributes, let state):
        continuations[continuationId] = .signUpAttributes(state, required: attributes)
        return attributesRequired(
          continuationId: continuationId,
          requiredAttributes: attributes
        )
      case .completed(let state):
        continuations.removeValue(forKey: continuationId)
        return await signInAfterSignUp(state)
      }

    case .resetPasswordPassword(let state, let scopes):
      let event: ResetPasswordPasswordEvent = await withCheckedContinuation { continuation in
        let delegateId = UUID()
        let delegate = ResetPasswordPasswordHandler { [weak self] event in
          self?.activeDelegates.removeValue(forKey: delegateId)
          continuation.resume(returning: event)
        }
        activeDelegates[delegateId] = delegate
        state.submitPassword(password: password, delegate: delegate)
      }
      switch event {
      case .error(let error, let newState):
        if let newState {
          continuations[continuationId] = .resetPasswordPassword(newState, scopes: scopes)
        }
        return failure(error)
      case .completed(let state):
        continuations.removeValue(forKey: continuationId)
        return await signInAfterResetPassword(state, scopes: scopes)
      }

    case .signInCode, .signUpCode, .signUpAttributes, .resetPasswordCode:
      return invalidContinuation()
    }
  }

  func submitAttributes(
    continuationId: String,
    attributes: [NativeAuthAttributeMessage]
  ) async throws -> NativeAuthResultMessage {
    guard case .signUpAttributes(let state, let requiredAttributes) =
      continuations[continuationId]
    else {
      return invalidContinuation()
    }

    let values = attributes.reduce(into: [String: Any]()) { result, attribute in
      result[attribute.name] = attribute.value
    }
    let event: SignUpAttributesEvent = await withCheckedContinuation { continuation in
      let delegateId = UUID()
      let delegate = SignUpAttributesHandler { [weak self] event in
        self?.activeDelegates.removeValue(forKey: delegateId)
        continuation.resume(returning: event)
      }
      activeDelegates[delegateId] = delegate
      state.submitAttributes(attributes: values, delegate: delegate)
    }
    switch event {
    case .error(let error):
      return failure(error)
    case .attributesRequired(let attributes, let state):
      continuations[continuationId] = .signUpAttributes(state, required: attributes)
      return attributesRequired(
        continuationId: continuationId,
        requiredAttributes: attributes
      )
    case .attributesInvalid(let names, let state):
      continuations[continuationId] = .signUpAttributes(state, required: requiredAttributes)
      return attributesRequired(
        continuationId: continuationId,
        requiredAttributes: requiredAttributes,
        invalidAttributeNames: names
      )
    case .completed(let state):
      continuations.removeValue(forKey: continuationId)
      return await signInAfterSignUp(state)
    }
  }

  func resendCode(continuationId: String) async throws -> NativeAuthResultMessage {
    guard let flow = continuations[continuationId] else {
      return invalidContinuation()
    }

    switch flow {
    case .signInCode(let state, let scopes):
      let event: SignInResendEvent = await withCheckedContinuation { continuation in
        let delegateId = UUID()
        let delegate = SignInResendHandler { [weak self] event in
          self?.activeDelegates.removeValue(forKey: delegateId)
          continuation.resume(returning: event)
        }
        activeDelegates[delegateId] = delegate
        state.resendCode(delegate: delegate)
      }
      switch event {
      case .error(let error, let newState):
        if let newState {
          continuations[continuationId] = .signInCode(newState, scopes: scopes)
        }
        return failure(error)
      case .codeRequired(let state, let sentTo, let codeLength):
        continuations[continuationId] = .signInCode(state, scopes: scopes)
        return codeRequired(
          operation: .signIn,
          continuationId: continuationId,
          sentTo: sentTo,
          codeLength: codeLength
        )
      }

    case .signUpCode(let state):
      let event: SignUpResendEvent = await withCheckedContinuation { continuation in
        let delegateId = UUID()
        let delegate = SignUpResendHandler { [weak self] event in
          self?.activeDelegates.removeValue(forKey: delegateId)
          continuation.resume(returning: event)
        }
        activeDelegates[delegateId] = delegate
        state.resendCode(delegate: delegate)
      }
      switch event {
      case .error(let error, let newState):
        if let newState {
          continuations[continuationId] = .signUpCode(newState)
        }
        return failure(error)
      case .codeRequired(let state, let sentTo, let codeLength):
        continuations[continuationId] = .signUpCode(state)
        return codeRequired(
          operation: .signUp,
          continuationId: continuationId,
          sentTo: sentTo,
          codeLength: codeLength
        )
      }

    case .resetPasswordCode(let state, let scopes):
      let event: ResetPasswordResendEvent = await withCheckedContinuation { continuation in
        let delegateId = UUID()
        let delegate = ResetPasswordResendHandler { [weak self] event in
          self?.activeDelegates.removeValue(forKey: delegateId)
          continuation.resume(returning: event)
        }
        activeDelegates[delegateId] = delegate
        state.resendCode(delegate: delegate)
      }
      switch event {
      case .error(let error, let newState):
        if let newState {
          continuations[continuationId] = .resetPasswordCode(newState, scopes: scopes)
        }
        return failure(error)
      case .codeRequired(let state, let sentTo, let codeLength):
        continuations[continuationId] = .resetPasswordCode(state, scopes: scopes)
        return codeRequired(
          operation: .passwordReset,
          continuationId: continuationId,
          sentTo: sentTo,
          codeLength: codeLength
        )
      }

    case .signInPassword, .signUpPassword, .signUpAttributes, .resetPasswordPassword:
      return invalidContinuation()
    }
  }

  func getAccessToken(
    parameters: NativeAuthAccessTokenParametersMessage
  ) async throws -> NativeAuthResultMessage {
    guard let nativeAuth else { return notInitialized() }
    if accountResult == nil {
      accountResult = nativeAuth.getNativeAuthUserAccount()
    }
    guard let accountResult else {
      return NativeAuthResultMessage(type: .signedOut)
    }
    return await signedIn(
      accountResult,
      scopes: parameters.scopes,
      forceRefresh: parameters.forceRefresh
    )
  }

  func signOut() async throws -> NativeAuthResultMessage {
    if accountResult == nil {
      accountResult = nativeAuth?.getNativeAuthUserAccount()
    }
    accountResult?.signOut()
    accountResult = nil
    continuations.removeAll()
    return NativeAuthResultMessage(type: .signedOut)
  }

  private func signInAfterSignUp(
    _ state: SignInAfterSignUpState
  ) async -> NativeAuthResultMessage {
    let event: SignInAfterSignUpEvent = await withCheckedContinuation { continuation in
      let delegateId = UUID()
      let delegate = SignInAfterSignUpHandler { [weak self] event in
        self?.activeDelegates.removeValue(forKey: delegateId)
        continuation.resume(returning: event)
      }
      activeDelegates[delegateId] = delegate
      let parameters = MSALNativeAuthSignInAfterSignUpParameters()
      state.signIn(parameters: parameters, delegate: delegate)
    }
    switch event {
    case .error(let error):
      return failure(error)
    case .completed(let result):
      accountResult = result
      return await signedIn(result)
    case .unsupported(let code, let message):
      return failure(code: code, message: message)
    }
  }

  private func signInAfterResetPassword(
    _ state: SignInAfterResetPasswordState,
    scopes: [String]
  ) async -> NativeAuthResultMessage {
    let event: SignInAfterResetPasswordEvent = await withCheckedContinuation { continuation in
      let delegateId = UUID()
      let delegate = SignInAfterResetPasswordHandler { [weak self] event in
        self?.activeDelegates.removeValue(forKey: delegateId)
        continuation.resume(returning: event)
      }
      activeDelegates[delegateId] = delegate
      let parameters = MSALNativeAuthSignInAfterResetPasswordParameters()
      parameters.scopes = scopes.isEmpty ? nil : scopes
      state.signIn(parameters: parameters, delegate: delegate)
    }
    switch event {
    case .error(let error):
      return failure(error)
    case .completed(let result):
      accountResult = result
      return await signedIn(result, scopes: scopes)
    case .unsupported(let code, let message):
      return failure(code: code, message: message)
    }
  }

  private func map(
    _ event: SignInStartEvent,
    scopes: [String]
  ) async -> NativeAuthResultMessage {
    switch event {
    case .error(let error):
      return failure(error)
    case .codeRequired(let state, let sentTo, let codeLength):
      let continuationId = UUID().uuidString
      continuations[continuationId] = .signInCode(state, scopes: scopes)
      return codeRequired(
        operation: .signIn,
        continuationId: continuationId,
        sentTo: sentTo,
        codeLength: codeLength
      )
    case .passwordRequired(let state):
      let continuationId = UUID().uuidString
      continuations[continuationId] = .signInPassword(state, scopes: scopes)
      return passwordRequired(operation: .signIn, continuationId: continuationId)
    case .completed(let result):
      accountResult = result
      return await signedIn(result, scopes: scopes)
    case .unsupported(let code, let message):
      return failure(code: code, message: message)
    }
  }

  private func map(_ event: SignUpStartEvent) -> NativeAuthResultMessage {
    switch event {
    case .error(let error):
      return failure(error)
    case .codeRequired(let state, let sentTo, let codeLength):
      let continuationId = UUID().uuidString
      continuations[continuationId] = .signUpCode(state)
      return codeRequired(
        operation: .signUp,
        continuationId: continuationId,
        sentTo: sentTo,
        codeLength: codeLength
      )
    case .unsupported(let code, let message):
      return failure(code: code, message: message)
    }
  }

  private func codeRequired(
    operation: NativeAuthOperationMessage,
    continuationId: String,
    sentTo: String,
    codeLength: Int
  ) -> NativeAuthResultMessage {
    NativeAuthResultMessage(
      type: .codeRequired,
      operation: operation,
      continuationId: continuationId,
      sentTo: sentTo,
      codeLength: Int64(codeLength)
    )
  }

  private func passwordRequired(
    operation: NativeAuthOperationMessage,
    continuationId: String
  ) -> NativeAuthResultMessage {
    NativeAuthResultMessage(
      type: .passwordRequired,
      operation: operation,
      continuationId: continuationId
    )
  }

  private func attributesRequired(
    continuationId: String,
    requiredAttributes: [MSALNativeAuthRequiredAttribute],
    invalidAttributeNames: [String] = []
  ) -> NativeAuthResultMessage {
    NativeAuthResultMessage(
      type: .attributesRequired,
      operation: .signUp,
      continuationId: continuationId,
      requiredAttributes: requiredAttributes.map { attribute in
        NativeAuthRequiredAttributeMessage(
          name: attribute.name,
          type: attribute.type,
          required: attribute.required,
          regex: attribute.regex
        )
      },
      invalidAttributeNames: invalidAttributeNames
    )
  }

  private func signedIn(
    _ result: MSALNativeAuthUserAccountResult,
    scopes: [String] = [],
    forceRefresh: Bool = false
  ) async -> NativeAuthResultMessage {
    let parameters = MSALNativeAuthGetAccessTokenParameters()
    parameters.scopes = scopes.isEmpty ? nil : scopes
    parameters.forceRefresh = forceRefresh
    parameters.returnRefreshToken = false

    let event: CredentialsEvent = await withCheckedContinuation { continuation in
      let delegateId = UUID()
      let delegate = CredentialsHandler { [weak self] event in
        self?.activeDelegates.removeValue(forKey: delegateId)
        continuation.resume(returning: event)
      }
      activeDelegates[delegateId] = delegate
      result.getAccessToken(parameters: parameters, delegate: delegate)
    }

    switch event {
    case .error(let error):
      return failure(error)
    case .completed(let token):
      let expiresAt = token.expiresOn.map {
        Int64(($0.timeIntervalSince1970 * 1_000).rounded())
      }
      return NativeAuthResultMessage(
        type: .signedIn,
        username: result.account.username,
        idToken: result.idToken,
        accessToken: token.accessToken,
        scopes: token.scopes,
        expiresAtEpochMilliseconds: expiresAt
      )
    }
  }

  private func notInitialized() -> NativeAuthResultMessage {
    failure(
      code: "not_initialized",
      message: "Call initialize before using Microsoft Entra External ID native authentication."
    )
  }

  private func invalidContinuation() -> NativeAuthResultMessage {
    failure(
      code: "invalid_continuation",
      message: "The native authentication continuation is missing or expired. Restart the flow."
    )
  }

  private func failure(_ error: MSALNativeAuthError) -> NativeAuthResultMessage {
    var code = String(describing: type(of: error))
    if let error = error as? VerifyCodeError, error.isInvalidCode {
      code = "invalid_code"
    } else if let error = error as? SignInStartError, error.isUserNotFound {
      code = "user_not_found"
    } else if let error = error as? SignInStartError, error.isInvalidUsername {
      code = "invalid_username"
    } else if let error = error as? PasswordRequiredError, error.isInvalidPassword {
      code = "invalid_credentials"
    } else if let error = error as? SignUpStartError, error.isUserAlreadyExists {
      code = "user_already_exists"
    } else if let error = error as? SignUpStartError, error.isInvalidUsername {
      code = "invalid_username"
    }
    return failure(
      code: code,
      message: error.errorDescription ?? "Native authentication failed.",
      browserRequired: error.isBrowserRequired
    )
  }

  private func failure(
    code: String,
    message: String,
    browserRequired: Bool = false
  ) -> NativeAuthResultMessage {
    NativeAuthResultMessage(
      type: browserRequired ? .browserRequired : .error,
      errorCode: code,
      errorMessage: message
    )
  }

  private enum AuthContinuation {
    case signInCode(SignInCodeRequiredState, scopes: [String])
    case signInPassword(SignInPasswordRequiredState, scopes: [String])
    case signUpCode(SignUpCodeRequiredState)
    case signUpPassword(SignUpPasswordRequiredState)
    case signUpAttributes(
      SignUpAttributesRequiredState,
      required: [MSALNativeAuthRequiredAttribute]
    )
    case resetPasswordCode(ResetPasswordCodeRequiredState, scopes: [String])
    case resetPasswordPassword(ResetPasswordRequiredState, scopes: [String])
  }
}

private enum SignInStartEvent {
  case error(SignInStartError)
  case codeRequired(SignInCodeRequiredState, String, Int)
  case passwordRequired(SignInPasswordRequiredState)
  case completed(MSALNativeAuthUserAccountResult)
  case unsupported(String, String)
}

private final class SignInStartHandler: NSObject, SignInStartDelegate {
  private let callback: (SignInStartEvent) -> Void

  init(callback: @escaping (SignInStartEvent) -> Void) {
    self.callback = callback
  }

  @MainActor func onSignInStartError(error: SignInStartError) {
    callback(.error(error))
  }

  @MainActor func onSignInCodeRequired(
    newState: SignInCodeRequiredState,
    sentTo: String,
    channelTargetType _: MSALNativeAuthChannelType,
    codeLength: Int
  ) {
    callback(.codeRequired(newState, sentTo, codeLength))
  }

  @MainActor func onSignInCompleted(result: MSALNativeAuthUserAccountResult) {
    callback(.completed(result))
  }

  @MainActor func onSignInPasswordRequired(newState: SignInPasswordRequiredState) {
    callback(.passwordRequired(newState))
  }

  @MainActor func onSignInStrongAuthMethodRegistration(
    authMethods _: [MSALAuthMethod],
    newState _: RegisterStrongAuthState
  ) {
    callback(.unsupported("strong_auth_registration_required", "Strong authentication registration is not implemented."))
  }

  @MainActor func onSignInAwaitingMFA(
    authMethods _: [MSALAuthMethod],
    newState _: AwaitingMFAState
  ) {
    callback(.unsupported("mfa_required", "Multifactor authentication is not implemented."))
  }
}

private enum SignInPasswordEvent {
  case error(PasswordRequiredError, SignInPasswordRequiredState?)
  case completed(MSALNativeAuthUserAccountResult)
  case unsupported(String, String)
}

private final class SignInPasswordHandler: NSObject, SignInPasswordRequiredDelegate {
  private let callback: (SignInPasswordEvent) -> Void

  init(callback: @escaping (SignInPasswordEvent) -> Void) {
    self.callback = callback
  }

  @MainActor func onSignInPasswordRequiredError(
    error: PasswordRequiredError,
    newState: SignInPasswordRequiredState?
  ) {
    callback(.error(error, newState))
  }

  @MainActor func onSignInCompleted(result: MSALNativeAuthUserAccountResult) {
    callback(.completed(result))
  }

  @MainActor func onSignInStrongAuthMethodRegistration(
    authMethods _: [MSALAuthMethod],
    newState _: RegisterStrongAuthState
  ) {
    callback(.unsupported("strong_auth_registration_required", "Strong authentication registration is not implemented."))
  }

  @MainActor func onSignInAwaitingMFA(
    authMethods _: [MSALAuthMethod],
    newState _: AwaitingMFAState
  ) {
    callback(.unsupported("mfa_required", "Multifactor authentication is not implemented."))
  }
}

private enum CredentialsEvent {
  case error(RetrieveAccessTokenError)
  case completed(MSALNativeAuthTokenResult)
}

private final class CredentialsHandler: NSObject, CredentialsDelegate {
  private let callback: (CredentialsEvent) -> Void

  init(callback: @escaping (CredentialsEvent) -> Void) {
    self.callback = callback
  }

  @MainActor func onAccessTokenRetrieveError(error: RetrieveAccessTokenError) {
    callback(.error(error))
  }

  @MainActor func onAccessTokenRetrieveCompleted(result: MSALNativeAuthTokenResult) {
    callback(.completed(result))
  }
}

private enum SignUpStartEvent {
  case error(SignUpStartError)
  case codeRequired(SignUpCodeRequiredState, String, Int)
  case unsupported(String, String)
}

private final class SignUpStartHandler: NSObject, SignUpStartDelegate {
  private let callback: (SignUpStartEvent) -> Void

  init(callback: @escaping (SignUpStartEvent) -> Void) {
    self.callback = callback
  }

  @MainActor func onSignUpStartError(error: SignUpStartError) {
    callback(.error(error))
  }

  @MainActor func onSignUpCodeRequired(
    newState: SignUpCodeRequiredState,
    sentTo: String,
    channelTargetType _: MSALNativeAuthChannelType,
    codeLength: Int
  ) {
    callback(.codeRequired(newState, sentTo, codeLength))
  }

  @MainActor func onSignUpAttributesInvalid(attributeNames _: [String]) {
    callback(.unsupported("invalid_attributes", "The tenant rejected one or more user attributes."))
  }
}

private enum SignInVerifyEvent {
  case error(VerifyCodeError, SignInCodeRequiredState?)
  case completed(MSALNativeAuthUserAccountResult)
  case unsupported(String, String)
}

private final class SignInVerifyHandler: NSObject, SignInVerifyCodeDelegate {
  private let callback: (SignInVerifyEvent) -> Void

  init(callback: @escaping (SignInVerifyEvent) -> Void) {
    self.callback = callback
  }

  @MainActor func onSignInVerifyCodeError(
    error: VerifyCodeError,
    newState: SignInCodeRequiredState?
  ) {
    callback(.error(error, newState))
  }

  @MainActor func onSignInCompleted(result: MSALNativeAuthUserAccountResult) {
    callback(.completed(result))
  }

  @MainActor func onSignInStrongAuthMethodRegistration(
    authMethods _: [MSALAuthMethod],
    newState _: RegisterStrongAuthState
  ) {
    callback(.unsupported("strong_auth_registration_required", "Strong authentication registration is not implemented."))
  }

  @MainActor func onSignInAwaitingMFA(
    authMethods _: [MSALAuthMethod],
    newState _: AwaitingMFAState
  ) {
    callback(.unsupported("mfa_required", "Multifactor authentication is not implemented."))
  }
}

private enum SignUpVerifyEvent {
  case error(VerifyCodeError, SignUpCodeRequiredState?)
  case completed(SignInAfterSignUpState)
  case passwordRequired(SignUpPasswordRequiredState)
  case attributesRequired([MSALNativeAuthRequiredAttribute], SignUpAttributesRequiredState)
  case unsupported(String, String)
}

private final class SignUpVerifyHandler: NSObject, SignUpVerifyCodeDelegate {
  private let callback: (SignUpVerifyEvent) -> Void

  init(callback: @escaping (SignUpVerifyEvent) -> Void) {
    self.callback = callback
  }

  @MainActor func onSignUpVerifyCodeError(
    error: VerifyCodeError,
    newState: SignUpCodeRequiredState?
  ) {
    callback(.error(error, newState))
  }

  @MainActor func onSignUpCompleted(newState: SignInAfterSignUpState) {
    callback(.completed(newState))
  }

  @MainActor func onSignUpAttributesRequired(
    attributes: [MSALNativeAuthRequiredAttribute],
    newState: SignUpAttributesRequiredState
  ) {
    callback(.attributesRequired(attributes, newState))
  }

  @MainActor func onSignUpPasswordRequired(newState: SignUpPasswordRequiredState) {
    callback(.passwordRequired(newState))
  }
}

private enum SignUpPasswordEvent {
  case error(PasswordRequiredError, SignUpPasswordRequiredState?)
  case attributesRequired([MSALNativeAuthRequiredAttribute], SignUpAttributesRequiredState)
  case completed(SignInAfterSignUpState)
}

private final class SignUpPasswordHandler: NSObject, SignUpPasswordRequiredDelegate {
  private let callback: (SignUpPasswordEvent) -> Void

  init(callback: @escaping (SignUpPasswordEvent) -> Void) {
    self.callback = callback
  }

  @MainActor func onSignUpPasswordRequiredError(
    error: PasswordRequiredError,
    newState: SignUpPasswordRequiredState?
  ) {
    callback(.error(error, newState))
  }

  @MainActor func onSignUpAttributesRequired(
    attributes: [MSALNativeAuthRequiredAttribute],
    newState: SignUpAttributesRequiredState
  ) {
    callback(.attributesRequired(attributes, newState))
  }

  @MainActor func onSignUpCompleted(newState: SignInAfterSignUpState) {
    callback(.completed(newState))
  }
}

private enum SignUpAttributesEvent {
  case error(AttributesRequiredError)
  case attributesRequired([MSALNativeAuthRequiredAttribute], SignUpAttributesRequiredState)
  case attributesInvalid([String], SignUpAttributesRequiredState)
  case completed(SignInAfterSignUpState)
}

private final class SignUpAttributesHandler: NSObject, SignUpAttributesRequiredDelegate {
  private let callback: (SignUpAttributesEvent) -> Void

  init(callback: @escaping (SignUpAttributesEvent) -> Void) {
    self.callback = callback
  }

  @MainActor func onSignUpAttributesRequiredError(error: AttributesRequiredError) {
    callback(.error(error))
  }

  @MainActor func onSignUpAttributesRequired(
    attributes: [MSALNativeAuthRequiredAttribute],
    newState: SignUpAttributesRequiredState
  ) {
    callback(.attributesRequired(attributes, newState))
  }

  @MainActor func onSignUpAttributesInvalid(
    attributeNames: [String],
    newState: SignUpAttributesRequiredState
  ) {
    callback(.attributesInvalid(attributeNames, newState))
  }

  @MainActor func onSignUpCompleted(newState: SignInAfterSignUpState) {
    callback(.completed(newState))
  }
}

private enum SignInResendEvent {
  case error(ResendCodeError, SignInCodeRequiredState?)
  case codeRequired(SignInCodeRequiredState, String, Int)
}

private final class SignInResendHandler: NSObject, SignInResendCodeDelegate {
  private let callback: (SignInResendEvent) -> Void

  init(callback: @escaping (SignInResendEvent) -> Void) {
    self.callback = callback
  }

  @MainActor func onSignInResendCodeError(
    error: ResendCodeError,
    newState: SignInCodeRequiredState?
  ) {
    callback(.error(error, newState))
  }

  @MainActor func onSignInResendCodeCodeRequired(
    newState: SignInCodeRequiredState,
    sentTo: String,
    channelTargetType _: MSALNativeAuthChannelType,
    codeLength: Int
  ) {
    callback(.codeRequired(newState, sentTo, codeLength))
  }
}

private enum SignUpResendEvent {
  case error(ResendCodeError, SignUpCodeRequiredState?)
  case codeRequired(SignUpCodeRequiredState, String, Int)
}

private final class SignUpResendHandler: NSObject, SignUpResendCodeDelegate {
  private let callback: (SignUpResendEvent) -> Void

  init(callback: @escaping (SignUpResendEvent) -> Void) {
    self.callback = callback
  }

  @MainActor func onSignUpResendCodeError(
    error: ResendCodeError,
    newState: SignUpCodeRequiredState?
  ) {
    callback(.error(error, newState))
  }

  @MainActor func onSignUpResendCodeCodeRequired(
    newState: SignUpCodeRequiredState,
    sentTo: String,
    channelTargetType _: MSALNativeAuthChannelType,
    codeLength: Int
  ) {
    callback(.codeRequired(newState, sentTo, codeLength))
  }
}

private enum SignInAfterSignUpEvent {
  case error(SignInAfterSignUpError)
  case completed(MSALNativeAuthUserAccountResult)
  case unsupported(String, String)
}

private final class SignInAfterSignUpHandler: NSObject, SignInAfterSignUpDelegate {
  private let callback: (SignInAfterSignUpEvent) -> Void

  init(callback: @escaping (SignInAfterSignUpEvent) -> Void) {
    self.callback = callback
  }

  @MainActor func onSignInAfterSignUpError(error: SignInAfterSignUpError) {
    callback(.error(error))
  }

  @MainActor func onSignInCompleted(result: MSALNativeAuthUserAccountResult) {
    callback(.completed(result))
  }

  @MainActor func onSignInStrongAuthMethodRegistration(
    authMethods _: [MSALAuthMethod],
    newState _: RegisterStrongAuthState
  ) {
    callback(.unsupported("strong_auth_registration_required", "Strong authentication registration is not implemented."))
  }

  @MainActor func onSignInAwaitingMFA(
    authMethods _: [MSALAuthMethod],
    newState _: AwaitingMFAState
  ) {
    callback(.unsupported("mfa_required", "Multifactor authentication is not implemented."))
  }
}

private enum ResetPasswordStartEvent {
  case error(ResetPasswordStartError)
  case codeRequired(ResetPasswordCodeRequiredState, String, Int)
}

private final class ResetPasswordStartHandler: NSObject, ResetPasswordStartDelegate {
  private let callback: (ResetPasswordStartEvent) -> Void

  init(callback: @escaping (ResetPasswordStartEvent) -> Void) {
    self.callback = callback
  }

  @MainActor func onResetPasswordStartError(error: ResetPasswordStartError) {
    callback(.error(error))
  }

  @MainActor func onResetPasswordCodeRequired(
    newState: ResetPasswordCodeRequiredState,
    sentTo: String,
    channelTargetType _: MSALNativeAuthChannelType,
    codeLength: Int
  ) {
    callback(.codeRequired(newState, sentTo, codeLength))
  }
}

private enum ResetPasswordVerifyEvent {
  case error(VerifyCodeError, ResetPasswordCodeRequiredState?)
  case passwordRequired(ResetPasswordRequiredState)
}

private final class ResetPasswordVerifyHandler: NSObject, ResetPasswordVerifyCodeDelegate {
  private let callback: (ResetPasswordVerifyEvent) -> Void

  init(callback: @escaping (ResetPasswordVerifyEvent) -> Void) {
    self.callback = callback
  }

  @MainActor func onResetPasswordVerifyCodeError(
    error: VerifyCodeError,
    newState: ResetPasswordCodeRequiredState?
  ) {
    callback(.error(error, newState))
  }

  @MainActor func onPasswordRequired(newState: ResetPasswordRequiredState) {
    callback(.passwordRequired(newState))
  }
}

private enum ResetPasswordResendEvent {
  case error(ResendCodeError, ResetPasswordCodeRequiredState?)
  case codeRequired(ResetPasswordCodeRequiredState, String, Int)
}

private final class ResetPasswordResendHandler: NSObject, ResetPasswordResendCodeDelegate {
  private let callback: (ResetPasswordResendEvent) -> Void

  init(callback: @escaping (ResetPasswordResendEvent) -> Void) {
    self.callback = callback
  }

  @MainActor func onResetPasswordResendCodeError(
    error: ResendCodeError,
    newState: ResetPasswordCodeRequiredState?
  ) {
    callback(.error(error, newState))
  }

  @MainActor func onResetPasswordResendCodeRequired(
    newState: ResetPasswordCodeRequiredState,
    sentTo: String,
    channelTargetType _: MSALNativeAuthChannelType,
    codeLength: Int
  ) {
    callback(.codeRequired(newState, sentTo, codeLength))
  }
}

private enum ResetPasswordPasswordEvent {
  case error(PasswordRequiredError, ResetPasswordRequiredState?)
  case completed(SignInAfterResetPasswordState)
}

private final class ResetPasswordPasswordHandler: NSObject, ResetPasswordRequiredDelegate {
  private let callback: (ResetPasswordPasswordEvent) -> Void

  init(callback: @escaping (ResetPasswordPasswordEvent) -> Void) {
    self.callback = callback
  }

  @MainActor func onResetPasswordRequiredError(
    error: PasswordRequiredError,
    newState: ResetPasswordRequiredState?
  ) {
    callback(.error(error, newState))
  }

  @MainActor func onResetPasswordCompleted(newState: SignInAfterResetPasswordState) {
    callback(.completed(newState))
  }
}

private enum SignInAfterResetPasswordEvent {
  case error(SignInAfterResetPasswordError)
  case completed(MSALNativeAuthUserAccountResult)
  case unsupported(String, String)
}

private final class SignInAfterResetPasswordHandler: NSObject, SignInAfterResetPasswordDelegate {
  private let callback: (SignInAfterResetPasswordEvent) -> Void

  init(callback: @escaping (SignInAfterResetPasswordEvent) -> Void) {
    self.callback = callback
  }

  @MainActor func onSignInAfterResetPasswordError(error: SignInAfterResetPasswordError) {
    callback(.error(error))
  }

  @MainActor func onSignInCompleted(result: MSALNativeAuthUserAccountResult) {
    callback(.completed(result))
  }

  @MainActor func onSignInStrongAuthMethodRegistration(
    authMethods _: [MSALAuthMethod],
    newState _: RegisterStrongAuthState
  ) {
    callback(.unsupported("strong_auth_registration_required", "Strong authentication registration is not implemented."))
  }

  @MainActor func onSignInAwaitingMFA(
    authMethods _: [MSALAuthMethod],
    newState _: AwaitingMFAState
  ) {
    callback(.unsupported("mfa_required", "Multifactor authentication is not implemented."))
  }
}
