import XCTest

@testable import MediaApis

class KinoGoAPITests: XCTestCase {
  var subject = KinoGoAPI()

  func testGetAvailable() throws {
    let result = try subject.available()

    XCTAssertEqual(result, true)
  }

  func testGetCookie() throws {
    if let result = try subject.getCookie(url: KinoGoAPI.SiteUrl +  "/11361-venom_2018_08-10.html") {
      print(result)

      XCTAssertNotNil(result)
    } else {
      XCTFail("Empty result")
    }
  }

  func testGetAllCategories() throws {
    let list = try subject.getAllCategories()

//    print(list["Категории"]!)
//    print(list["По году"]!)
//    print(list["По странам"]!)
//    print(list["Сериалы"]!)

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.count > 0)
  }

  func testGetCategoriesByGroup() throws {
    print(try subject.getCategoriesByTheme())
//    print(try subject.getCategoriesByYear())
//    print(try subject.getCategoriesByCountry())
//    print(try subject.getCategoriesBySerie())

//    XCTAssertNotNil(list)
//    XCTAssert(list.count > 0)
  }

  func testGetAllMovies() throws {
    let list = try subject.getAllMovies()

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.items.count > 0)
  }

  func testGetPremierMovies() throws {
    let list = try subject.getPremierMovies()

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.items.count > 0)
  }

  func testGetLastMovies() throws {
    let list = try subject.getLastMovies()

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.items.count > 0)
  }

  func testGetAllSeries() throws {
    let list = try subject.getAllSeries()

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.items.count > 0)
  }

//  func testGetAnimations() throws {
//    let list = try subject.getAnimations()
//
//    print(try list.prettify())
//
//    XCTAssertNotNil(list)
//    XCTAssert(list.items.count > 0)
//  }

  func testGetAnime() throws {
    let list = try subject.getAnime()

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.items.count > 0)
  }

  func testGetTvShows() throws {
    let list = try subject.getTvShows()

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.items.count > 0)
  }

//  func testGetMoviesByCountry() throws {
//    //print("Франция".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!)
//    let list = try subject.getMoviesByCountry(country: "/tags/Франция/")
//    //https://kinogo.by/tags/%D0%A4%D1%80%D0%B0%D0%BD%D1%86%D0%B8%D1%8F/
//
//    print(try list.prettify())
//
//    XCTAssertNotNil(list)
//    XCTAssert(list.items.count > 0)
//  }

//  func testGetMoviesByYear() throws {
//    let list = try subject.getMoviesByYear(year: 2008)
//
//    print(try list.prettify())
//
//    XCTAssertNotNil(list)
//    XCTAssert(list.items.count > 0)
//  }

  func testGetUrls() throws {
    let url = "\(KinoGoAPI.SiteUrl)/drama/8701-klarissa-2021-smotret-onlajn-besplatno.html"

    let list = try subject.getUrls(url)

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.count > 0)
  }

//  func testGetSeriePlaylistUrl() throws {
//    let path = "/8892-legion-2-sezon-2018-11.html"
//
//    let list = try subject.getSeasonPlaylistUrl(path)
//
//    // print(list)
//
//    XCTAssertNotNil(list)
//    XCTAssert(list.count > 0)
//  }

  func testSearch() throws {
//    #if swift(>=5.0)
//    print("Hello, Swift 5.0")
//
//    #elseif swift(>=4.2)
//    print("Hello, Swift 4.2")
//
//    #elseif swift(>=4.1)
//    print("Hello, Swift 4.1")
//
//    #elseif swift(>=4.0)
//    print("Hello, Swift 4.0")
//    #else
//    print("unknown")
//    #endif

    let query = "гейман"

    let list = try subject.search(query)

    print(try list.prettify())

    XCTAssertNotNil(list)
    XCTAssert(list.items.count > 0)
  }

  func testPaginationInAllMovies() throws {
    let result1 = try subject.getAllMovies(page: 1)

    let pagination1 = result1.pagination

    XCTAssertTrue(pagination1!.has_next)
    XCTAssertFalse(pagination1!.has_previous)
    XCTAssertEqual(pagination1!.page, 1)

    let result2 = try subject.getAllMovies(page: 2)

    let pagination2 = result2.pagination

    XCTAssertTrue(pagination2!.has_next)
    XCTAssertTrue(pagination2!.has_previous)
    XCTAssertEqual(pagination2!.page, 2)
  }

  func testGetSeasons() throws {
    let url = "\(KinoGoAPI.SiteUrl)/22643-papik-1-sezon.html"
    //let path = "/5139-into-the-badlands_3-sezon_17-08.html"

    let list = try subject.getSeasons(url, "some name")

    print(try list.prettify())

//    print(list.first!.playlist.first!.comment)
//    print(list.first!.playlist.first!.name)

    XCTAssertNotNil(list)
    XCTAssert(list.count > 0)
  }
}
