import Foundation
import SwiftSoup
import SimpleHttpClient

open class KinoKongAPI {
  public static let SiteUrl = "https://kinokong.org"

  let UserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36"

  let apiClient = ApiClient(URL(string: SiteUrl)!)

  public init() {}
  
  public static func getURLPathOnly(_ url: String, baseUrl: String) -> String {
    String(url[baseUrl.index(url.startIndex, offsetBy: baseUrl.count)...])
  }

  func getHeaders(_ referer: String="") -> Set<HttpHeader> {
    var headers: Set<HttpHeader> = []
    headers.insert(HttpHeader(field: "User-Agent", value: UserAgent))
    headers.insert(HttpHeader(field: "Host", value: KinoKongAPI.SiteUrl.replacingOccurrences(of: "https://", with: "")))
    headers.insert(HttpHeader(field: "Upgrade-Insecure-Requests", value: "1"))

    if !referer.isEmpty {
      headers.insert(HttpHeader(field: "Referer", value: referer))
    }
    else {
      headers.insert(HttpHeader(field: "Referer", value: KinoKongAPI.SiteUrl))
    }

    return headers
  }

  public func getDocument(_ path: String = "", queryItems: Set<URLQueryItem> = []) throws -> Document? {
    var document: Document? = nil

    if let response = try apiClient.request(path, queryItems: queryItems),
       let data = response.data {
      document = try data.toDocument(encoding: .windowsCP1251)
    }

    return document
  }

  func getPagePath(_ path: String, page: Int=1) -> String {
    if page == 1 {
      return path
    }
    else {
      return "\(path)page/\(page)/"
    }
  }

  public func available() throws -> Bool {
    if let document = try getDocument() {
      return try document.select("div[id=container]").size() > 0
    }
    else {
      return false
    }
  }

  public func getAllMovies(page: Int=1) throws -> BookResults {
    try getMovies("/filmes/", page: page)
  }

  public func getNewMovies(page: Int=1) throws -> BookResults {
    try getMovies("/filmes/novinki-2020-godes/", page: page)
  }

  public func getAllSeries(page: Int=1) throws -> BookResults {
    try getMovies("/seriez/", page: page)
  }

  public func getAnimations(page: Int=1) throws -> BookResults {
    try getMovies("/cartoons/", page: page)
  }

  public func getAnime(page: Int=1) throws -> BookResults {
    try getMovies("/animes/", page: page)
  }

  public func getTvShows(page: Int=1) throws -> BookResults {
    try getMovies("/doc/", page: page)
  }

  public func getMovies(_ path: String, page: Int=1) throws -> BookResults {
    var collection = [BookItem]()
    var pagination = Pagination()

    let pagePath = getPagePath(path, page: page)

    if let document = try getDocument(pagePath) {
      let items = try document.select("div[class=owl-item]")

      for item: Element in items.array() {
        var href = try item.select("div[class=item] span[class=main-sliders-bg] a").attr("href")
        let name = try item.select("h2[class=main-sliders-title] a").text()
        let last = try item.select("div[class=main-sliders-img] img").array().last!
        let thumb = try last.attr("src")
        
        let seasonNode = try item.select("div[class=main-sliders-shadow] div[class=main-sliders-season]").text()

        if href.find(KinoKongAPI.SiteUrl) != nil {
          let index = href.index(href.startIndex, offsetBy: KinoKongAPI.SiteUrl.count)

          href = String(href[index ..< href.endIndex])
        }

        let type = seasonNode.isEmpty ? "movie" : "serie"

        collection.append(["id": href, "name": name, "thumb": thumb, "type": type])
      }

      if items.size() > 0 {
        pagination = try extractPaginationData(document, page: page)
      }
    }

    return BookResults(items: collection, pagination: pagination)
  }

  func getMoviesByRating(page: Int=1) throws -> BookResults {
    try getMoviesByCriteriaPaginated("rating", page: page)
  }

  func getMoviesByViews(page: Int=1) throws -> BookResults {
    try getMoviesByCriteriaPaginated("views", page: page)
  }

  func getMoviesByComments(page: Int=1) throws -> BookResults {
    try getMoviesByCriteriaPaginated("comments", page: page)
  }

