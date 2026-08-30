package io.github.wreos.entra_external_id

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
}
