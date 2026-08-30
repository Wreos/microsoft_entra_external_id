import Flutter
import XCTest

@testable import entra_external_id

class RunnerTests: XCTestCase {
  func testNativeSdkStatusReportsUnlinkedIOSBridge() throws {
    let plugin = EntraExternalIdPlugin()
    let status = try plugin.getNativeSdkStatus()

    XCTAssertEqual(status.platform, .ios)
    XCTAssertFalse(status.linked)
    XCTAssertNil(status.sdkVersion)
  }
}
