import Foundation
import SwiftSoup
import SimpleHttpClient

open class AudioBooAPI {
  public static let SiteUrl = "https://audioboo.ru"
  public static let ArchiveUrl = "https://archive.org"

  let apiClient = ApiClient(URL(string: SiteUrl)!)
  let archiveClient = ApiClient(URL(string: ArchiveUrl)!)

  public init() {}

  public static func getURLPathOnly(_ url: String, baseUrl: String) -> String {
    String(url[baseUrl.index(url.startIndex, offsetBy: baseUrl.count)...])
  }

  func getPagePath(path: String, page: Int=1) -> String {
    if page == 1 {
      return path
    }
    else {
      return "\(path)page/\(page)/"
    }
  }

  public func getLetters() throws -> [[String: String]] {
    var result = [[String: String]]()

    if let document = try getDocument() {
      let items = try document.select("div[class=content] div div a[class=alfavit]")

      for item in items.array() {
        let name = try item.text()

        let href = try item.attr("href")

        result.append(["id": href, "name": name.uppercased()])
      }
    }

    return result
  }

  public func getAuthorsByLetter(_ path: String) throws -> [NameClassifier.ItemsGroup] {
    var groups: [String: [NameClassifier.Item]] = [:]

    if let document = try getDocument(path) {
      let items = try document.select("div[class=news-item-content] div a")

      for item in items.array() {
        let href = try item.attr("href")
        let name = try item.text().trim()

        if !name.isEmpty && !name.hasPrefix("ALIAS") && Int(name) == nil {
          let index1 = name.startIndex
          let index2 = name.index(name.startIndex, offsetBy: 3)

          let groupName = name[index1 ..< index2].uppercased()

          if !groups.keys.contains(groupName) {
            groups[groupName] = []
          }

          var group: [NameClassifier.Item] = []

          if let subGroup = groups[groupName] {
            for item in subGroup {
              group.append(item)
            }
          }

          group.append(NameClassifier.Item(id: href, name: name))

          groups[groupName] = group
        }
      }
    }

    var newGroups: [NameClassifier.ItemsGroup] = []

    for (groupName, group) in groups.sorted(by: { $0.key < $1.key}) {
      newGroups.append(NameClassifier.ItemsGroup(key: groupName, value: group))
    }

    return NameClassifier().mergeSmallGroups(newGroups)
  }

  public func getPerformersLetters() throws -> [[String: String]] {
    var letters: [[String: String]] = []

    if let document = try getDocument("tags/") {
      let items = try document.select("div[class=content] div[id=dle-content] h3")

      for item in items.array() {
        let name = try item.text().uppercased()

        if !name.isEmpty && Int(name) == nil {
          letters.append(["name": name, "id": name])
        }
      }
    }

    return letters
  }

  public func getPerformers() throws -> [NameClassifier.ItemsGroup] {
    var groups: [String: [NameClassifier.Item]] = [:]

    if let document = try getDocument("tags/") {
      let items = try document.select("div[class=content] div[id=dle-content] a")

      for item in items.array() {
        let href = try item.attr("href")

        let name = try item.text()

        let index1 = name.startIndex
        let index2 = name.count > 2 ? name.index(name.startIndex, offsetBy: 3) :
          name.index(name.startIndex, offsetBy: 2)

        let groupName = name[index1 ..< index2].uppercased()

        if !groups.keys.contains(groupName) {
          groups[groupName] = []
        }

        var group: [NameClassifier.Item] = []

        if let subGroup = groups[groupName] {
          for item in subGroup {
            group.append(item)
          }
        }

        group.append(NameClassifier.Item(id: href, name: name))

        groups[groupName] = group
      }
    }

    var newGroups: [NameClassifier.ItemsGroup] = []

    for (groupName, group) in groups.sorted(by: { $0.key < $1.key}) {
      newGroups.append(NameClassifier.ItemsGroup(key: groupName, value: group))
    }

    return NameClassifier().mergeSmallGroups(newGroups)
  }

  public func getAllBooks(page: Int=1) throws -> [BookItem] {
    var result = [BookItem]()

    let path = getPagePath(path: "", page: page)

    if let document = try getDocument(path) {
      let items = try document.select("div[id=dle-content] div[class=biography-main]")

      for item: Element in items.array() {
        let name = try item.select("div[class=biography-title] h2 a").text()
        let href = try item.select("div div[class=biography-image] a").attr("href")
        var thumb = try item.select("div div[class=biography-image] a img").attr("src")

        let index = thumb.find("https://")

        if index != thumb.startIndex {
          thumb = AudioBooAPI.SiteUrl + thumb
        }

        result.append(["type": "book", "id": href, "name": name, "thumb": thumb])
      }
    }

    return result
  }

