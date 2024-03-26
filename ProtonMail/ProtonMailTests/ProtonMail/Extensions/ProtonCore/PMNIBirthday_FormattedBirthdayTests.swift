@testable import ProtonMail
import VCard
import XCTest

class PMNIBirthday_FormattedBirthdayTests: XCTestCase {

    func testFormattedBirthday() {
        XCTAssertEqual(BirthdayStub().formattedBirthday, "Feb 2, 2021")
    }

    func testFormattedBirthdayFromDate() {
        let stub = BirthdayStub()
        stub._getDate = "20220310"
        XCTAssertEqual(stub.formattedBirthday, "20220310")
    }
}

private class BirthdayStub: PMNIBirthday {

    var _getText: String = "20210201T23:00:00.000Z"
    var _getDate: String = .empty

    // MARK: - PMNIBirthday

    override func getText() -> String {
        _getText
    }

    override func getDate() -> String {
        _getDate
    }
}
