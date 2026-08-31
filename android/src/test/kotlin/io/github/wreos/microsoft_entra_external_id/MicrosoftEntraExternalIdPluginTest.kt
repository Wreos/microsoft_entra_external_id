package io.github.wreos.microsoft_entra_external_id

import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

internal class MicrosoftEntraExternalIdPluginTest {
    @Test
    fun getNativeSdkStatus_reportsLinkedAndroidSdk() {
        val plugin = MicrosoftEntraExternalIdPlugin()
        val status = plugin.getNativeSdkStatus()

        assertEquals(NativePlatformMessage.ANDROID, status.platform)
        assertTrue(status.linked)
        assertEquals("8.4.2", status.sdkVersion)
    }

    @Test
    fun getCurrentAccount_beforeInitialization_returnsTypedFailure() = runBlocking {
        val result = MicrosoftEntraExternalIdPlugin().getCurrentAccount()

        assertEquals(NativeAuthResultTypeMessage.ERROR, result.type)
        assertEquals("not_initialized", result.errorCode)
    }

    @Test
    fun initialize_beforeEngineAttachment_returnsTypedFailure() = runBlocking {
        val result = MicrosoftEntraExternalIdPlugin().initialize(
            NativeAuthConfigurationMessage(
                clientId = "00000000-0000-0000-0000-000000000000",
                tenantSubdomain = "contoso",
            ),
        )

        assertEquals(NativeAuthResultTypeMessage.ERROR, result.type)
        assertEquals("not_attached", result.errorCode)
    }
}
