import Foundation
import SimpleHttpClient
import Codextended

extension EtvnetAPI {
  public enum WatchStatus: Int, RawRepresentable, Codable {
    case new = 0
    case partiallyWatched
    case finished

    public typealias RawValue = Int

    public init?(rawValue: RawValue) {
      switch rawValue {
      case 0: self = .new
      case 1: self = .partiallyWatched
      case 2: self = .finished
      default: self = .new
      }
    }

    public var rawValue: RawValue {
      switch self {
      case .new: return 0
      case .partiallyWatched: return 1
      case .finished: return 2
      }
    }

    public var description: String {
      switch self {
      case .new: return "New"
      case .partiallyWatched: return "Partially Watched"
      case .finished: return "Finished"
      }
    }
  }

  public struct UrlType: Codable {
    public let url: String
  }

  public struct Name: Codable {
    public let id: Int
    public let name: String
  }

  public struct Genre: Codable {
    public let id: Int
    public let name: String
    public let count: Int
  }

  public struct FileType: Codable {
    public let bitrate: Int
    public let format: String

    public init(bitrate: Int, format: String) {
      self.bitrate = bitrate
      self.format = format
    }
  }

  public enum MediaType: String, Codable {
    case container = "Container"
    case mediaObject = "MediaObject"
  }

  public struct MarkType: Codable {
    public let total: Int
    public let count: Int

    public init(total: Int, count: Int) {
      self.total = total
      self.count = count
    }
  }

  public struct Media: Codable {
    public let id: Int
    public let name: String
    public let seriesNum: Int
    public let onAir: String
    public let duration: Int
    public let country: String
    public let childrenCount: Int
    public let isHd: Bool
    public let files: [FileType]
    public let channel: Name
    public let shortName: String
    public let shortNameEng: String
    public let watchStatus: WatchStatus
    public let tag: String
    public let year: Int
    public let mediaType: MediaType
    public let parent: Int
    public let thumb: String
    public let mark: MarkType
    public let rating: Int
    public let description: String

    enum CodingKeys: String, CodingKey {
      case id
      case name
      case seriesNum = "series_num"
      case onAir = "on_air"
      case duration
      case country
      case childrenCount = "children_count"
      case isHd = "is_hd"
      case files
      case channel
      case shortName = "short_name"
      case shortNameEng = "short_name_eng"
      case watchStatus = "watch_status"
      case tag
      case year
      case mediaType = "type"
      case parent
      case thumb
      case mark
      case rating
      case description
    }

    public init(from decoder: Decoder) throws {
      id = try decoder.decode("id")
      name = try decoder.decode("name")
      seriesNum = try decoder.decode("series_num")
      onAir = try decoder.decode("on_air")
      duration = try decoder.decode("duration")
      country = try decoder.decode("country")
      childrenCount = try decoder.decode("children_count")
      isHd = try decoder.decode("is_hd")

      do {
        files = (try decoder.decode("files")) ?? []
      }
      catch {
        files = []
      }

      channel = try decoder.decode("channel")
      shortName = try decoder.decode("short_name")
      shortNameEng = try decoder.decode("short_name_eng")
      watchStatus = try decoder.decode("watch_status")
      tag = try decoder.decode("tag")

      // bug in REST API: sometimes returns empty string
      do {
        year = (try decoder.decode("year")) ?? 0
      }
      catch {
        year = 0
      }

      mediaType = try decoder.decode("type")
      parent = try decoder.decode("parent")
      thumb = try decoder.decode("thumb")
      mark = try decoder.decode("mark")
      rating = try decoder.decode("rating")
      description = try decoder.decode("description")
    }
  }

  public struct Show: Codable {
    public let title: String
    public let startTime: String
    public let finishTime: String

    enum CodingKeys: String, CodingKey {
      case title
      case startTime = "start_time"
      case finishTime = "finish_time"
    }
  }

  public struct LiveChannel: Codable {
    public let id: Int
    public let name: String
    public let allowed: Int
    public let files: [FileType]
    public let icon: URL?

    enum CodingKeys: String, CodingKey {
      case id
      case name
      case allowed
      case files
      case icon
    }

    public init(name: String, id: Int, allowed: Int, files: [FileType], icon: URL?) {
      self.name = name
      self.id = id
      self.allowed = allowed
      self.files = files
      self.icon = icon
    }

    public init(from decoder: Decoder) throws {
      let name: String = try decoder.decode("name")
      let id: Int = try decoder.decode("id")
      let allowed: Int = try decoder.decode("allowed")
      let files: [FileType] = try decoder.decode("files")
      let icon: URL? = try decoder.decodeIfPresent("icon")

      self.init(name: name, id: id, allowed: allowed, files: files, icon: icon)
    }

