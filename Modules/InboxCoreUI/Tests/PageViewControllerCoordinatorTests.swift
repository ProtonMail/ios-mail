//
// Copyright (c) 2025 Proton Technologies AG
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

import proton_app_uniffi
import SwiftUI
import Testing

@testable import InboxCoreUI

@MainActor
final class PageViewControllerCoordinatorTests {
    private let pageViewController = UIPageViewController()
    private let cursor = MailboxCursorSpy()

    private lazy var sut = PageViewController.Coordinator(
        cursor: cursor,
        pageFactory: { _ in Text("sample page") },
        dismiss: {}
    )

    @Test
    func whenNextItemIsProvidedByCursor_thenShowsPage() throws {
        let centerViewController = setupCenterViewController()

        let nextViewController = sut.pageViewController(pageViewController, viewControllerAfter: centerViewController)

        _ = try #require(nextViewController as? UIHostingController<Text>)
    }

    @Test
    func whenNextItemIsPromisedButNotProvidedByCursor_thenShowsLoadingView() throws {
        let centerViewController = setupCenterViewController()
        cursor.stubbedGetNextResult = .ok(.callAsync)

        let nextViewController = sut.pageViewController(pageViewController, viewControllerAfter: centerViewController)

        _ = try #require(nextViewController as? UIHostingController<LoadingView<Text>>)
    }

    @Test
    func whenThereIsNoNextItemProvidedByCursor_thenDoesntShowAnything() {
        let centerViewController = setupCenterViewController()
        cursor.stubbedGetNextResult = .ok(.none)

        let nextViewController = sut.pageViewController(pageViewController, viewControllerAfter: centerViewController)

        #expect(nextViewController == nil)
    }

    @Test
    func tagsNextPageWithHigherValue() throws {
        let centerViewController = setupCenterViewController()

        let nextViewController = try #require(
            sut.pageViewController(pageViewController, viewControllerAfter: centerViewController)
        )

        #expect(nextViewController.view.tag == 1)
    }

    @Test
    func tagsPreviousPageWithLowerValue() throws {
        let centerViewController = setupCenterViewController()

        let nextViewController = try #require(
            sut.pageViewController(pageViewController, viewControllerBefore: centerViewController)
        )

        #expect(nextViewController.view.tag == -1)
    }

    @Test
    func whenUserNavigatesToNextPage_thenMovesCursorForward() {
        let previousViewController = makeViewController(withTag: 3)
        setupCenterViewController(withTag: 4)

        sut.pageViewController(
            pageViewController,
            didFinishAnimating: false,
            previousViewControllers: [previousViewController],
            transitionCompleted: true
        )

        #expect(cursor.receivedMovements == [.forward])
    }

    @Test
    func whenUserNavigatesToPreviousPage_thenMovesCursorBackward() {
        let previousViewController = makeViewController(withTag: 5)
        setupCenterViewController(withTag: 4)

        sut.pageViewController(
            pageViewController,
            didFinishAnimating: false,
            previousViewControllers: [previousViewController],
            transitionCompleted: true
        )

        #expect(cursor.receivedMovements == [.reverse])
    }

    @Test
    func whenGoToNextPageIsRequested_thenReplacesCurrentPageAndMovesCursorForward() throws {
        setupCenterViewController(withTag: 1)

        let goToNextPageNotifier = GoToNextPageNotifier()
        sut.subscribe(to: goToNextPageNotifier, pageViewController: pageViewController)

        goToNextPageNotifier.notify()

        #expect(cursor.receivedMovements == [.forward])

        let currentViewController = try #require(pageViewController.viewControllers?.first)
        #expect(currentViewController.view.tag == 2)
    }

    @discardableResult
    private func setupCenterViewController(withTag tag: Int = 0) -> UIViewController {
        let centerViewController = makeViewController(withTag: tag)
        pageViewController.setViewControllers([centerViewController], direction: .forward, animated: false)
        return centerViewController
    }

    private func makeViewController(withTag tag: Int) -> UIViewController {
        let viewController = UIHostingController(rootView: Text("foo"))
        viewController.view.tag = tag
        return viewController
    }
}

private final class MailboxCursorSpy: @unchecked Sendable, MailboxCursorProtocol {
    var stubbedGetNextResult: MailboxCursorGetNextResult = .ok(.some(.conversationEntry(.testData())))

    private(set) var receivedMovements: [UIPageViewController.NavigationDirection] = []

    func fetchNext() async -> MailboxCursorFetchNextResult {
        .ok(.none)
    }

    func getNext() -> MailboxCursorGetNextResult {
        stubbedGetNextResult
    }

    func getPrevious() -> MailboxCursorGetPreviousResult {
        .ok(.some(.conversationEntry(.testData())))
    }

    func goBackward() {
        receivedMovements.append(.reverse)
    }

    func goForward() {
        receivedMovements.append(.forward)
    }
}

private extension Conversation {
    static func testData(conversationId: UInt64 = UInt64.random(in: 0..<100)) -> Self {
        .init(
            id: .init(value: conversationId),
            attachmentsMetadata: [],
            customLabels: [],
            displaySnoozeReminder: false,
            snoozedUntil: nil,
            exclusiveLocation: .system(name: .inbox, id: .init(value: 41)),
            expirationTime: 1625140800,
            isStarred: true,
            numAttachments: 0,
            numMessages: 1,
            numUnread: 1,
            totalMessages: 1,
            totalUnread: 1,
            displayOrder: 0,
            recipients: [],
            senders: [],
            size: 1_024,
            subject: .empty,
            time: 1622548800,
            avatar: .init(text: .empty, color: .empty),
            hiddenMessagesBanner: nil
        )
    }
}
