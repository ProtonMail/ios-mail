@testable import ProtonMail
import XCTest

class DateFormatter_ContactBirthdayFormatterTests: XCTestCase {

    var sut: DateFormatter!

    override func setUp() {
        super.setUp()

        sut = .contactBirthdayFormatter

        sut.locale = Locale(identifier: "en_US")
        sut.timeZone = TimeZone(secondsFromGMT: 0)
    }

    override func tearDown() {
        super.tearDown()

        sut = nil
    }

    func testContactBirthdayFormatter() {
        let date = Date.fixture("2021-02-01 23:00:00")
        XCTAssertEqual(sut.string(from: date), "Feb 1, 2021")
    }

}
