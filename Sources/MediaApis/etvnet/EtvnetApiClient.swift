import Foundation
import SimpleHttpClient

open class EtvnetApiClient: ApiClient {
  public let UserAgent = "Etvnet User Agent"

  public var configFile: ConfigFile<String>!

  public let authClient: AuthApiClient!

  public var authorizeCallback: () -> Void = {}

  init(_ url: String, authUrl: String) {
    authClient = AuthApiClient(URL(string: authUrl)!)

    super.init(URL(string: url)!)
  }
}

extension EtvnetApiClient {
  func setConfigFile(_ configFile: ConfigFile<String>) {
    self.configFile = configFile
  }

  public func loadConfig() throws {
    if (configFile.exists()) {
      if let items = (try Await.await() { handler in
        self.configFile.read(handler)
      }) {
        self.configFile.items = items
      }
    }
  }

  public func saveConfig() throws {
    try Await.await() { handler in
      self.configFile.write(handler)
    }
  }
}

extension EtvnetApiClient {
  public func resetToken() throws {
    _ = configFile.remove("access_token")
    _ = configFile.remove("refresh_token")
    _ = configFile.remove("device_code")
    _ = configFile.remove("user_code")
    _ = configFile.remove("activation_url")

    try saveConfig()
  }

  public func addAccessToken(params: Set<URLQueryItem>, accessToken: String) -> Set<URLQueryItem> {
    var newParams: Set<URLQueryItem> = []

    for param in params {
      newParams.insert(param)
    }

    newParams.insert(URLQueryItem(name: "access_token", value: accessToken))

    return newParams
  }

  public func authorization(includeClientSecret: Bool = true) throws -> AuthResult? {
    var result: AuthResult?

    if configFile.items["device_code"] != nil && checkAccessData("user_code"),
       let userCode = configFile.items["user_code"],
       let deviceCode = configFile.items["device_code"] {
      result = AuthResult(userCode: userCode, deviceCode: deviceCode)
    } else {
      if let value = try self.authClient.getActivationCodes(includeClientSecret: includeClientSecret) {
        if let userCode = value.userCode,
           let deviceCode = value.deviceCode {
//          self.configFile.items["user_code"] = userCode
//          self.configFile.items["device_code"] = deviceCode
//          self.configFile.items["activation_url"] = authClient.getActivationUrl()

          //try self.saveConfig()

          result = AuthResult(userCode: userCode, deviceCode: deviceCode)
        }
      }
    }

    return result
  }

  public func checkAuthorization() -> Bool {
    var ok = false

    if checkAccessData("access_token") {
      ok = true
    } else if configFile.items["refresh_token"] != nil {
      do {
        let refreshToken = configFile.items["refresh_token"]

        if let refreshToken = refreshToken {
          if let value = try updateToken(refreshToken) {
            ok = true
            self.configFile.items = value.asMap()
            try self.saveConfig()
          }
        }
      } catch {
        print(error)
      }
    }

    if !ok {
      if configFile.items["device_code"] != nil {
        let deviceCode = configFile.items["device_code"]

        do {
          if let deviceCode = deviceCode {
            if let value = try self.authClient.createToken(deviceCode: deviceCode) {
              ok = true

              self.configFile.items = value.asMap()
              try self.saveConfig()
            }
          }
        } catch {
          print(error)
        }
      }
    }

    return ok
  }

  public func createToken(deviceCode: String, delayCallback: () -> Void = { sleep(5) }) -> AuthProperties? {
    var result: AuthProperties?

    var done = false

    while !done {
      do {
        if let value = try self.authClient.createToken(deviceCode: deviceCode) {
          done = value.accessToken != nil

          if done {
            result = value

            self.configFile.items = value.asMap()
            try saveConfig()
          }
        }
      } catch {
        print(error)
      }

      if !done {
        delayCallback()
      }
    }

    return result
  }

  func updateToken(_ refreshToken: String) throws -> AuthProperties? {
    try self.authClient.updateToken(refreshToken: refreshToken)
  }

  func checkAccessData(_ key: String) -> Bool {
    (configFile.items[key] != nil) && (configFile.items["expires"] != nil) &&
        configFile.items["expires"]! >= String(Int(Date().timeIntervalSince1970))
  }
}

extension EtvnetApiClient {
  @discardableResult
  func fullRequest<T: Decodable>(path: String, to type: T.Type, method: HttpMethod = .get,
                                 queryItems: Set<URLQueryItem> = [], unauthorized: Bool=false) throws ->
    (value: T, response: ApiResponse)? {
    var result: (value: T, response: ApiResponse)?

    if !checkAuthorization() {
      authorizeCallback()
    }

    if let accessToken = configFile.items["access_token"] {
      let newQueryItems = addAccessToken(params: queryItems, accessToken: accessToken)

      var headers: Set<HttpHeader> = []
      headers.insert(HttpHeader(field: "User-agent", value: UserAgent))

      let response = try request(path, method: method, queryItems: newQueryItems, headers: headers)

      if let response = response, let data = response.data,
         let value = try self.decode(data, to: type) {
        result = (value: value, response: response)

        if let result2 = result, let response = result2.response.response {
          let statusCode = response.statusCode

          if (statusCode == 401 || statusCode == 400) && !unauthorized {
            let refreshToken = self.configFile.items["refresh_token"]

            if let refreshToken = refreshToken {
              if let fullValue = try self.updateToken(refreshToken) {
                self.configFile.items = fullValue.asMap()
                try self.saveConfig()

                result = try self.fullRequest(path: path, to: type, method: method, queryItems: queryItems, unauthorized: true)
              }
            }
          }
        }
      }
    }

    return result
  }
}
