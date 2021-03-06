import Foundation
import Files

import SimpleHttpClient
import MediaApis

//protocol AudioClient {
//  func getAudioTracks(_ path: String) throws -> [Track]
//}
//
//extension AudioKnigiAPI: AudioClient {
//  func getAudioTracks(_ path: String) throws -> [Track] {
//  }
//}
//
//extension AudioBooAPI: AudioClient {
//  func getAudioTracks(_ path: String) throws -> [Track] {
//  }
//}
//
//extension BookZvookAPI: AudioClient {
//  func getAudioTracks(_ path: String) throws -> [Track] {
//  }
//}

open class MyDownloadManager: DownloadManager {
  public enum ClientType {
    case audioKnigi
    case audioBoo
    case bookZvook
  }

  public func download(clientType: ClientType, url: String) throws {
    let path = URL(string: url)!.lastPathComponent

    switch clientType {
      case .audioKnigi:
        let client = AudioKnigiAPI()

        let audioTracks = try client.getAudioTracks(url)

        var currentAlbum = ""

        for track in audioTracks {
          print(track)

          if let albumName = track.albumName, !albumName.isEmpty {
            currentAlbum = albumName
          }

          let toDir = path + currentAlbum

          if let url = track.url,
            let path = url.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) {

            let to = self.getDestinationFile(dir: toDir, name: "\(track.title).mp3")

            if File.exists(atPath: to.path) {
              print("\(to.path) --- exist")
            }
            else {
              downloadFile(from: path, to: to)
            }
          }
        }

    case .audioBoo:
      let client = AudioBooAPI()

      let playlistUrls = try client.getPlaylistUrls(url)

      if playlistUrls.count > 0 {
        let playlistUrl = playlistUrls[0]

        let bookFolder = String(path[...path.index(path.endIndex, offsetBy: -".html".count-1)])

        let audioTracks = try client.getAudioTracks(playlistUrl)

        for track in audioTracks {
          print(track)

          let path = "\(AudioBooAPI.ArchiveUrl)\(track.sources[0].file)"

          let to = self.getDestinationFile(dir: bookFolder, name: track.orig)

          if File.exists(atPath: to.path) {
            print("\(to.path) --- exist")
          }
          else {
            downloadFile(from: path, to: to)
          }
        }
      }
      else {
        print("Cannot find playlist.")
      }

      case .bookZvook:
        let client = BookZvookAPI()

        let playlistUrls = try client.getPlaylistUrls(url)

        if playlistUrls.count > 0 {
          let playlistUrl = playlistUrls[0]

          let bookFolder = String(path[...path.index(path.endIndex, offsetBy: -".html".count-1)])

          let audioTracks = try client.getAudioTracks(playlistUrl)

          for track in audioTracks {
            print(track)

            let path = track.url //"\(AudioBooAPI.ArchiveUrl)\(track.sources[0].file)"

            let to = self.getDestinationFile(dir: bookFolder, name: track.orig)

            if File.exists(atPath: to.path) {
              print("\(to.path) --- exist")
            }
            else {
              downloadFile(from: path, to: to)
            }
          }
        }
        else {
          print("Cannot find playlist.")
        }
    }
  }

  func getDestinationFile(dir: String, name: String) -> URL {
    let downloadsDirectory = self.fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]

    let destinationDir = downloadsDirectory.appendingPathComponent(dir)

    return destinationDir.appendingPathComponent(name)
  }

  open func downloadFile(from: String, to: URL) {
    do {
      if let fromUrl = URL(string: from) {
        try downloadFrom(fromUrl, toUrl: to)
      }
    }
    catch DownloadError.downloadFailed(let message) {
      print("\(message)")
    }
    catch {
      print("Error: \(error.localizedDescription)")
    }
  }
}