  public func getBooks(_ url: String, page: Int=1) throws -> [BookItem] {
    var result = [BookItem]()

    let pagePath = getPagePath(path: "", page: page)

   let newUrl = AudioBooAPI.SiteUrl + "/" + url
    let path = AudioBooAPI.getURLPathOnly("\(newUrl)\(pagePath)", baseUrl: AudioBooAPI.SiteUrl)
    
    if let document = try getDocument(path) {
      let items = try document.select("div[class=biography-main]")

      for item: Element in items.array() {
        let name = try item.select("div[class=biography-title] h2 a").text()
        let href = try item.select("div div[class=biography-image] a").attr("href")
        let thumb = try item.select("div div[class=biography-image] a img").attr("src")

        let content = try item.select("div[class=biography-content]").text()

        let elements = try item.select("div[class=biography-content] div").array()

        let rating = try elements[0].select("div[class=rating] ul li[class=current-rating]").text()

        result.append(["type": "book", "id": href, "name": name, "thumb": AudioBooAPI.SiteUrl + thumb, 
                       "content": content, "rating": rating])
      }
    }

    return result
  }

  public func getPlaylistUrls(_ url: String) throws -> [String] {
    var result = [String]()

    let path = AudioBooAPI.getURLPathOnly(url, baseUrl: AudioBooAPI.SiteUrl)

    if let document = try getDocument(path) {
      let items = try document.select("object")

      if items.count > 0 {
        for item: Element in items.array() {
          result.append(try item.attr("data"))
        }
      }
//      else {
//        let script = try document.select("script")
//
//        if script.count > 0 {
//          let content = try script[0].text()
//          
//          let index1 = content.find("file:")
//          let index2 = content.find("});")
//          
//          if let index1 = index1, let index2 = index2 {
//            let text = content.substring(from: index1, to: index2)
//          }
//
////          for item2: Element in playerLinks.array() {
////            //result.append(try item.attr("data"))
////            print(item2)
////          }
//        }
//      }
    }

    return result
  }

  public func getAudioTracks(_ url: String) throws -> [BooTrack] {
    var result = [BooTrack]()

    let path = AudioBooAPI.getURLPathOnly(url, baseUrl: AudioBooAPI.ArchiveUrl)

    if let response = try archiveClient.request(path), let data = response.data,
       let document = try toDocument(data: data, encoding: .utf8) {

      let items = try document.select("input[class=js-play8-playlist]")

      for item in items.array() {
        let value = try item.attr("value")

        if let data = value.data(using: .utf8),
           let tracks = try archiveClient.decode(data, to: [BooTrack].self) {
          result = tracks
        }
      }
    }

    return result
  }

  public func getAudioTracksNew(_ url: String) throws -> [BooTrack2] {
    var result = [BooTrack2]()

    let path = AudioBooAPI.getURLPathOnly(url, baseUrl: AudioBooAPI.ArchiveUrl)

    if let document = try getDocument(path) {
      let scripts = try document.select("script")

      for script in scripts {
        let text = try script.html()

        if !text.trim().isEmpty {
          let index1 = text.find("file:")
          let index2 = text.find("}]")

          if let index1 = index1, let index2 = index2 {
            let index3 = text.index(index1, offsetBy: 5)
            let index4 = text.index(index2, offsetBy: 1)

            let body = String(text[index3 ... index4])
            //.replacingOccurrences(of: " ", with: "")
            //.replacingOccurrences(of: "\n", with: "")a


            if let data = body.data(using: .utf8),
               let items = try apiClient.decode(data, to: [BooTrack2].self) {
              result = items
            }
          }
        }
      }
    }

    return result
  }

  public func search(_ query: String, page: Int=1) throws -> [[String: String]] {
    var result = [[String: String]]()

    let path = "engine/ajax/controller.php"

    let content = "query=\(query)" +
            "&user_hash=e49f7fb6c307f5918acf0a8ff5ad4f209e01e36a"
    let body = content.data(using: .utf8, allowLossyConversion: false)

    var headers: Set<HttpHeader> = []
    headers.insert(HttpHeader(field: "content-type", value: "application/x-www-form-urlencoded; charset=UTF-8"))

    var queryItems: Set<URLQueryItem> = []
    queryItems.insert(URLQueryItem(name: "mod", value: "search"))

    if let response = try apiClient.request(path, method: .post, queryItems: queryItems,
            headers: headers, body: body),
       let data = response.data,
       let document = try toDocument(data: data) {
      let items = try document.select("a")

      for item in items.array() {
        let name = try item.text()

        let href = try item.attr("href")

        result.append(["type": "book", "id": href, "name": name])
      }
    }

    return result
  }

  public func getDocument(_ path: String = "") throws -> Document? {
    var document: Document? = nil

    if let response = try apiClient.request(path), let data = response.data {
      document = try data.toDocument(encoding: .utf8)
    }

    return document
  }

  func toDocument(data: Data, encoding: String.Encoding = .utf8) throws -> Document? {
    try data.toDocument(encoding: encoding)
  }
}
