// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCoreTestingToolkitUnitTestsServices
@testable import ProtonMail
import XCTest

final class BannerViewControllerTests: XCTestCase {

    private var sut: BannerViewController!
    private var viewModel: BannerViewModel!
    private var infoProvider: MessageInfoProvider!
    private var testContainer: TestContainer!
    private var user: UserManager!

    private let systemUpTime = SystemUpTimeMock(
        localServerTime: TimeInterval(1635745851),
        localSystemUpTime: TimeInterval(2000),
        systemUpTime: TimeInterval(2000)
    )

    override func setUpWithError() throws {
        try super.setUpWithError()
        user = .init(api: APIServiceMock(), globalContainer: testContainer)
        testContainer = .init()
        setupSUT()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        sut = nil
        viewModel = nil
        user = nil
        testContainer = nil
    }

    func testSnoozedMessage_unsnoozeBannerWillBeShown() throws {
        infoProvider = .init(
            message: .make(
                labels: [.make(labelID: Message.Location.snooze.labelID)],
                snoozeTime: Date(timeIntervalSince1970: 700000)
            ),
            systemUpTime: systemUpTime,
            labelID: .init("0"),
            dependencies: user.container,
            highlightedKeywords: []
        )
        viewModel.providerHasChanged(provider: infoProvider)
        sut.loadViewIfNeeded()

        wait(self.sut.containerView?.arrangedSubviews.count == 1)

        let banner = try XCTUnwrap(
            sut.containerView?.arrangedSubviews.first as? UnsnoozeBanner
        )
        let dateString = PMDateFormatter.shared.stringForSnoozeTime(from: Date(timeIntervalSince1970: 700000))
        XCTAssertEqual(
            banner.infoLabel.text,
            String(format: L10n.Snooze.bannerTitle, dateString)
        )
    }

    func testMessageInInbox_noUnsnoozeBannerWillBeShown() {
        infoProvider = .init(
            message: .make(
                labels: [.make(labelID: Message.Location.inbox.labelID)]
            ),
            systemUpTime: systemUpTime,
            labelID: .init("0"),
            dependencies: user.container,
            highlightedKeywords: []
        )
        viewModel.providerHasChanged(provider: infoProvider)
        sut.loadViewIfNeeded()

        wait(self.sut.containerView?.arrangedSubviews.count == 0)
    }

    func testInSingleMessageMode_withSnoozeMessage_noButtonIsShownInUnsnoozeBanner() throws {
        setupSUT(viewMode: .singleMessage)
        infoProvider = .init(
            message: .make(
                labels: [.make(labelID: Message.Location.snooze.labelID)],
                snoozeTime: Date(timeIntervalSince1970: 700000)
            ),
            systemUpTime: systemUpTime,
            labelID: .init("0"),
            dependencies: user.container,
            highlightedKeywords: []
        )
        viewModel.providerHasChanged(provider: infoProvider)
        sut.loadViewIfNeeded()

        wait(self.sut.containerView?.arrangedSubviews.count == 1)

        let banner = try XCTUnwrap(
            sut.containerView?.arrangedSubviews.first as? UnsnoozeBanner
        )
        let dateString = PMDateFormatter.shared.stringForSnoozeTime(from: Date(timeIntervalSince1970: 700000))
        XCTAssertEqual(
            banner.infoLabel.text,
            String(format: L10n.Snooze.bannerTitle, dateString)
        )
        XCTAssertNil(banner.unsnoozeButton.superview)
    }

    private func setupSUT(viewMode: ViewMode = .conversation) {
        viewModel = .init(
            shouldAutoLoadRemoteContent: true,
            expirationTime: nil,
            shouldAutoLoadEmbeddedImage: true,
            unsubscribeActionHandler: MockUnsubscribeActionHandler(),
            markLegitimateActionHandler: MockMarkLegitimateActionHandler(),
            receiptActionHandler: MockReceiptActionHandler(),
            urlOpener: UIApplication.shared,
            viewMode: viewMode
        )
        sut = .init(viewModel: viewModel)
    }
}
