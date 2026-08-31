package io.github.wreos.entra_external_id

import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

internal class EntraExternalIdPluginTest {
    @Test
    fun getNativeSdkStatus_reportsLinkedAndroidSdk() {
        val plugin = EntraExternalIdPlugin()
        val status = plugin.getNativeSdkStatus()

        assertEquals(NativePlatformMessage.ANDROID, status.platform)
        assertTrue(status.linked)
        assertEquals("8.4.2", status.sdkVersion)
    }

    @Test
    fun getCurrentAccount_beforeInitialization_returnsTypedFailure() = runBlocking {
        val result = EntraExternalIdPlugin().getCurrentAccount()

        assertEquals(NativeAuthResultTypeMessage.ERROR, result.type)
        assertEquals("not_initialized", result.errorCode)
    }

    @Test
    fun initialize_beforeEngineAttachment_returnsTypedFailure() = runBlocking {
        val result = EntraExternalIdPlugin().initialize(
            NativeAuthConfigurationMessage(
                clientId = "00000000-0000-0000-0000-000000000000",
                tenantSubdomain = "contoso",
            ),
        )

        assertEquals(NativeAuthResultTypeMessage.ERROR, result.type)
        assertEquals("not_attached", result.errorCode)
    }
}
