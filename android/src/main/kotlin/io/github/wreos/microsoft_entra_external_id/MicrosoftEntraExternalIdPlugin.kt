package io.github.wreos.microsoft_entra_external_id

import android.app.Activity
import android.content.Context
import com.microsoft.identity.client.AcquireTokenParameters
import com.microsoft.identity.client.AuthenticationCallback
import com.microsoft.identity.client.IAuthenticationResult
import com.microsoft.identity.client.PublicClientApplication
import com.microsoft.identity.client.exception.MsalException
import com.microsoft.identity.nativeauth.INativeAuthPublicClientApplication
import com.microsoft.identity.nativeauth.NativeAuthPublicClientApplicationParameters
import com.microsoft.identity.nativeauth.RequiredUserAttribute
import com.microsoft.identity.nativeauth.UserAttributes
import com.microsoft.identity.nativeauth.parameters.NativeAuthGetAccessTokenParameters
import com.microsoft.identity.nativeauth.parameters.NativeAuthResetPasswordParameters
import com.microsoft.identity.nativeauth.parameters.NativeAuthSignInContinuationParameters
import com.microsoft.identity.nativeauth.parameters.NativeAuthSignInParameters
import com.microsoft.identity.nativeauth.parameters.NativeAuthSignUpParameters
import com.microsoft.identity.nativeauth.statemachine.errors.BrowserRequiredError
import com.microsoft.identity.nativeauth.statemachine.errors.Error as MsalNativeAuthError
import com.microsoft.identity.nativeauth.statemachine.errors.GetAccountError
import com.microsoft.identity.nativeauth.statemachine.errors.GetAccessTokenError
import com.microsoft.identity.nativeauth.statemachine.errors.ResendCodeError
import com.microsoft.identity.nativeauth.statemachine.errors.ResetPasswordError
import com.microsoft.identity.nativeauth.statemachine.errors.ResetPasswordSubmitPasswordError
import com.microsoft.identity.nativeauth.statemachine.errors.SignInContinuationError
import com.microsoft.identity.nativeauth.statemachine.errors.SignInError
import com.microsoft.identity.nativeauth.statemachine.errors.SignInSubmitPasswordError
import com.microsoft.identity.nativeauth.statemachine.errors.SignOutError
import com.microsoft.identity.nativeauth.statemachine.errors.SignUpError
import com.microsoft.identity.nativeauth.statemachine.errors.SignUpSubmitAttributesError
import com.microsoft.identity.nativeauth.statemachine.errors.SignUpSubmitPasswordError
import com.microsoft.identity.nativeauth.statemachine.errors.SubmitCodeError
import com.microsoft.identity.nativeauth.statemachine.results.GetAccountResult
import com.microsoft.identity.nativeauth.statemachine.results.GetAccessTokenResult
import com.microsoft.identity.nativeauth.statemachine.results.SignInResendCodeResult
import com.microsoft.identity.nativeauth.statemachine.results.SignInResult
import com.microsoft.identity.nativeauth.statemachine.results.SignOutResult
import com.microsoft.identity.nativeauth.statemachine.results.ResetPasswordResendCodeResult
import com.microsoft.identity.nativeauth.statemachine.results.ResetPasswordResult
import com.microsoft.identity.nativeauth.statemachine.results.ResetPasswordStartResult
import com.microsoft.identity.nativeauth.statemachine.results.ResetPasswordSubmitCodeResult
import com.microsoft.identity.nativeauth.statemachine.results.SignUpResendCodeResult
import com.microsoft.identity.nativeauth.statemachine.results.SignUpResult
import com.microsoft.identity.nativeauth.statemachine.states.SignInCodeRequiredState
import com.microsoft.identity.nativeauth.statemachine.states.AccountState
import com.microsoft.identity.nativeauth.statemachine.states.ResetPasswordCodeRequiredState
import com.microsoft.identity.nativeauth.statemachine.states.ResetPasswordPasswordRequiredState
import com.microsoft.identity.nativeauth.statemachine.states.SignInPasswordRequiredState
import com.microsoft.identity.nativeauth.statemachine.states.SignUpAttributesRequiredState
import com.microsoft.identity.nativeauth.statemachine.states.SignUpCodeRequiredState
import com.microsoft.identity.nativeauth.statemachine.states.SignUpPasswordRequiredState
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.UUID
import kotlin.coroutines.resume