  public func getMoviesByCriteriaPaginated(_ mode: String, page: Int=1, perPage: Int=25) throws -> BookResults {
    var queryItems: Set<URLQueryItem> = []
    queryItems.insert(URLQueryItem(name: "do", value: "top"))
    queryItems.insert(URLQueryItem(name: "mode", value: mode))

    let collection = try getMoviesByCriteria(queryItems: queryItems)

    var items: [Any] = []

    for (index, item) in collection.enumerated() {
      if index >= (page-1)*perPage && index < page*perPage {
        items.append(item)
      }
    }

    let pagination = buildPaginationData(collection, page: page, perPage: perPage)

    return BookResults(items: collection, pagination: pagination)
  }

  func getMoviesByCriteria(queryItems: Set<URLQueryItem>) throws ->  [BookItem] {
    var data =  [BookItem]()

    if let document = try getDocument(queryItems: queryItems) {
      let items = try document.select("div[id=dle-content] div div table tr")

      for item: Element in items.array() {
        let link = try item.select("td a")

        if !link.array().isEmpty {
          var href = try link.attr("href")

          let index = href.index(href.startIndex, offsetBy: KinoKongAPI.SiteUrl.count)

          href = String(href[index ..< href.endIndex])

          let name = try link.text().trim()

          let tds = try item.select("td").array()

          let rating = try tds[tds.count-1].text()

          data.append(["id": href, "name": name, "rating": rating, "type": "rating"])
        }
      }
    }

    return data
  }

  public func getTags() throws -> [BookItem] {
    var data = [BookItem]()

    if let document = try getDocument("kino-podborka.html") {
      let items = try document.select("div[class=podborki-item-block]")

      for item: Element in items.array() {
        let link = try item.select("a")
        let img = try item.select("a span img")
        let title = try item.select("a span[class=podborki-title]")
        let href = try link.attr("href")

        var thumb = try img.attr("src")

        if thumb.find(KinoKongAPI.SiteUrl) == nil {
          thumb = KinoKongAPI.SiteUrl + thumb
        }

        let name = try title.text()

        data.append(["id": href, "name": name, "thumb": thumb, "type": "movie"])
      }
    }

    return data
  }

  func buildPaginationData(_ data: [BookItem], page: Int, perPage: Int) ->Pagination {
    let pages = data.count / perPage

    return Pagination(page: page, pages: pages, has_previous: page > 1, has_next: page < pages)
  }

  func getSeries(_ path: String, page: Int=1) throws -> BookResults {
    try getMovies(path, page: page)
  }

