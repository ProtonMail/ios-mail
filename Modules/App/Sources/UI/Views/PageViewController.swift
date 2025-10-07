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

import InboxCore
import proton_app_uniffi
import SwiftUI

enum CursorResult {
    case value(MailboxItemCellUIModel)
    case noValue
    case unknown
}

struct PageViewController<Page: View>: UIViewControllerRepresentable {
    typealias Item = MailboxItemCellUIModel

    let startingItem: Item
    let cursor: MailboxCursorProtocol
    let pageFactory: (Item) -> Page

    init(
        startingItem: Item,
        cursor: MailboxCursorProtocol,
        pageFactory: @escaping (Item) -> Page
    ) {
        self.startingItem = startingItem
        self.cursor = cursor
        self.pageFactory = pageFactory
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator

        let page = pageFactory(startingItem)
        let hostingController = UIHostingController(rootView: page)
        pageViewController.setViewControllers([hostingController], direction: .forward, animated: false)

        return pageViewController
    }

    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        .init(
            cursor: cursor,
            pageFactory: pageFactory
        )
    }
}

extension PageViewController {
    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        private let cursor: MailboxCursorProtocol
        private let pageFactory: (Item) -> Page

        private var transitionInProgress = false

        init(
            cursor: MailboxCursorProtocol,
            pageFactory: @escaping (Item) -> Page
        ) {
            self.cursor = cursor
            self.pageFactory = pageFactory
        }

        // MARK: UIPageViewControllerDataSource

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            adjacentViewController(direction: .reverse, pageViewController: pageViewController)
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            adjacentViewController(direction: .forward, pageViewController: pageViewController)
        }

        private func adjacentViewController(
            direction: UIPageViewController.NavigationDirection,
            pageViewController: UIPageViewController
        ) -> UIViewController? {
            do {
                let result = try cursor.adjacent(direction: direction)

                switch result {
                case .value(let adjacentItem):
                    let adjacentPage = pageFactory(adjacentItem)
                    let hostingController = UIHostingController(rootView: adjacentPage)
                    hostingController.view.tag = direction.viewTag
                    return hostingController
                case .noValue:
                    return nil
                case .unknown:
                    fetchNextPage(for: pageViewController)
                    return nil
                }
            } catch {
                AppLogger.log(error: error)
                return nil
            }
        }

        private func fetchNextPage(for pageViewController: UIPageViewController) {
            Task {
                do {
                    _ = try await cursor.fetchNext().get()

                    if !transitionInProgress {
                        invalidateCachedAdjacentViewControllers(in: pageViewController)
                    }
                } catch {
                    AppLogger.log(error: error)
                }
            }
        }

        private func invalidateCachedAdjacentViewControllers(in pageViewController: UIPageViewController) {
            pageViewController.dataSource = nil
            pageViewController.dataSource = self
        }

        // MARK: UIPageViewControllerDelegate

        func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
            transitionInProgress = true
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            transitionInProgress = false

            if completed {
                let reachedViewController = pageViewController.viewControllers![0]
                let previousViewController = previousViewControllers[0]

                switch UIPageViewController.NavigationDirection(viewTag: reachedViewController.view.tag) {
                case .forward:
                    previousViewController.view.tag = -1
                    cursor.goForward()
                case .reverse:
                    previousViewController.view.tag = 1
                    cursor.goBackward()
                default:
                    assertionFailure("unexpected tag: \(reachedViewController.view.tag)")
                }

                reachedViewController.view.tag = 0
            }
        }
    }
}

private extension MailboxCursorProtocol {
    func adjacent(direction: UIPageViewController.NavigationDirection) throws -> CursorResult {
        switch direction {
        case .forward:
            switch try getNext().get() {
            case .some(let entry): .value(entry.mailboxItemCellUIModel())
            case .none: .noValue
            case .callAsync: .unknown
            }
        case .reverse:
            if let entry = try getPrevious().get() {
                .value(entry.mailboxItemCellUIModel())
            } else {
                .noValue
            }
        @unknown default:
            fatalError()
        }
    }
}

private extension CursorEntry {
    func mailboxItemCellUIModel() -> MailboxItemCellUIModel {
        switch self {
        case .conversationEntry(let conversation):
            conversation.toMailboxItemCellUIModel(selectedIds: [], showLocation: false)
        case .messageEntry(let message):
            message.toMailboxItemCellUIModel(selectedIds: [], displaySenderEmail: false, showLocation: false)
        }
    }
}

private extension UIPageViewController.NavigationDirection {
    init?(viewTag: Int) {
        switch viewTag {
        case -1:
            self = .reverse
        case 1:
            self = .forward
        default:
            return nil
        }
    }

    var viewTag: Int {
        switch self {
        case .forward:
            1
        case .reverse:
            -1
        @unknown default:
            0
        }
    }
}
