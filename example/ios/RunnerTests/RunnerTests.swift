import Flutter
import XCTest

@testable import microsoft_entra_external_id

class RunnerTests: XCTestCase {
  func testInitializeCreatesNativeClientWithPublicConfiguration() async throws {
    let plugin = MicrosoftEntraExternalIdPlugin()
    let configuration = NativeAuthConfigurationMessage(
      clientId: "00000000-0000-0000-0000-000000000000",
      tenantSubdomain: "contoso",
      redirectUri: "msauth.io.github.wreos.microsoftEntraExternalIdExample://auth"
    )

    let result = try await plugin.initialize(configuration: configuration)

    XCTAssertEqual(result.type, .initialized, result.errorMessage ?? "Initialization failed")
    XCTAssertNil(result.errorCode)
  }

  func testNativeSdkStatusReportsLinkedIOSSDK() throws {
    let plugin = MicrosoftEntraExternalIdPlugin()
    let status = try plugin.getNativeSdkStatus()

    XCTAssertEqual(status.platform, .ios)
    XCTAssertTrue(status.linked)
    XCTAssertEqual(status.sdkVersion, "2.16.0")
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
