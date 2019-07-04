import XCTest

import SimpleHttpClient

@testable import MediaApis

class AuthAPITests: XCTestCase {
  static func getProjectDirectory() -> String {
    return String(URL(fileURLWithPath: #file).pathComponents
      .prefix(while: { $0 != "Tests" }).joined(separator: "/").dropFirst());
  }

  static let path = URL(fileURLWithPath: getProjectDirectory())

  static var config = ConfigFile<String>(path: path, fileName: "etvnet.config")
  
  var subject = EtvnetAPI(configFile: config)
  
  func testGetActivationCodes() throws {
    if let result = try self.subject.apiClient.authClient.getActivationCodes() {
      XCTAssertNotNil(result)

      print("Activation url: \(self.subject.apiClient.authClient.getActivationUrl())")

      if let userCode = result.userCode {
        print("Activation code: \(userCode)")        
      }

      if let deviceCode = result.deviceCode {
        print("Device code: \(deviceCode)") 
      }
    }
    else {
      XCTFail("Error during request")
    }
  }
  
  func testCreateToken() throws {
    if let result = try subject.apiClient.authorization() {
      print("Register activation code on web site \(subject.apiClient.authClient.getActivationUrl()): \(result.userCode)")

      if let response = subject.apiClient.createToken(deviceCode: result.deviceCode) {
        XCTAssertNotNil(response.accessToken)
        XCTAssertNotNil(response.refreshToken)

        print("Result: \(result)") 
      }
      else {
        XCTFail()
      }
    }
    else {
      XCTFail()
    }
  }
  
  func testUpdateToken() throws {
    let refreshToken = subject.apiClient.configFile.items["refresh_token"]!

    if let result = try self.subject.apiClient.authClient.updateToken(refreshToken: refreshToken) {
      XCTAssertNotNil(result.accessToken)

      print("Result: \(result)")

      subject.apiClient.configFile.items = result.asMap()

      if let result = (try Await.await() { handler in
        self.subject.apiClient.configFile.write(handler)
      }) {
        print("Config saved.")
      }
      else {
        XCTFail()
      }
    }
    else {
      XCTFail("Error during request")
    }
  }
}
