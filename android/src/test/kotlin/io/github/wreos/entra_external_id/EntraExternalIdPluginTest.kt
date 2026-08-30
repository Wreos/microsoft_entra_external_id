package io.github.wreos.entra_external_id

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Test

/*
 * Verifies the bootstrap diagnostic without claiming that MSAL is already linked.
 */
internal class EntraExternalIdPluginTest {
    @Test
    fun getNativeSdkStatus_reportsUnlinkedAndroidBridge() {
        val plugin = EntraExternalIdPlugin()
        val status = plugin.getNativeSdkStatus()

        assertEquals(NativePlatformMessage.ANDROID, status.platform)
        assertFalse(status.linked)
        assertNull(status.sdkVersion)
    }
}
