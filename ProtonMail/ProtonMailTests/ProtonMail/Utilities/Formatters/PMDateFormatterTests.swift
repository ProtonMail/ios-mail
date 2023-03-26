@testable import ProtonMail
import XCTest

class PMDateFormatterTests: XCTestCase {

    var sut: PMDateFormatter!
    var notificationCenter: NotificationCenter!

    override func setUp() {
        super.setUp()

        notificationCenter = NotificationCenter()
        sut = PMDateFormatter(notificationCenter: notificationCenter)
    }

    override func tearDown() {
        super.tearDown()

        notificationCenter = nil
        sut = nil
        Environment.restore()
    }

    func testFormattingWithEnglishUKLocaleWhenWeekStartIsMonday() {
        Environment.locale = { .enGB }
        Environment.currentDate = { Date.fixture("2021-06-24 00:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!

        sut.isDateInToday = { _ in true }
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-24 11:00:00"), weekStart: .monday), "11:00")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-24 12:00:00"), weekStart: .monday), "12:00")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-24 13:00:00"), weekStart: .monday), "13:00")
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
        Environment.locale = { .enGB }
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
        Environment.locale = { .enGB }
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
        Environment.locale = { .enUS }
        Environment.currentDate = { Date.fixture("2021-06-24 00:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!

        sut.isDateInToday = { _ in true }
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-24 11:00:00"), weekStart: .monday), "11:00 AM")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-24 12:00:00"), weekStart: .monday), "12:00 PM")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-24 13:00:00"), weekStart: .monday), "1:00 PM")
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
        Environment.locale = { .enUS }
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
        Environment.locale = { .enGB }
        Environment.currentDate = { Date.fixture("2021-06-23 00:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!

        sut.isDateInYesterday = { _ in true }
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-22 00:00:00"), weekStart: .automatic), "Yesterday")
        sut.isDateInYesterday = { _ in false }

        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-21 00:00:00"), weekStart: .automatic), "Monday")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-20 00:00:00"), weekStart: .automatic), "20 June 2021")
        XCTAssertEqual(sut.string(from: Date.fixture("2021-06-19 00:00:00"), weekStart: .automatic), "19 June 2021")
    }

    func testUserChangedLocaleAndRecreateFormatter() {
        let initialFormatterInstance = PMDateFormatter.shared

        notificationCenter.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)

        XCTAssertFalse(initialFormatterInstance === PMDateFormatter.shared)
    }

    func testStringForScheduleMsg_dateIn10Mins() {
        Environment.locale = { .enGB }
        Environment.currentDate = { Date.fixture("2022-04-22 00:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!
        sut.isDateInToday = { _ in true }

        let sendDate = Date.fixture("2022-04-22 00:09:00")
        XCTAssertEqual(sut.stringForScheduledMsg(from: sendDate), "In 9 minutes")

        let sendDate2 = Date.fixture("2022-04-22 00:10:00")
        XCTAssertEqual(sut.stringForScheduledMsg(from: sendDate2), "In 10 minutes")

        let sendDate3 = Date.fixture("2022-04-22 00:01:00")
        XCTAssertEqual(sut.stringForScheduledMsg(from: sendDate3), "In 1 minute")
    }

    func testStringForScheduleMsg_dateIn30Mins() {
        Environment.locale = { .enGB }
        Environment.currentDate = { Date.fixture("2022-04-22 00:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!
        sut.isDateInToday = { _ in true }

        let sendDate = Date.fixture("2022-04-22 00:30:00")
        XCTAssertEqual(sut.stringForScheduledMsg(from: sendDate), "In 30 minutes")

        let sendDate2 = Date.fixture("2022-04-22 00:29:00")
        XCTAssertEqual(sut.stringForScheduledMsg(from: sendDate2), "In 29 minutes")
    }

    func testStringForScheduleMsg_dateMoreThan30Mins_inToday() {
        Environment.locale = { .enGB }
        Environment.currentDate = { Date.fixture("2022-04-22 00:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!
        sut.isDateInToday = { _ in true }

        let sendDate = Date.fixture("2022-04-22 12:30:00")
        XCTAssertEqual(sut.stringForScheduledMsg(from: sendDate), "Today, 12:30")
    }

    func testStringForScheduleMsg_dateInTomorrow() {
        Environment.locale = { .enGB }
        Environment.currentDate = { Date.fixture("2022-04-22 01:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!
        sut.isDateInTomorrow = { _ in true }

        let sendDate = Date.fixture("2022-04-23 18:00:00")
        XCTAssertEqual(sut.stringForScheduledMsg(from: sendDate), "Tomorrow, 18:00")
    }

    func testStringForScheduleMsg_dateIn3Days() {
        Environment.locale = { .enUS }
        Environment.currentDate = { Date.fixture("2022-04-22 00:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!
        sut.isDateInToday = { _ in false }
        sut.isDateInTomorrow = { _ in false }

        let sendDate = Date.fixture("2022-04-24 17:00:00")
        XCTAssert(["April 24, 5:00 PM", "April 24 at 5:00 PM"].contains(sut.stringForScheduledMsg(from: sendDate)))
    }

    func testCheckIsDateWillHappenInTheNext10Mins() {
        Environment.locale = { .enUS }
        Environment.currentDate = { Date.fixture("2022-04-22 00:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!

        let date = Date.fixture("2022-04-22 00:05:00")
        XCTAssertTrue(sut.checkIsDateWillHappenInTheNext10Mins(date))

        let date2 = Date.fixture("2022-04-22 00:15:00")
        XCTAssertFalse(sut.checkIsDateWillHappenInTheNext10Mins(date2))
    }

    func testTitleForScheduledBanner() {
        Environment.locale = { .enUS }
        Environment.currentDate = { Date.fixture("2022-04-22 00:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!

        let date = Date.fixture("2022-04-25 01:05:00")
        XCTAssertEqual(sut.titleForScheduledBanner(from: date).0,
                       "Monday, April 25")
        XCTAssertEqual(sut.titleForScheduledBanner(from: date).1,
                       "1:05 AM")
    }

    func testStringForScheduledMsg_withTimeInThePast() {
        Environment.locale = { .enUS }
        Environment.currentDate = { Date.fixture("2022-04-22 00:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!

        let pastDate = Date.fixture("2022-04-21 00:00:00")
        XCTAssertEqual(sut.stringForScheduledMsg(from: pastDate),
                       LocalString._less_than_1min_not_in_list_view)
    }

    func testStringForScheduledMsg_withTimeLessIn1Minutes_inListView() {
        Environment.locale = { .enUS }
        Environment.currentDate = { Date.fixture("2022-04-22 00:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!
        sut.isDateInToday = { _ in true }

        let date = Date.fixture("2022-04-22 00:00:40")
        XCTAssertEqual(sut.stringForScheduledMsg(from: date, inListView: true), LocalString._less_than_1min_in_list_view)
    }

    func testStringForScheduledMsg_withTimeLessIn1Minutes_notInListView() {
        Environment.locale = { .enUS }
        Environment.currentDate = { Date.fixture("2022-04-22 00:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!
        sut.isDateInToday = { _ in true }

        let date = Date.fixture("2022-04-22 00:00:40")
        XCTAssertEqual(sut.stringForScheduledMsg(from: date, inListView: false), LocalString._less_than_1min_not_in_list_view)
    }
}