  public func getUrls(_ path: String) throws -> [String] {
    var urls: [String] = []

    var newPath: String? = nil

    if let document = try getDocument(path) {
      let items = try document.select("iframe")

      for item: Element in items.array() {
        let text = try item.attr("src")

        if !text.isEmpty, text.find("/iframe") != nil {
          let index1 = text.find(".pw/")

          if let index1 = index1 {
            let index2 = text.index(index1, offsetBy: 3)

            newPath = String(text[index2 ..< text.endIndex])
          }
        }
      }
    }

    if let newPath = newPath {
      let apiClient = ApiClient(URL(string: "https://vid1603659014294.vb17120ayeshajenkins.pw")!)

      var headers: Set<HttpHeader> = []
      headers.insert(HttpHeader(field: "referer", value: " https://kinokong.org/"))

      if let response = try apiClient.request(newPath, headers: headers), let data = response.data {
        let document = try data.toDocument(encoding: .windowsCP1251)

        if let document = document {
          let items = try document.select("div")

          for item: Element in items.array() {
            let id = try item.attr("id")

            if id == "nativeplayer" {
              let dataConfig = try item.attr("data-config")

              if dataConfig == dataConfig {
                // "{\"ads\":{\"ads\":{\"midroll\":[{\"time\":\"firstQuartile\",\"url\":\"https:\\/\\/aj1907.online\\/zD4or91Q1-VnpIM_oLUqwh5HsfEWEAVmZPF8UopM59PCI-CURAzt7r12Bibpz8aGcs7uefk8p9a4pdXuaKaJo5P7E6e2uuUE#mid35-19\"},{\"time\":\"1\",\"url\":\"https:\\/\\/aj1907.online\\/zD4or91Q1-VnpIM_oLUqwh5HsfEWEAVmZPF8UopM59PCI-CURAzt7r12Bibpz8aGcs7uefk8p9a4pdXuaKaJo5P7E6e2uuUE#mid35-19\"}],\"preroll\":\"https:\\/\\/aj1907.online\\/z4IiVVrfmpT0vTF2FxwSDJi4aFnFAGgnvLeQS6GCqxsd7lJM55zsf-OBwCnE35pjPGM_o-1UDvYQYZ4thZNB7L_EUhb0uZ2o#pre35-20\"}},\"poster\":\"\",\"type\":\"movie\",\"subtitle\":[],\"volume_control_mouse\":0,\"href\":null,\"token\":\"4dcfffbeaaa7e83966d4403138d34803\",\"hls\":\"\\/\\/cdn-400.vb17120ayeshajenkins.pw\\/stream2\\/cdn-400\\/fb144bf917094bac73c6be2f5c6eb536\\/MJTMsp1RshGTygnMNRUR2N2MSlnWXZEdMNDZzQWe5MDZzMmdZJTO1R2RWVHZDljekhkSsl1VwYnWtx2cihVT25UbFhXW6JlaNpXQ41kenhnWER2aOp2ZyoFRVlXTHVlMPRFZqplaZRjTtVUP:1603667407:73.194.0.48:a459fb4399846955957655adc140c08498b2bb098fcbb98da56d9cb635869346\\/index.m3u8\",\"end_tag_banner_show_time\":60,\"end_tag_banner_skip_time\":15,\"endTag\":\"528"...

                let index1 = dataConfig.find("\"hls\":\"")
                let index2 = dataConfig.find(".m3u8\"")

                if let index1 = index1, let index2 = index2 {
                  let index3 = dataConfig.index(index1, offsetBy: 7)

                  let url = (dataConfig[index3 ..< index2] + ".m3u8")
                      .replacingOccurrences(of: "\\/", with: "/")
                      .replacingOccurrences(of: "//", with: "http://")

                  urls.append(url)
                }
              }
            }
          }
        }
      }
    }

//      let items = try document.select("script")
//
//      for item: Element in items.array() {
//        let text0 = try item.html()
//        let text = text0.replacingOccurrences(of: ",file:", with: ", file:")
//
//        if !text.isEmpty {
//          let index1 = text.find("\", file:\"")
//          let index2 = text.find("\"});")
//
//          if let startIndex = index1, let endIndex = index2 {
//            urls = text[text.index(startIndex, offsetBy: 8) ..< endIndex].components(separatedBy: ",")
//
//            break
//          }
//          else {
//            let index1 = text.find("\", file:\"")
//            let index2 = text.find("\",st:")
//
//            if let startIndex = index1, let endIndex = index2 {
//              urls = text[text.index(startIndex, offsetBy: 8) ..< endIndex].components(separatedBy: ",")
//
//              break
//            }
//          }
//        }
//      }
//    }

//    var newUrls: [String] = []
//
//    for url in urls {
//      if !url.hasPrefix("cuid:") {
//        let newUrl = url.replacingOccurrences(of: "\"", with: "")
//            .replacingOccurrences(of: "[720]", with: "")
//            .replacingOccurrences(of: "[480]", with: "")
//
//          newUrls.append(newUrl)
//      }
//    }
//
//    return newUrls.reversed()

    return urls
  }

  public func getSeriePlaylistUrl(_ path: String) throws -> String {
    var url = ""

    if let document = try getDocument(KinoKongAPI.getURLPathOnly(path, baseUrl: KinoKongAPI.SiteUrl)) {
      let items = try document.select("iframe")

      for item: Element in items.array() {
        let text = try item.attr("src")

        if !text.isEmpty  && text.starts(with: "//") {
          url = text.replacingOccurrences(of: "//", with: "http://")
//          print(text)
//          let index1 = text.find("pl:")
//
//          if let startIndex = index1 {
//            let text2 = String(text[startIndex ..< text.endIndex])
//
//            let index2 = text2.find("\",")
//
//            if let endIndex = index2 {
//              url = String(text2[text2.index(text2.startIndex, offsetBy:4) ..< endIndex])
//
//              break
//            }
//          }
        }
      }
    }

    return url
  }

  public func getSeriePosterUrl(_ path: String) throws -> String? {
    var url: String? = nil

    if let document = try getDocument(KinoKongAPI.getURLPathOnly(path, baseUrl: KinoKongAPI.SiteUrl)) {
      let items = try document.select("div[class=full-poster] img")

      if items.array().count > 0 {
        url = try items.array().first!.attr("src")
      }
    }

    return url
  }