/** Pigeon host implementation backed by MSAL Native Authentication. */
class MicrosoftEntraExternalIdPlugin : FlutterPlugin, ActivityAware, NativeAuthHostApi {
    private var applicationContext: Context? = null
    private var activity: Activity? = null
    private var authClient: INativeAuthPublicClientApplication? = null
    private val continuations = mutableMapOf<String, AuthContinuation>()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        NativeAuthHostApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun getNativeSdkStatus() =
        NativeSdkStatusMessage(
            platform = NativePlatformMessage.ANDROID,
            linked = true,
            sdkVersion = MSAL_VERSION,
        )

    override suspend fun initialize(configuration: NativeAuthConfigurationMessage): NativeAuthResultMessage {
        val context = applicationContext
            ?: return failure("not_attached", "The Flutter plugin is not attached to an Android engine.")

        return try {
            val tenant = configuration.tenantSubdomain
            val parameters = NativeAuthPublicClientApplicationParameters(
                clientId = configuration.clientId,
                authorityUrl = "https://$tenant.ciamlogin.com/$tenant.onmicrosoft.com/",
                challengeTypes = listOf("oob", "password"),
            )
            parameters.redirectUri = configuration.redirectUri
            authClient = PublicClientApplication.createNativeAuthPublicClientApplication(context, parameters)
            continuations.clear()
            NativeAuthResultMessage(type = NativeAuthResultTypeMessage.INITIALIZED)
        } catch (error: Exception) {
            failure("initialization_failed", error.localizedMessage ?: "Unable to initialize MSAL.")
        }
    }

    override suspend fun acquireTokenWithBrowser(
        parameters: NativeAuthWebFallbackParametersMessage,
    ): NativeAuthResultMessage {
        val client = authClient ?: return notInitialized()
        val hostActivity = activity
            ?: return failure(
                "activity_unavailable",
                "A foreground Android Activity is required for browser authentication.",
            )
        if (parameters.scopes.isEmpty()) {
            return failure("invalid_scopes", "At least one browser scope is required.")
        }

        return suspendCancellableCoroutine { continuation ->
            val builder = AcquireTokenParameters.Builder()
                .startAuthorizationFromActivity(hostActivity)
                .withScopes(parameters.scopes)
                .withCallback(object : AuthenticationCallback {
                    override fun onSuccess(result: IAuthenticationResult) {
                        continuation.resume(
                            NativeAuthResultMessage(
                                type = NativeAuthResultTypeMessage.SIGNED_IN,
                                username = result.account.username,
                                idToken = result.account.idToken,
                                accessToken = result.accessToken,
                                scopes = result.scope.toList(),
                                expiresAtEpochMilliseconds = result.expiresOn.time,
                            ),
                        )
                    }

                    override fun onError(exception: MsalException) {
                        continuation.resume(
                            failure(
                                code = exception.errorCode.takeIf { it.isNotBlank() }
                                    ?: "browser_auth_failed",
                                message = exception.message ?: "Browser authentication failed.",
                            ),
                        )
                    }

                    override fun onCancel() {
                        continuation.resume(
                            failure("browser_auth_cancelled", "Browser authentication was cancelled."),
                        )
                    }
                })
            parameters.loginHint?.let(builder::withLoginHint)
            client.acquireToken(builder.build())
        }
    }

    override suspend fun getCurrentAccount(): NativeAuthResultMessage {
        val client = authClient ?: return notInitialized()
        return when (val result = client.getCurrentAccount()) {
            is GetAccountResult.AccountFound -> signedIn(result.resultValue)
            is GetAccountResult.NoAccountFound -> signedOut()
            is GetAccountError -> failure(result)
            else -> unsupported(result)
        }
    }

