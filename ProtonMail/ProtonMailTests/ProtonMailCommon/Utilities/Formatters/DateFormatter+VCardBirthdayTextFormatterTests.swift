@testable import ProtonMail
import XCTest

class DateFormatter_VCardBirthdayTextFormatterTests: XCTestCase {

    var sut: DateFormatter!

    override func setUp() {
        super.setUp()

        sut = .vCardBirthdayTextFormatter
        sut.locale = Locale(identifier: "en_US")
        sut.timeZone = TimeZone(secondsFromGMT: 0)
    }

    override func tearDown() {
        super.tearDown()

        sut = nil
    }

    func testVCardBirthdayTextFormatter() {
        let vCardBirthdayText = "20210201T23:00:00.000Z"
        let date = sut.date(from: vCardBirthdayText) ?? Date()

        XCTAssertEqual(date, Date.fixture("2021-02-01 23:00:00"))
    }

}
