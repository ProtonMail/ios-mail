// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail
import CoreMedia
import ProtonCore_TestingToolkit

class BannerViewModelTests: XCTestCase {
    var sut: BannerViewModel!
    var contextProviderMock: MockCoreDataContextProvider!
    var mockMessage: MessageEntity!
    var rawMessage: Message!
    var unsubscribeHandlerMock: MockUnsubscribeActionHandler!
    var markLegitimateHandlerMock: MockMarkLegitimateActionHandler!
    var receiptHandlerMock: MockReceiptActionHandler!
    var userManagerMock: UserManager!
    var apiServiceMock: APIServiceMock!
    var systemUpTimeMock: SystemUpTimeMock!

    override func setUp() {
        super.setUp()
        contextProviderMock = MockCoreDataContextProvider()
        rawMessage = Message(context: contextProviderMock.rootSavingContext)
        mockMessage = nil
        unsubscribeHandlerMock = MockUnsubscribeActionHandler()
        markLegitimateHandlerMock = MockMarkLegitimateActionHandler()
        receiptHandlerMock = MockReceiptActionHandler()
        apiServiceMock = APIServiceMock()
        userManagerMock = UserManager(api: apiServiceMock, role: .none)
        systemUpTimeMock = SystemUpTimeMock(localServerTime: 0, localSystemUpTime: 0, systemUpTime: 0)

        let scheduledLabel = Label(context: contextProviderMock.rootSavingContext)
        scheduledLabel.labelID = "12"
        let inboxLabel = Label(context: contextProviderMock.rootSavingContext)
        inboxLabel.labelID = "0"
        _ = contextProviderMock.rootSavingContext.saveUpstreamIfNeeded()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        contextProviderMock = nil
        mockMessage = nil
        rawMessage = nil
        unsubscribeHandlerMock = nil
        markLegitimateHandlerMock = nil
        receiptHandlerMock = nil
        apiServiceMock = nil
        userManagerMock = nil
        systemUpTimeMock = nil
    }

    func testDurationsBySecond() {
        let sut = BannerViewModel.durationsBySecond
        let result = sut(1000)
        XCTAssertEqual(result.days, 0)
        XCTAssertEqual(result.hours, 0)
        XCTAssertEqual(result.minutes, 16)

        let result2 = sut(1000000)
        XCTAssertEqual(result2.days, 11)
        XCTAssertEqual(result2.hours, 13)
        XCTAssertEqual(result2.minutes, 46)
    }

    func testCalculateExpirationTitle_withMinusInput_getExpiredMsg() {
        let sut = BannerViewModel.calculateExpirationTitle
        let result = sut(-1)
        XCTAssertEqual(result, LocalString._message_expired)
    }

    func testCalculateExpirationTitle_withInput0_getExpiredMsg() {
        let sut = BannerViewModel.calculateExpirationTitle
        let result = sut(0)
        XCTAssertEqual(result, LocalString._message_expired)
    }

    func testCalculateExpirationTitle_withInput1000() {
        let sut = BannerViewModel.calculateExpirationTitle
        let expected = String(format: LocalString._expires_in_days_hours_mins_seconds, 0, 0, 17)

        let result = sut(1000)
        XCTAssertEqual(result, expected)
    }

    func testCalculateExpirationTitle_withInput1000000() {
        let sut = BannerViewModel.calculateExpirationTitle
        let expected = String(format: LocalString._expires_in_days_hours_mins_seconds, 11, 13, 47)

        let result = sut(1000000)
        XCTAssertEqual(result, expected)
    }

    func testScheduledSendingTime_timeIsNil_returnNil() {
        rawMessage.time = nil
        createSUT()

        XCTAssertNil(sut.scheduledSendingTime)
    }

    func testScheduledSendingTime_timeIsNotNil_notInScheduled_returnNil() {
        rawMessage.time = Date()
        _ = rawMessage.add(labelID: "0")

        createSUT()
        XCTAssertNil(sut.scheduledSendingTime)
    }

    func testScheduledSendingTime_messageHasTime_returnNonNil() {
        rawMessage.time = Date(timeIntervalSince1970: 12849012491)
        _ = rawMessage.add(labelID: "12")

        createSUT()
        XCTAssertNotNil(sut.scheduledSendingTime)
    }

    func testSpamType_withDmarcFailed_returnSameType() {
        var flag = Message.Flag()
        flag.insert(.dmarcFailed)
        rawMessage.flag = flag
        createSUT()

        XCTAssertEqual(sut.spamType, .dmarcFailed)
    }

    func testSpamType_withPhishing_returnSameType() {
        var flag = Message.Flag()
        flag.insert(.autoPhishing)
        rawMessage.flag = flag
        createSUT()

        XCTAssertEqual(sut.spamType, .autoPhishing)
    }

    func testSpamType_withPhishingAndHamManual_returnNil() {
        var flag = Message.Flag()
        flag.insert(.autoPhishing)
        flag.insert(.hamManual)
        rawMessage.flag = flag
        createSUT()

        XCTAssertNil(sut.spamType)
    }

    func testIsAutoReply_sameAsMessage() {
        createSUT()
        XCTAssertEqual(sut.isAutoReply, mockMessage.isAutoReply)
    }

    func testMarkAsLegitimate() {
        createSUT()
        sut.markAsLegitimate()
        XCTAssertTrue(markLegitimateHandlerMock.callMarkAsLegitimate.wasCalledExactlyOnce)
        XCTAssertEqual(markLegitimateHandlerMock.callMarkAsLegitimate.lastArguments?.a1, mockMessage.messageID)
    }

    func testSendReceipt() {
        createSUT()
        sut.sendReceipt()
        XCTAssertTrue(receiptHandlerMock.callSendReceipt.wasCalledExactlyOnce)
        XCTAssertEqual(receiptHandlerMock.callSendReceipt.lastArguments?.a1, mockMessage.messageID)
    }

    private func createSUT() {
        mockMessage = MessageEntity(rawMessage)
        sut = BannerViewModel(shouldAutoLoadRemoteContent: false,
                              expirationTime: nil,
                              shouldAutoLoadEmbeddedImage: false,
                              unsubscribeActionHandler: unsubscribeHandlerMock,
                              markLegitimateActionHandler: markLegitimateHandlerMock,
                              receiptActionHandler: receiptHandlerMock,
                              weekStart: .automatic,
                              urlOpener: UIApplication.shared)
        sut.providerHasChanged(provider: .init(message: mockMessage,
                                               user: userManagerMock,
                                               systemUpTime: systemUpTimeMock,
                                               labelID: ""))
    }
}