    override suspend fun startSignIn(parameters: NativeAuthSignInParametersMessage): NativeAuthResultMessage {
        val client = authClient ?: return notInitialized()
        continuations.clear()
        val password = parameters.password?.toCharArray()
        return try {
            val nativeParameters = NativeAuthSignInParameters(username = parameters.username).apply {
                this.password = password
                scopes = parameters.scopes.ifEmpty { null }
            }
            mapSignInResult(client.signIn(nativeParameters), parameters.scopes)
        } catch (error: Exception) {
            failure("sign_in_failed", error.localizedMessage ?: "Unable to start sign in.")
        } finally {
            password?.fill('\u0000')
        }
    }

    override suspend fun startSignUp(
        parameters: NativeAuthSignUpParametersMessage,
    ): NativeAuthResultMessage {
        val client = authClient ?: return notInitialized()
        continuations.clear()
        val password = parameters.password?.toCharArray()
        return try {
            val nativeParameters = NativeAuthSignUpParameters(username = parameters.username).apply {
                this.password = password
                attributes = parameters.attributes.toUserAttributesOrNull()
            }
            mapSignUpResult(client.signUp(nativeParameters))
        } catch (error: Exception) {
            failure("sign_up_failed", error.localizedMessage ?: "Unable to start sign up.")
        } finally {
            password?.fill('\u0000')
        }
    }

    override suspend fun startResetPassword(
        parameters: NativeAuthResetPasswordParametersMessage,
    ): NativeAuthResultMessage {
        val client = authClient ?: return notInitialized()
        continuations.clear()
        return try {
            when (
                val result = client.resetPassword(
                    NativeAuthResetPasswordParameters(username = parameters.username),
                )
            ) {
                is ResetPasswordStartResult.CodeRequired -> {
                    val continuationId = UUID.randomUUID().toString()
                    continuations[continuationId] = AuthContinuation.ResetPasswordCode(
                        state = result.nextState,
                        scopes = parameters.scopes,
                    )
                    codeRequired(
                        operation = NativeAuthOperationMessage.PASSWORD_RESET,
                        continuationId = continuationId,
                        sentTo = result.sentTo,
                        codeLength = result.codeLength,
                    )
                }
                is ResetPasswordError -> failure(result)
                else -> unsupported(result)
            }
        } catch (error: Exception) {
            failure(
                "password_reset_failed",
                error.localizedMessage ?: "Unable to start password reset.",
            )
        }
    }

    override suspend fun submitCode(continuationId: String, code: String): NativeAuthResultMessage {
        return when (val continuation = continuations[continuationId]) {
            is AuthContinuation.SignInCode -> {
                when (val result = continuation.state.submitCode(code)) {
                    is SignInResult.Complete -> {
                        continuations.remove(continuationId)
                        signedIn(result.resultValue, continuation.scopes)
                    }
                    is SubmitCodeError -> failure(result)
                    else -> unsupported(result)
                }
            }
            is AuthContinuation.SignUpCode -> {
                when (val result = continuation.state.submitCode(code)) {
                    is SignUpResult.Complete -> {
                        continuations.remove(continuationId)
                        signInAfterPreviousFlow(result.nextState)
                    }
                    is SignUpResult.PasswordRequired -> {
                        continuations[continuationId] =
                            AuthContinuation.SignUpPassword(result.nextState)
                        passwordRequired(
                            operation = NativeAuthOperationMessage.SIGN_UP,
                            continuationId = continuationId,
                        )
                    }
                    is SignUpResult.AttributesRequired ->
                        storeAttributesRequired(continuationId, result)
                    is SubmitCodeError -> failure(result)
                    else -> unsupported(result)
                }
            }
            is AuthContinuation.ResetPasswordCode -> {
                when (val result = continuation.state.submitCode(code)) {
                    is ResetPasswordSubmitCodeResult.PasswordRequired -> {
                        continuations[continuationId] =
                            AuthContinuation.ResetPasswordPassword(
                                state = result.nextState,
                                scopes = continuation.scopes,
                            )
                        passwordRequired(
                            operation = NativeAuthOperationMessage.PASSWORD_RESET,
                            continuationId = continuationId,
                        )
                    }
                    is SubmitCodeError -> failure(result)
                    else -> unsupported(result)
                }
            }
            is AuthContinuation.SignInPassword,
            is AuthContinuation.SignUpPassword,
            is AuthContinuation.SignUpAttributes,
            is AuthContinuation.ResetPasswordPassword,
            -> invalidContinuation()
            null -> failure(
                "invalid_continuation",
                "The native authentication continuation is missing or expired. Restart the flow.",
            )
        }
    }

