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
import ProtonCoreTestingToolkitUnitTestsServices

class BannerViewModelTests: XCTestCase {
    var sut: BannerViewModel!
    var unsubscribeHandlerMock: MockUnsubscribeActionHandler!
    var markLegitimateHandlerMock: MockMarkLegitimateActionHandler!
    var receiptHandlerMock: MockReceiptActionHandler!
    var userManagerMock: UserManager!
    var apiServiceMock: APIServiceMock!
    var systemUpTimeMock: SystemUpTimeMock!

    override func setUp() {
        super.setUp()

        unsubscribeHandlerMock = MockUnsubscribeActionHandler()
        markLegitimateHandlerMock = MockMarkLegitimateActionHandler()
        receiptHandlerMock = MockReceiptActionHandler()
        apiServiceMock = APIServiceMock()
        userManagerMock = UserManager(api: apiServiceMock)
        systemUpTimeMock = SystemUpTimeMock(localServerTime: 0, localSystemUpTime: 0, systemUpTime: 0)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
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
        let message = MessageEntity.make(time: nil)
        createSUT(mockMessage: message)

        XCTAssertNil(sut.scheduledSendingTime)
    }

    func testScheduledSendingTime_timeIsNotNil_notInScheduled_returnNil() {
        let message = MessageEntity.make(time: Date(), labels: [.make(labelID: "0")])

        createSUT(mockMessage: message)
        XCTAssertNil(sut.scheduledSendingTime)
    }

    func testScheduledSendingTime_messageHasTime_returnNonNil() {
        let message = MessageEntity.make(
            time: Date(timeIntervalSince1970: 12849012491),
            labels: [.make(labelID: "12")]
        )

        createSUT(mockMessage: message)
        XCTAssertNotNil(sut.scheduledSendingTime)
    }

    func testSpamType_withDmarcFailed_returnSameType() {
        var flag = Message.Flag()
        flag.insert(.dmarcFailed)
        let message = MessageEntity.make(rawFlag: flag.rawValue)
        createSUT(mockMessage: message)

        XCTAssertEqual(sut.spamType, .dmarcFailed)
    }

    func testSpamType_with_dmarcPass() {
        var flag = Message.Flag()
        flag.insert(.dmarcFailed)
        flag.insert(.dmarcPass)
        let message = MessageEntity.make(rawFlag: flag.rawValue)
        createSUT(mockMessage: message)
        XCTAssertNil(sut.spamType)
    }

    func testSpamType_withPhishing_returnSameType() {
        var flag = Message.Flag()
        flag.insert(.autoPhishing)
        let message = MessageEntity.make(rawFlag: flag.rawValue)
        createSUT(mockMessage: message)

        XCTAssertEqual(sut.spamType, .autoPhishing)
    }

    func testSpamType_withPhishingAndHamManual_returnNil() {
        var flag = Message.Flag()
        flag.insert(.autoPhishing)
        flag.insert(.hamManual)
        let message = MessageEntity.make(rawFlag: flag.rawValue)
        createSUT(mockMessage: message)

        XCTAssertNil(sut.spamType)
    }

    func testIsAutoReply_sameAsMessage() {
        let mockMessage = MessageEntity.make()
        createSUT(mockMessage: mockMessage)
        XCTAssertEqual(sut.isAutoReply, mockMessage.isAutoReply)
    }

    func testMarkAsLegitimate() {
        let mockMessage = MessageEntity.make(messageID: .init(rawValue: UUID().uuidString))
        createSUT(mockMessage: mockMessage)
        sut.markAsLegitimate()
        XCTAssertTrue(markLegitimateHandlerMock.markAsLegitimateStub.wasCalledExactlyOnce)
        XCTAssertEqual(markLegitimateHandlerMock.markAsLegitimateStub.lastArguments?.a1, mockMessage.messageID)
    }

    func testSendReceipt() {
        let mockMessage = MessageEntity.make(messageID: .init(rawValue: UUID().uuidString))
        createSUT(mockMessage: mockMessage)
        sut.sendReceipt()
        XCTAssertTrue(receiptHandlerMock.sendReceiptStub.wasCalledExactlyOnce)
        XCTAssertEqual(receiptHandlerMock.sendReceiptStub.lastArguments?.a1, mockMessage.messageID)
    }

    private func createSUT(mockMessage: MessageEntity) {
        sut = BannerViewModel(shouldAutoLoadRemoteContent: false,
                              expirationTime: nil,
                              shouldAutoLoadEmbeddedImage: false,
                              unsubscribeActionHandler: unsubscribeHandlerMock,
                              markLegitimateActionHandler: markLegitimateHandlerMock,
                              receiptActionHandler: receiptHandlerMock,
                              urlOpener: UIApplication.shared,
                              viewMode: .singleMessage)

        let globalContainer = GlobalContainer()
        let userContainer = UserContainer(userManager: userManagerMock, globalContainer: globalContainer)

        sut.providerHasChanged(
            provider: .init(
                message: mockMessage,
                systemUpTime: systemUpTimeMock,
                labelID: "",
                dependencies: userContainer,
                highlightedKeywords: []
            )
        )
    }
}
