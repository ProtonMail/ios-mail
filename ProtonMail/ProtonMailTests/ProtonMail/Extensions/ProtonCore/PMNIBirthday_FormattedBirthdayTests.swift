@testable import ProtonMail
import VCard
import XCTest

class PMNIBirthday_FormattedBirthdayTests: XCTestCase {

    override func setUp() {
        super.setUp()

        LocaleEnvironment.locale = { .enUS }
    }

    override func tearDown() {
        super.tearDown()

        LocaleEnvironment.restore()
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
