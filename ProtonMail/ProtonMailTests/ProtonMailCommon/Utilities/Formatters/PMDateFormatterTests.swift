@testable import ProtonMail
import XCTest

class PMDateFormatterTests: XCTestCase {

    var sut: PMDateFormatter!

    override func setUp() {
        super.setUp()

        sut = PMDateFormatter()
    }

    override func tearDown() {
        super.tearDown()

        Environment.restore()
    }

    func testFormattingWithEnglishUKLocaleWhenWeekStartIsMonday() {
        Environment.locale = Locale(identifier: "en_GB")
        Environment.currentDate = { Date.fixture("2021-06-24 00:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!

        sut.isDateInToday = { _ in true }
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-24 12:00:00"), weekStart: .monday), "12:00")
        sut.isDateInToday = { _ in false }

        sut.isDateInYesterday = { _ in true }
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-23 00:00:00"), weekStart: .monday), "Yesterday")
        sut.isDateInYesterday = { _ in false }

        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-22 00:00:00"), weekStart: .monday), "Tuesday")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-21 00:00:00"), weekStart: .monday), "Monday")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-20 00:00:00"), weekStart: .monday), "20 June 2021")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-19 00:00:00"), weekStart: .monday), "19 June 2021")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-18 00:00:00"), weekStart: .monday), "18 June 2021")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-17 00:00:00"), weekStart: .monday), "17 June 2021")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-16 00:00:00"), weekStart: .monday), "16 June 2021")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-15 00:00:00"), weekStart: .monday), "15 June 2021")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-14 00:00:00"), weekStart: .monday), "14 June 2021")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-13 00:00:00"), weekStart: .monday), "13 June 2021")
        XCTAssertEqual(sut.string(from: Date.fixture("2020-06-25 00:00:00"), weekStart: .monday), "25 June 2020")
    }

    func testFormattingWithEnglishUKLocaleWhenWeekStartIsSunday() {
        Environment.locale = Locale(identifier: "en_GB")
        Environment.currentDate = { Date.fixture("2021-06-24 00:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!

        sut.isDateInToday = { _ in true }
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-24 12:00:00"), weekStart: .sunday), "12:00")
        sut.isDateInToday = { _ in false }

        sut.isDateInYesterday = { _ in true }
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-23 00:00:00"), weekStart: .sunday), "Yesterday")
        sut.isDateInYesterday = { _ in false }

        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-22 00:00:00"), weekStart: .sunday), "Tuesday")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-21 00:00:00"), weekStart: .sunday), "Monday")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-20 00:00:00"), weekStart: .sunday), "Sunday")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-19 00:00:00"), weekStart: .sunday), "19 June 2021")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-18 00:00:00"), weekStart: .sunday), "18 June 2021")
        XCTAssertEqual(sut.string(from: Date.fixture("2020-06-25 00:00:00"), weekStart: .sunday), "25 June 2020")
    }

    func testFormattingWithEnglishUKLocaleWhenWeekStartIsSaturday() {
        Environment.locale = Locale(identifier: "en_GB")
        Environment.currentDate = { Date.fixture("2021-06-24 00:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!

        sut.isDateInToday = { _ in true }
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-24 12:00:00"), weekStart: .saturday), "12:00")
        sut.isDateInToday = { _ in false }

        sut.isDateInYesterday = { _ in true }
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-23 00:00:00"), weekStart: .saturday), "Yesterday")
        sut.isDateInYesterday = { _ in false }

        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-22 00:00:00"), weekStart: .saturday), "Tuesday")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-21 00:00:00"), weekStart: .saturday), "Monday")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-20 00:00:00"), weekStart: .saturday), "Sunday")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-19 00:00:00"), weekStart: .saturday), "Saturday")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-18 00:00:00"), weekStart: .saturday), "18 June 2021")
        XCTAssertEqual(sut.string(from: Date.fixture("2020-06-25 00:00:00"), weekStart: .saturday), "25 June 2020")
    }

    func testFormattingWithEnglishUSALocaleWhenWeekStartIsMonday() {
        Environment.locale = Locale(identifier: "en_US")
        Environment.currentDate = { Date.fixture("2021-06-24 00:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!

        sut.isDateInToday = { _ in true }
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-24 12:00:00"), weekStart: .monday), "12:00")
        sut.isDateInToday = { _ in false }

        sut.isDateInYesterday = { _ in true }
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-23 00:00:00"), weekStart: .monday), "Yesterday")
        sut.isDateInYesterday = { _ in false }

        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-22 00:00:00"), weekStart: .monday), "Tuesday")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-21 00:00:00"), weekStart: .monday), "Monday")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-20 00:00:00"), weekStart: .monday), "June 20, 2021")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-19 00:00:00"), weekStart: .monday), "June 19, 2021")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-18 00:00:00"), weekStart: .monday), "June 18, 2021")
        XCTAssertEqual(sut.string(from: Date.fixture("2020-06-25 00:00:00"), weekStart: .monday), "June 25, 2020")
    }

    func testFormattingWithAutomaticEn_USWeekStart() {
        Environment.locale = Locale(identifier: "en_US")
        Environment.currentDate = { Date.fixture("2021-06-23 00:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!

        sut.isDateInYesterday = { _ in true }
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-22 00:00:00"), weekStart: .automatic), "Yesterday")
        sut.isDateInYesterday = { _ in false }

        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-21 00:00:00"), weekStart: .automatic), "Monday")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-20 00:00:00"), weekStart: .automatic), "Sunday")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-19 00:00:00"), weekStart: .automatic), "June 19, 2021")
    }

    func testFormattingWithAutomaticEn_GNWeekStart() {
        Environment.locale = Locale(identifier: "en_GB")
        Environment.currentDate = { Date.fixture("2021-06-23 00:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!

        sut.isDateInYesterday = { _ in true }
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-22 00:00:00"), weekStart: .automatic), "Yesterday")
        sut.isDateInYesterday = { _ in false }

        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-21 00:00:00"), weekStart: .automatic), "Monday")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-20 00:00:00"), weekStart: .automatic), "20 June 2021")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-19 00:00:00"), weekStart: .automatic), "19 June 2021")
    }

}
