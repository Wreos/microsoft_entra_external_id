import Flutter
import XCTest

@testable import microsoft_entra_external_id

class RunnerTests: XCTestCase {
  func testNativeSdkStatusReportsLinkedIOSSDK() throws {
    let plugin = MicrosoftEntraExternalIdPlugin()
    let status = try plugin.getNativeSdkStatus()

    XCTAssertEqual(status.platform, .ios)
    XCTAssertTrue(status.linked)
    XCTAssertEqual(status.sdkVersion, "2.15.0")
  }

  func testCurrentAccountBeforeInitializationReturnsTypedFailure() async throws {
    let result = try await MicrosoftEntraExternalIdPlugin().getCurrentAccount()

    XCTAssertEqual(result.type, .error)
    XCTAssertEqual(result.errorCode, "not_initialized")
  }

  func testGetAccessTokenBeforeInitializationReturnsTypedFailure() async throws {
    let plugin = MicrosoftEntraExternalIdPlugin()
    let parameters = NativeAuthAccessTokenParametersMessage(
      scopes: ["api://client/read"],
      forceRefresh: true
    )

    let result = try await plugin.getAccessToken(parameters: parameters)

    XCTAssertEqual(result.type, .error)
    XCTAssertEqual(result.errorCode, "not_initialized")
  }

  func testSubmitPasswordWithoutContinuationReturnsTypedFailure() async throws {
    let plugin = MicrosoftEntraExternalIdPlugin()

    let result = try await plugin.submitPassword(
      continuationId: "missing",
      password: "not-logged"
    )

    XCTAssertEqual(result.type, .error)
    XCTAssertEqual(result.errorCode, "invalid_continuation")
  }
}