  public func getMetadata(_ url: String) -> [String: String] {
    var data = [String: String]()

    let groups = url.components(separatedBy: ".")

    if (groups.count > 1) {
      let text = groups[groups.count-2]

      let pattern = "(\\d+)p_(\\d+)"

      do {
        let regex = try NSRegularExpression(pattern: pattern)

        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))

        if let width = getMatched(text, matches: matches, index: 1) {
          data["width"] = width
        }

        if let height = getMatched(text, matches: matches, index: 2) {
          data["height"] = height
        }
      }
      catch {
        print("Error in regular expression.")
      }

    }

    return data
  }

  func getMatched(_ link: String, matches: [NSTextCheckingResult], index: Int) -> String? {
    var matched: String?

    let match = matches.first

    if let match = match, index < match.numberOfRanges {
      let capturedGroupIndex = match.range(at: index)

      let index1 = link.index(link.startIndex, offsetBy: capturedGroupIndex.location)
      let index2 = link.index(index1, offsetBy: capturedGroupIndex.length-1)

      matched = String(link[index1 ... index2])
    }

    return matched
  }

  public func getGroupedGenres() throws -> [String: [BookItem]] {
    var data = [String: [BookItem]]()

    if let document = try getDocument() {
      let items = try document.select("div[id=header] div div div ul li")

      for item: Element in items.array() {
        let hrefLink = try item.select("a")
        let genresNode1 = try item.select("span em a")
        let genresNode2 = try item.select("span a")

        var href = try hrefLink.attr("href")

        if href == "#" {
          href = "top"
        }
        else {
          href = String(href[href.index(href.startIndex, offsetBy: 1) ..< href.index(href.endIndex, offsetBy: -1)])
        }

        var genresNode: Elements?

        if !genresNode1.array().isEmpty {
          genresNode = genresNode1
        }
        else {
          genresNode = genresNode2
        }

        if let genresNode = genresNode, !genresNode.array().isEmpty {
          data[href] = []

          for genre in genresNode {
            let path = try genre.attr("href")
            let name = try genre.text()

            if !["/kino-recenzii/", "/news-kino/"].contains(path) {
              data[href]!.append(["id": path, "name": name])
            }
          }
        }
      }
    }

    return data
  }

  public func search(_ query: String, page: Int=1, perPage: Int=15) throws -> BookResults {
    var collection = [BookItem]()
    var pagination = Pagination()

    var queryItems: Set<URLQueryItem> = []
    queryItems.insert(URLQueryItem(name: "do", value: "search"))

    let path = "/index.php"

    var content = "subaction=search&" + "search_start=\(page)&" + "full_search=0&" +
      "story=\(query.windowsCyrillicPercentEscapes())"

    if page > 1 {
      content += "&result_from=\(page * perPage + 1)"
    }
    else {
      content += "&result_from=1"
    }

    let body = content.data(using: .utf8, allowLossyConversion: false)

    if let response = try apiClient.request(path, method: .post, queryItems: queryItems,
      headers: getHeaders(), body: body),
       let data = response.data,
       let document = try data.toDocument(encoding: .windowsCP1251) {
      let items = try document.select("div[class=owl-item]")

      for item: Element in items.array() {
        var href = try item.select("div[class=item] span[class=main-sliders-bg] a").attr("href")
        let name = try item.select("div[class=main-sliders-title] a").text()
        let thumb = try item.select("div[class=item] span[class=main-sliders-bg] img").attr("src")
        //try item.select("div[class=main-sliders-shadow] span[class=main-sliders-bg] ~ img").attr("src")

        let seasonNode = try item.select("div[class=main-sliders-shadow] span[class=main-sliders-season]").text()

        if href.find(KinoKongAPI.SiteUrl) != nil {
          let index = href.index(href.startIndex, offsetBy: KinoKongAPI.SiteUrl.count)

          href = String(href[index ..< href.endIndex])
        }

        var type = seasonNode.isEmpty ? "movie" : "serie"

        if name.contains("Сезон") || name.contains("сезон") {
          type = "serie"
        }

        collection.append(["id": href, "name": name, "thumb": thumb, "type": type])
      }

      if items.size() > 0 {
        pagination = try extractPaginationData(document, page: page)
      }
    }

    return BookResults(items: collection, pagination: pagination)
  }

  func extractPaginationData(_ document: Document, page: Int) throws -> Pagination {
    var pages = 1

    let paginationRoot = try document.select("div[class=basenavi] div[class=navigation]")

    if !paginationRoot.array().isEmpty {
      let paginationNode = paginationRoot.get(0)

      let links = try paginationNode.select("a").array()

      if let number = Int(try links[links.count-1].text()) {
        pages = number
      }
    }

    return Pagination(page: page, pages: pages, has_previous: page > 1, has_next: page < pages)
  }

  public func getSeasons(_ playlistUrl: String, path: String = "") throws -> [Season] {
    var list: [Season] = []

    if let url = URL(string: playlistUrl), let scheme = url.scheme, let host = url.host {
      let apiClient = ApiClient(URL(string: "\(scheme)://\(host)")!)

      if let response = try apiClient.request(url.path),
         let data = response.data,
         let document = try data.toDocument(encoding: .windowsCP1251) {
        let items = try document.select("input")

        for item: Element in items.array() {
          let id = try item.attr("id")

          if id == "files" {
            let value = try item.attr("value")

            print(value)

            if let localizedData = value.data(using: .utf16) {
              let jsonResponse = try JSONSerialization.jsonObject(with: localizedData, options: [])

              if let result = jsonResponse as? [String: [[String: Any]]] {
                let singleSeason = result.values.count > 0 && (result.values.first?.first?["file"] != nil)

                //print(singleSeason)

                if singleSeason {
                  var episodes: [Episode] = []

                  for (key, values) in result {
                    if key == "0" {
                      episodes.append(contentsOf: buildEpisodes(values as! [[String: String]]))
                    }
                  }

                  let season = Season(comment: "1 сезон", playlist: episodes)

                  list.append(season)
                }
                else {
                  for (key, values) in result {
                    if key == "0" {
                      var episodes: [Episode] = []

                      for value in values {
                        let comment = value["comment"] as? String ?? ""

                        if let folder = value["folder"] as? [[String: String]] {
                          episodes = buildEpisodes(folder)
                        }

                        let season = Season(comment: comment, playlist: episodes)

                        list.append(season)
                      }
                    }
                  }
                }
              }
            }

            break;
          }
        }
      }
    }

//
//    if let response = try apiClient.request(newPath, headers: getHeaders(KinoKongAPI.SiteUrl + "/" + newPath)),
//       let data = response.data,
//       let content = String(data: data, encoding: .windowsCP1251) {
//
//      if !content.isEmpty {
//        if let index = content.find("{\"playlist\":") {
//          let playlistContent = content[index ..< content.endIndex]
//
//          if let localizedData = playlistContent.data(using: .windowsCP1251) {
//
//            if let result = try? apiClient.decode(localizedData, to: PlayList.self) {
//              for item in result.playlist {
//                list.append(Season(comment: item.comment, playlist: buildEpisodes(item.playlist)))
//              }
//            }
//            else if let result = try apiClient.decode(localizedData, to: SingleSeasonPlayList.self) {
//              list.append(Season(comment: "Сезон 1", playlist: buildEpisodes(result.playlist)))
//            }
//          }
//        }
//      }
//    }

    return list
  }

  func buildEpisodes(_ playlist: [[String: String]]) -> [Episode] {
    var episodes: [Episode] = []

//    for item in playlist {
//      let comment = item["comment"]!
//      let file = item["file"]!
//
//      var episode = Episode(comment: comment, file: file)
//
//      episode.files = episode.urls()
//
//      episodes.append(episode)
//    }

    for value in playlist {
      let comment = value["comment"] ?? ""
      let file = value["file"] ?? ""

      var episode = Episode(comment: comment, file: file)

      episode.files = episode.urls()

      episodes.append(episode)
    }

    return episodes
  }

  func getEpisodeUrl(url: String, season: String, episode: String) -> String {
    var episodeUrl = url

    if !season.isEmpty {
      episodeUrl = "\(url)?season=\(season)&episode=\(episode)"
    }

    return episodeUrl
  }

  func getSoundtrackPlaylistUrl(_ path: String) throws -> String {
    try getSeriePlaylistUrl(path)
  }

  public func getSoundtracks(_ playlistUrl: String, path: String = "") throws -> [Soundtrack] {
    var list: [Soundtrack] = []

    let newPath = KinoKongAPI.getURLPathOnly(playlistUrl, baseUrl: KinoKongAPI.SiteUrl)

    if let response = try apiClient.request(newPath, headers: getHeaders(KinoKongAPI.SiteUrl + "/" + newPath)),
       let data = response.data,
       let content = String(data: data, encoding: .windowsCP1251) {

      if !content.isEmpty {
        if let index = content.find("{\"playlist\":") {
          let playlistContent = content[index ..< content.endIndex]

          if let localizedData = playlistContent.data(using: .windowsCP1251) {
            if let result = try apiClient.decode(localizedData, to: SoundtrackList.self) {
              list = result.playlist
            }
          }
        }
      }
    }

    return list
  }
}