    override suspend fun submitPassword(continuationId: String, password: String): NativeAuthResultMessage {
        val passwordCharacters = password.toCharArray()
        return try {
            when (val continuation = continuations[continuationId]) {
                is AuthContinuation.SignInPassword ->
                    submitSignInPassword(continuationId, continuation, passwordCharacters)
                is AuthContinuation.SignUpPassword ->
                    submitSignUpPassword(continuationId, continuation, passwordCharacters)
                is AuthContinuation.ResetPasswordPassword ->
                    submitResetPassword(continuationId, continuation, passwordCharacters)
                else -> invalidContinuation()
            }
        } catch (error: Exception) {
            failure("password_submission_failed", error.localizedMessage ?: "Unable to submit password.")
        } finally {
            passwordCharacters.fill('\u0000')
        }
    }

    override suspend fun submitAttributes(
        continuationId: String,
        attributes: List<NativeAuthAttributeMessage>,
    ): NativeAuthResultMessage {
        val continuation = continuations[continuationId]
        if (continuation !is AuthContinuation.SignUpAttributes) {
            return invalidContinuation()
        }

        return try {
            when (val result = continuation.state.submitAttributes(attributes.toUserAttributes())) {
                is SignUpResult.Complete -> {
                    continuations.remove(continuationId)
                    signInAfterPreviousFlow(result.nextState)
                }
                is SignUpResult.AttributesRequired ->
                    storeAttributesRequired(continuationId, result)
                is SignUpSubmitAttributesError -> {
                    if (result.isInvalidAttributes()) {
                        attributesRequired(
                            continuationId = continuationId,
                            requiredAttributes = continuation.requiredAttributes,
                        )
                    } else {
                        failure(result)
                    }
                }
                else -> unsupported(result)
            }
        } catch (error: Exception) {
            failure(
                "attributes_submission_failed",
                error.localizedMessage ?: "Unable to submit sign-up attributes.",
            )
        }
    }

    override suspend fun resendCode(continuationId: String): NativeAuthResultMessage {
        return when (val continuation = continuations[continuationId]) {
            is AuthContinuation.SignInCode -> {
                when (val result = continuation.state.resendCode()) {
                    is SignInResendCodeResult.Success -> {
                        continuation.state = result.nextState
                        codeRequired(
                            operation = NativeAuthOperationMessage.SIGN_IN,
                            continuationId = continuationId,
                            sentTo = result.sentTo,
                            codeLength = result.codeLength,
                        )
                    }
                    is ResendCodeError -> failure(result)
                    else -> unsupported(result)
                }
            }
            is AuthContinuation.SignUpCode -> {
                when (val result = continuation.state.resendCode()) {
                    is SignUpResendCodeResult.Success -> {
                        continuation.state = result.nextState
                        codeRequired(
                            operation = NativeAuthOperationMessage.SIGN_UP,
                            continuationId = continuationId,
                            sentTo = result.sentTo,
                            codeLength = result.codeLength,
                        )
                    }
                    is ResendCodeError -> failure(result)
                    else -> unsupported(result)
                }
            }
            is AuthContinuation.ResetPasswordCode -> {
                when (val result = continuation.state.resendCode()) {
                    is ResetPasswordResendCodeResult.Success -> {
                        continuation.state = result.nextState
                        codeRequired(
                            operation = NativeAuthOperationMessage.PASSWORD_RESET,
                            continuationId = continuationId,
                            sentTo = result.sentTo,
                            codeLength = result.codeLength,
                        )
                    }
                    is ResendCodeError -> failure(result)
                    else -> unsupported(result)
                }
            }
            is AuthContinuation.SignInPassword,
            is AuthContinuation.SignUpPassword,
            is AuthContinuation.SignUpAttributes,
            is AuthContinuation.ResetPasswordPassword,
            -> invalidContinuation()
            null -> failure(
                "invalid_continuation",
                "The native authentication continuation is missing or expired. Restart the flow.",
            )
        }
    }