    public func encode(to encoder: Encoder) throws {
      try encoder.encode(name, for: "name")
      try encoder.encode(id, for: "id")
      try encoder.encode(allowed, for: "allowed")
      try encoder.encode(files, for: "files")
      try encoder.encode(icon, for: "icon")
    }
  }

  public struct LiveSchedule: Codable {
    public let channel: Int
    public let name: String
    public let startTime: String
    public let finishTime: String
    public let description: String
    public let rating: String
    public let week: String?
    public let mediaId: String?
    public let currentShow: Bool

    enum CodingKeys: String, CodingKey {
      case channel
      case name
      case startTime = "start_time"
      case finishTime = "finish_time"
      case description
      case rating
      case week = "efir_week"
      case mediaId = "media_id"
      case currentShow = "current_show"
    }
  }

  public struct Pagination: Codable {
    public let pages: Int
    public let page: Int
    public let perPage: Int
    public let start: Int
    public let end: Int
    public let count: Int
    public let hasNext: Bool
    public let hasPrevious: Bool

    enum CodingKeys: String, CodingKey {
      case pages
      case page
      case perPage = "per_page"
      case start
      case end
      case count
      case hasNext = "has_next"
      case hasPrevious = "has_previous"
    }
  }

  public struct PaginatedMediaData: Codable {
    public let media: [Media]
    public let pagination: Pagination
  }

  public struct PaginatedChildrenData: Codable {
    public let children: [Media]
    public let pagination: Pagination
  }

  public struct PaginatedBookmarksData: Codable {
    public let bookmarks: [Media]
    public let pagination: Pagination
  }

  public enum MediaData: Encodable {
    case paginatedMedia(PaginatedMediaData)
    case paginatedBookmarks(PaginatedBookmarksData)
    case paginatedChildren(PaginatedChildrenData)
    case names([Name])
    case genres([Genre])
    case liveChannels([LiveChannel])
    case liveSchedules([LiveSchedule])
    case url(UrlType)
    case none

    public func encode(to encoder: Encoder) throws {}
  }

  public struct MediaResponse: Codable {
    public let errorCode: String
    public let errorMessage: String
    public let statusCode: Int
    public let data: MediaData

    enum CodingKeys: String, CodingKey {
      case errorCode = "error_code"
      case errorMessage = "error_message"
      case statusCode = "status_code"
      case data
    }

    public init(errorCode: String, errorMessage: String, statusCode: Int, data: MediaData) {
      self.errorCode = errorCode
      self.errorMessage = errorMessage
      self.statusCode = statusCode
      self.data = data
    }

    public init(from decoder: Decoder) throws {
      let errorCode = (try decoder.decode("error_code")) ?? ""
      let errorMessage = (try decoder.decode("error_message")) ?? ""
      let statusCode = (try decoder.decode("status_code")) ?? 0

      let paginatedMedia: PaginatedMediaData? = try? decoder.decodeIfPresent("data")
      let paginatedChildren: PaginatedChildrenData? = try? decoder.decodeIfPresent("data")
      let paginatedBookmarks: PaginatedBookmarksData? = try? decoder.decodeIfPresent("data")
      let genres: [Genre]? = try? decoder.decodeIfPresent("data")
      let names: [Name]? = try? decoder.decodeIfPresent("data")
      let liveChannels: [LiveChannel]? = try? decoder.decodeIfPresent("data")
      let liveSchedules: [LiveSchedule]? = try? decoder.decodeIfPresent("data")
      let url: UrlType? = try? decoder.decodeIfPresent("data")

      var data: MediaData?

      if let value = paginatedMedia {
        data = MediaData.paginatedMedia(value)
      }
      else if let value = paginatedChildren {
        data = MediaData.paginatedChildren(value)
      }
      else if let value = paginatedBookmarks {
        data = MediaData.paginatedBookmarks(value)
      }
      else if let value = genres {
        data = MediaData.genres(value)
      }
      else if let value = liveChannels {
        data = MediaData.liveChannels(value)
      }
      else if let value = liveSchedules {
        data = MediaData.liveSchedules(value)
      }
      else if let value = names {
        data = MediaData.names(value)
      }
      else if let value = url {
        data = MediaData.url(value)
      }
      else {
        data = MediaData.none
      }

      self.init(errorCode: errorCode, errorMessage: errorMessage, statusCode: statusCode, data: data!)
    }

    public func encode(to encoder: Encoder) throws {
      try encoder.encode(errorCode, for: "error_code")
      try encoder.encode(errorMessage, for: "error_message")
      try encoder.encode(statusCode, for: "status_code")
      try encoder.encode(data, for: "data")
    }
  }

  public struct BookmarkResponse: Codable {
    public let status: String
  }

}
