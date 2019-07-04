import Foundation
import SimpleHttpClient
import Codextended

public struct AuthResult {
  public let userCode: String
  public let deviceCode: String
}

public struct ErrorProperties: Codable {
  public let error: String
  public let error_description: String
}

public struct ActivationCodesProperties: Codable, CustomStringConvertible {
  public let deviceCode: String?
  public let userCode: String?

  enum CodingKeys: String, CodingKey {
    case deviceCode = "device_code"
    case userCode = "user_code"
  }

  public init(from decoder: Decoder) throws {
    deviceCode = try decoder.decode("device_code")
    userCode = try decoder.decode("user_code")
  }

  public var description: String {
    return "ActivationCodesProperties(\(deviceCode ?? ""), \(userCode ?? ""))"
  }
}

public struct AuthProperties: Codable, CustomStringConvertible {
  public var accessToken: String?
  public var refreshToken: String?
  public var expiresIn: Int?

  private var expires: Int?

  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case expiresIn = "expires_in"
  }

  public init(from decoder: Decoder) throws {
    accessToken = try decoder.decode("access_token")
    refreshToken = try decoder.decode("refresh_token")
    expiresIn = try decoder.decode("expires_in")

    if let expiresIn = expiresIn {
      expires = Int(Date().timeIntervalSince1970) + expiresIn
    }
  }

  public func asMap() -> [String: String] {
    var map = [String: String]()

    if let accessToken = accessToken {
      map["access_token"] = accessToken
    }

    if let refreshToken = refreshToken {
      map["refresh_token"] = refreshToken
    }

    if let expires = expires {
      map["expires"] = String(expires)
    }

    return map
  }

  public var description: String {
    return "AuthProperties(\(accessToken ?? ""), \(refreshToken ?? ""), \(expiresIn ?? 0), \(expires ?? 0))"
  }
}
