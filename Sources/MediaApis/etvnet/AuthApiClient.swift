import Foundation
import SimpleHttpClient

open class AuthApiClient: ApiClient {
  private let ClientId = "a332b9d61df7254dffdc81a260373f25592c94c9"
  private let ClientSecret = "744a52aff20ec13f53bcfd705fc4b79195265497"
  private let GrantType = "http://oauth.net/grant_type/device/1.0"

  public let Scope = [
    "com.etvnet.media.browse",
    "com.etvnet.media.watch",
    "com.etvnet.media.bookmarks",
    "com.etvnet.media.history",
    "com.etvnet.media.live",
    "com.etvnet.media.fivestar",
    "com.etvnet.media.comments",
    "com.etvnet.persons",
    "com.etvnet.notifications"
  ].joined(separator: " ")

  public func getActivationUrl() -> String {
    return "\(baseURL)device/usercode"
  }
  
  func getActivationCodes(includeClientSecret: Bool = true, includeClientId: Bool = true) throws ->
    ActivationCodesProperties? {
    var properties: ActivationCodesProperties?

    var queryItems: Set<URLQueryItem> = []

    queryItems.insert(URLQueryItem(name: "scope", value: Scope))

    if includeClientSecret {
      queryItems.insert(URLQueryItem(name: "client_secret", value: ClientSecret))
    }
    
    if includeClientId {
      queryItems.insert(URLQueryItem(name: "client_id", value: ClientId))
    }

    let request = ApiRequest(path: "device/code", queryItems: queryItems)

    let response = try Await.await() { handler in
      self.fetch(request, handler)
    }

    if let response = response, let body = response.data {
      if let props = try self.decode(body, to: ActivationCodesProperties.self) {
        properties = props
      }
    }

    return properties
  }

  @discardableResult
  public func createToken(deviceCode: String) throws -> AuthProperties? {
    var properties: AuthProperties?

    var queryItems: Set<URLQueryItem> = []

    queryItems.insert(URLQueryItem(name: "grant_type", value: GrantType))
    queryItems.insert(URLQueryItem(name: "code", value: deviceCode))
    queryItems.insert(URLQueryItem(name: "client_secret", value: ClientSecret))
    queryItems.insert(URLQueryItem(name: "client_id", value: ClientId))

    let request = ApiRequest(path: "token", queryItems: queryItems)

    let response = try Await.await() { handler in
      self.fetch(request, handler)
    }

    if let response = response, let body = response.data {
      do {
        _ = try self.decode(body, to: ErrorProperties.self)
      }
      catch {
        if let props = try self.decode(body, to: AuthProperties.self) {
          properties = props
        }
      }
    }

    return properties
  }

  @discardableResult
  func updateToken(refreshToken: String) throws -> AuthProperties? {
    var properties: AuthProperties?

    var queryItems: Set<URLQueryItem> = []

    queryItems.insert(URLQueryItem(name: "grant_type", value: "refresh_token"))
    queryItems.insert(URLQueryItem(name: "refresh_token", value: refreshToken))
    queryItems.insert(URLQueryItem(name: "client_secret", value: ClientSecret))
    queryItems.insert(URLQueryItem(name: "client_id", value: ClientId))

    let request = ApiRequest(path: "token", queryItems: queryItems)

    let response = try Await.await { handler in
      self.fetch(request, handler)
    }

    if let response = response, let body = response.data {
      properties = try self.decode(body, to: AuthProperties.self)
    }

    return properties
  }
}