    override suspend fun getAccessToken(
        parameters: NativeAuthAccessTokenParametersMessage,
    ): NativeAuthResultMessage {
        val client = authClient ?: return notInitialized()
        return when (val account = client.getCurrentAccount()) {
            is GetAccountResult.AccountFound -> signedIn(
                account = account.resultValue,
                scopes = parameters.scopes,
                forceRefresh = parameters.forceRefresh,
            )
            is GetAccountResult.NoAccountFound -> signedOut()
            is GetAccountError -> failure(account)
            else -> unsupported(account)
        }
    }

    override suspend fun signOut(): NativeAuthResultMessage {
        val client = authClient ?: return notInitialized()
        return when (val account = client.getCurrentAccount()) {
            is GetAccountResult.NoAccountFound -> signedOut()
            is GetAccountError -> failure(account)
            is GetAccountResult.AccountFound -> {
                when (val result = account.resultValue.signOut()) {
                    is SignOutResult.Complete -> {
                        continuations.clear()
                        signedOut()
                    }
                    is SignOutError -> failure(result)
                    else -> unsupported(result)
                }
            }
            else -> unsupported(account)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        NativeAuthHostApi.setUp(binding.binaryMessenger, null)
        continuations.clear()
        authClient = null
        activity = null
        applicationContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    private suspend fun mapSignInResult(
        result: SignInResult,
        scopes: List<String> = emptyList(),
    ): NativeAuthResultMessage = when (result) {
        is SignInResult.Complete -> signedIn(result.resultValue, scopes)
        is SignInResult.CodeRequired -> {
            val continuationId = UUID.randomUUID().toString()
            continuations[continuationId] = AuthContinuation.SignInCode(result.nextState, scopes)
            codeRequired(
                operation = NativeAuthOperationMessage.SIGN_IN,
                continuationId = continuationId,
                sentTo = result.sentTo,
                codeLength = result.codeLength,
            )
        }
        is SignInError -> failure(result)
        is SignInContinuationError -> failure(result)
        is SignInResult.PasswordRequired -> {
            val continuationId = UUID.randomUUID().toString()
            continuations[continuationId] = AuthContinuation.SignInPassword(result.nextState, scopes)
            passwordRequired(
                operation = NativeAuthOperationMessage.SIGN_IN,
                continuationId = continuationId,
            )
        }
        is SignInResult.MFARequired -> failure(
            "mfa_required",
            "The plugin does not yet implement multifactor authentication.",
        )
        is SignInResult.StrongAuthMethodRegistrationRequired -> failure(
            "strong_auth_registration_required",
            "The plugin does not yet implement strong authentication registration.",
        )
        else -> unsupported(result)
    }

    private suspend fun mapSignUpResult(result: SignUpResult): NativeAuthResultMessage = when (result) {
        is SignUpResult.CodeRequired -> {
            val continuationId = UUID.randomUUID().toString()
            continuations[continuationId] = AuthContinuation.SignUpCode(result.nextState)
            codeRequired(
                operation = NativeAuthOperationMessage.SIGN_UP,
                continuationId = continuationId,
                sentTo = result.sentTo,
                codeLength = result.codeLength,
            )
        }
        is SignUpResult.Complete -> signInAfterPreviousFlow(result.nextState)
        is SignUpResult.AttributesRequired -> {
            val continuationId = UUID.randomUUID().toString()
            storeAttributesRequired(continuationId, result)
        }
        is SignUpResult.PasswordRequired -> {
            val continuationId = UUID.randomUUID().toString()
            continuations[continuationId] = AuthContinuation.SignUpPassword(result.nextState)
            passwordRequired(
                operation = NativeAuthOperationMessage.SIGN_UP,
                continuationId = continuationId,
            )
        }
        is SignUpError -> failure(result)
        else -> unsupported(result)
    }

    private fun codeRequired(
        operation: NativeAuthOperationMessage,
        continuationId: String,
        sentTo: String?,
        codeLength: Int?,
    ) = NativeAuthResultMessage(
        type = NativeAuthResultTypeMessage.CODE_REQUIRED,
        operation = operation,
        continuationId = continuationId,
        sentTo = sentTo,
        codeLength = codeLength?.toLong(),
    )

    private fun passwordRequired(
        operation: NativeAuthOperationMessage,
        continuationId: String,
    ) = NativeAuthResultMessage(
        type = NativeAuthResultTypeMessage.PASSWORD_REQUIRED,
        operation = operation,
        continuationId = continuationId,
    )

    private fun attributesRequired(
        continuationId: String,
        requiredAttributes: List<RequiredUserAttribute>,
        invalidAttributeNames: List<String> = emptyList(),
    ) = NativeAuthResultMessage(
        type = NativeAuthResultTypeMessage.ATTRIBUTES_REQUIRED,
        operation = NativeAuthOperationMessage.SIGN_UP,
        continuationId = continuationId,
        requiredAttributes = requiredAttributes.mapNotNull { attribute ->
            val name = attribute.attributeName ?: return@mapNotNull null
            NativeAuthRequiredAttributeMessage(
                name = name,
                type = attribute.type ?: "string",
                required = attribute.required ?: false,
                regex = attribute.options?.regex,
            )
        },
        invalidAttributeNames = invalidAttributeNames,
    )

    private fun storeAttributesRequired(
        continuationId: String,
        result: SignUpResult.AttributesRequired,
        invalidAttributeNames: List<String> = emptyList(),
    ): NativeAuthResultMessage {
        continuations[continuationId] = AuthContinuation.SignUpAttributes(
            state = result.nextState,
            requiredAttributes = result.requiredAttributes,
        )
        return attributesRequired(
            continuationId = continuationId,
            requiredAttributes = result.requiredAttributes,
            invalidAttributeNames = invalidAttributeNames,
        )
    }

    private suspend fun submitSignInPassword(
        continuationId: String,
        continuation: AuthContinuation.SignInPassword,
        password: CharArray,
    ): NativeAuthResultMessage = when (val result = continuation.state.submitPassword(password)) {
        is SignInResult.Complete -> {
            continuations.remove(continuationId)
            signedIn(result.resultValue, continuation.scopes)
        }
        is SignInResult.CodeRequired -> {
            continuations[continuationId] = AuthContinuation.SignInCode(
                state = result.nextState,
                scopes = continuation.scopes,
            )
            codeRequired(
                operation = NativeAuthOperationMessage.SIGN_IN,
                continuationId = continuationId,
                sentTo = result.sentTo,
                codeLength = result.codeLength,
            )
        }
        is SignInSubmitPasswordError -> failure(result)
        is SignInResult.MFARequired -> failure(
            "mfa_required",
            "The plugin does not yet implement multifactor authentication.",
        )
        is SignInResult.StrongAuthMethodRegistrationRequired -> failure(
            "strong_auth_registration_required",
            "The plugin does not yet implement strong authentication registration.",
        )
        else -> unsupported(result)
    }

    private suspend fun submitSignUpPassword(
        continuationId: String,
        continuation: AuthContinuation.SignUpPassword,
        password: CharArray,
    ): NativeAuthResultMessage = when (val result = continuation.state.submitPassword(password)) {
        is SignUpResult.Complete -> {
            continuations.remove(continuationId)
            signInAfterPreviousFlow(result.nextState)
        }
        is SignUpResult.AttributesRequired -> storeAttributesRequired(continuationId, result)
        is SignUpSubmitPasswordError -> failure(result)
        else -> unsupported(result)
    }

    private suspend fun submitResetPassword(
        continuationId: String,
        continuation: AuthContinuation.ResetPasswordPassword,
        password: CharArray,
    ): NativeAuthResultMessage = when (val result = continuation.state.submitPassword(password)) {
        is ResetPasswordResult.Complete -> {
            continuations.remove(continuationId)
            signInAfterPreviousFlow(result.nextState, continuation.scopes)
        }
        is ResetPasswordSubmitPasswordError -> failure(result)
        else -> unsupported(result)
    }

    private suspend fun signInAfterPreviousFlow(
        state: com.microsoft.identity.nativeauth.statemachine.states.SignInContinuationState,
        scopes: List<String> = emptyList(),
    ): NativeAuthResultMessage {
        val parameters = NativeAuthSignInContinuationParameters().apply {
            this.scopes = scopes.ifEmpty { null }
        }
        return mapSignInResult(state.signIn(parameters), scopes)
    }

    private suspend fun signedIn(
        account: AccountState,
        scopes: List<String> = emptyList(),
        forceRefresh: Boolean = false,
    ): NativeAuthResultMessage {
        val parameters = NativeAuthGetAccessTokenParameters().apply {
            this.forceRefresh = forceRefresh
            this.scopes = scopes.ifEmpty { null }
        }
        return when (val result = account.getAccessToken(parameters)) {
            is GetAccessTokenResult.Complete -> NativeAuthResultMessage(
                type = NativeAuthResultTypeMessage.SIGNED_IN,
                username = account.getAccount().username,
                idToken = account.getIdToken(),
                accessToken = result.resultValue.accessToken,
                scopes = result.resultValue.scope.toList(),
                expiresAtEpochMilliseconds = result.resultValue.expiresOn.time,
            )
            is GetAccessTokenError -> failure(result)
            else -> unsupported(result)
        }
    }

    private fun signedOut() = NativeAuthResultMessage(type = NativeAuthResultTypeMessage.SIGNED_OUT)

    private fun notInitialized() = failure(
        "not_initialized",
        "Call initialize before using Microsoft Entra External ID native authentication.",
    )

    private fun invalidContinuation() = failure(
        "invalid_continuation",
        "The native authentication continuation is missing or expired. Restart the flow.",
    )

    private fun failure(error: MsalNativeAuthError): NativeAuthResultMessage {
        val browserRequired = (error as? BrowserRequiredError)?.isBrowserRequired() == true
        return failure(
            code = error.error ?: error.javaClass.simpleName,
            message = error.errorMessage ?: error.exception?.localizedMessage ?: "Native authentication failed.",
            browserRequired = browserRequired,
        )
    }

    private fun failure(
        code: String,
        message: String,
        browserRequired: Boolean = false,
    ) = NativeAuthResultMessage(
        type = if (browserRequired) {
            NativeAuthResultTypeMessage.BROWSER_REQUIRED
        } else {
            NativeAuthResultTypeMessage.ERROR
        },
        errorCode = code,
        errorMessage = message,
    )

    private fun unsupported(result: Any) = failure(
        "unexpected_result",
        "Unsupported MSAL result: ${result.javaClass.simpleName}.",
    )

    private sealed interface AuthContinuation {
        data class SignInCode(
            var state: SignInCodeRequiredState,
            val scopes: List<String>,
        ) : AuthContinuation

        data class SignInPassword(
            var state: SignInPasswordRequiredState,
            val scopes: List<String>,
        ) : AuthContinuation

        data class SignUpCode(var state: SignUpCodeRequiredState) : AuthContinuation

        data class SignUpPassword(var state: SignUpPasswordRequiredState) : AuthContinuation

        data class SignUpAttributes(
            var state: SignUpAttributesRequiredState,
            val requiredAttributes: List<RequiredUserAttribute>,
        ) : AuthContinuation

        data class ResetPasswordCode(
            var state: ResetPasswordCodeRequiredState,
            val scopes: List<String>,
        ) : AuthContinuation

        data class ResetPasswordPassword(
            var state: ResetPasswordPasswordRequiredState,
            val scopes: List<String>,
        ) : AuthContinuation
    }

    private fun List<NativeAuthAttributeMessage>.toUserAttributes(): UserAttributes {
        val builder = UserAttributes.Builder()
        forEach { attribute -> builder.customAttribute(attribute.name, attribute.value) }
        return builder.build()
    }

    private fun List<NativeAuthAttributeMessage>.toUserAttributesOrNull(): UserAttributes? =
        takeIf { it.isNotEmpty() }?.toUserAttributes()

    private companion object {
        const val MSAL_VERSION = "8.4.2"
    }
}
