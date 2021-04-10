@testable import ProtonMail
import XCTest

class PMNIBirthday_FormattedBirthdayTests: XCTestCase {

    override func setUp() {
        super.setUp()

        Environment.locale = .enUS
    }

    override func tearDown() {
        super.tearDown()

        Environment.locale = .current
    }

    func testFormattedBirthday() {
        XCTAssertEqual(BirthdayStub().formattedBirthday, "Feb 2, 2021")
    }

}

private class BirthdayStub: PMNIBirthday {

    var _getText: String = "20210201T23:00:00.000Z"

    // MARK: - PMNIBirthday

    override func getText() -> String {
        _getText
    }

}
