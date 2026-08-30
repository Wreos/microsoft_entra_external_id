import Flutter
import XCTest

@testable import entra_external_id

class RunnerTests: XCTestCase {
  func testNativeSdkStatusReportsLinkedIOSSDK() throws {
    let plugin = EntraExternalIdPlugin()
    let status = try plugin.getNativeSdkStatus()

    XCTAssertEqual(status.platform, .ios)
    XCTAssertTrue(status.linked)
    XCTAssertEqual(status.sdkVersion, "2.15.0")
  }
}
