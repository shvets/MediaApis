import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    [
        testCase(MediaApisTests.allTests),
    ]
}
#endif
