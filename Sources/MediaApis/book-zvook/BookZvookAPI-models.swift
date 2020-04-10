import Foundation
import SimpleHttpClient

extension BookZvookAPI {
  public typealias BookItem = [String: String]

  public struct Pagination: Codable {
    let page: Int
    let pages: Int
    let has_previous: Bool
    let has_next: Bool

    init(page: Int = 1, pages: Int = 1, has_previous: Bool = false, has_next: Bool = false) {
      self.page = page
      self.pages = pages
      self.has_previous = has_previous
      self.has_next = has_next
    }
  }

  public struct BookResults: Codable {
    public let items: [BookItem]
    let pagination: Pagination?

    init(items: [BookItem] = [], pagination: Pagination? = nil) {
      self.items = items

      self.pagination = pagination
    }
  }

  public struct PersonName {
    public let name: String
    public let id: String

    public init(name: String, id: String) {
      self.name = name
      self.id = id
    }
  }

  public struct BooSource: Codable {
    public let file: String
    public let type: String
    public let height: String
    public let width: String
  }

  public struct BooTrack: Codable {
    public let title: String
    public let orig: String = ""
    public let image: String?
    //public let duration: String
    public let sources: [BooSource]?
    public let mp3: String?

    enum CodingKeys: String, CodingKey {
      case title
      case orig
      case image
      //case duration
      case sources
      case mp3
    }

    public var url: String {
      get {
        if let mp3 = mp3 {
          return mp3
        }
        else if let sources = sources {
          return "\(AudioBooAPI.ArchiveUrl)\(sources[0].file)"
        }
        else {
          return ""
        }
      }
    }

//  public var thumb: String {
//    get {
//      return "\(AudioBooAPI.SiteUrl)\(image)"
//    }
//  }
  }

//  public struct BooTrack2: Codable {
//    public let title: String
//    public let mp3: String
//
//    enum CodingKeys: String, CodingKey {
//      case title
//      case mp3
//    }
//
//    public var url: String {
//      get {
//        mp3
//      }
//    }
//  }

  public struct Book: Codable {
    public let title: String
    public let id: String
  }

  public struct Author: Codable {
    public let name: String
    public var books: [Book]
  }
}
