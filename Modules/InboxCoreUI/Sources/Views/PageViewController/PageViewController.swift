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

import Combine
import InboxCore
import proton_app_uniffi
import SwiftUI

public struct PageViewController<Page: View>: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode

    let cursor: MailboxCursorProtocol
    let isSwipeToAdjacentEnabled: Bool
    let startingPage: () -> Page
    let pageFactory: (CursorEntry) -> Page

    public init(
        cursor: MailboxCursorProtocol,
        isSwipeToAdjacentEnabled: Bool,
        startingPage: @escaping () -> Page,
        pageFactory: @escaping (CursorEntry) -> Page
    ) {
        self.cursor = cursor
        self.isSwipeToAdjacentEnabled = isSwipeToAdjacentEnabled
        self.startingPage = startingPage
        self.pageFactory = pageFactory
    }

    public func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pageViewController.delegate = context.coordinator

        let page = startingPage()
        let hostingController = UIHostingController(rootView: page)
        pageViewController.setViewControllers([hostingController], direction: .forward, animated: false)

        if let notifier = context.environment.goToNextPageNotifier {
            context.coordinator.subscribe(to: notifier, pageViewController: pageViewController)
        }

        return pageViewController
    }

    public func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        uiViewController.dataSource = isSwipeToAdjacentEnabled ? context.coordinator : nil
    }

    public func makeCoordinator() -> Coordinator {
        .init(
            cursor: cursor,
            pageFactory: pageFactory,
            dismiss: { presentationMode.wrappedValue.dismiss() }
        )
    }
}

extension PageViewController {
    public final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        private let cursor: MailboxCursorProtocol
        private let pageFactory: (CursorEntry) -> Page
        private let dismiss: () -> Void
        private var cancellables = Set<AnyCancellable>()

        init(
            cursor: MailboxCursorProtocol,
            pageFactory: @escaping (CursorEntry) -> Page,
            dismiss: @escaping () -> Void
        ) {
            self.cursor = cursor
            self.pageFactory = pageFactory
            self.dismiss = dismiss
        }

        func subscribe(to notifier: GoToNextPageNotifier, pageViewController: UIPageViewController) {
            notifier
                .publisher
                .sink { [weak self] _ in
                    self?.goToNextPage(pageViewController: pageViewController)
                }
                .store(in: &cancellables)
        }

        private func goToNextPage(pageViewController: UIPageViewController) {
            guard
                let currentViewController = pageViewController.viewControllers?.first,
                let newCenterViewController = self.pageViewController(pageViewController, viewControllerAfter: currentViewController)
            else {
                dismiss()
                return
            }

            cursor.gotoNext()

            pageViewController.setViewControllers([newCenterViewController], direction: .forward, animated: false)
        }

        // MARK: UIPageViewControllerDataSource

        public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            makeViewController(adjacentTo: viewController, inDirection: .reverse)
        }

        public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            makeViewController(adjacentTo: viewController, inDirection: .forward)
        }

        private func makeViewController(
            adjacentTo centerViewController: UIViewController,
            inDirection direction: UIPageViewController.NavigationDirection
        ) -> UIViewController? {
            guard let adjacentView = adjacentView(direction: direction) else {
                return nil
            }

            // this is needed to be able to determine direction in didFinishAnimating
            switch direction {
            case .forward:
                adjacentView.view.tag = centerViewController.view.tag + 1
            case .reverse:
                adjacentView.view.tag = centerViewController.view.tag - 1
            @unknown default:
                break
            }

            return adjacentView
        }

        private func adjacentView(direction: UIPageViewController.NavigationDirection) -> UIViewController? {
            let result = adjacentItem(direction: direction)

            switch result {
            case .some(let adjacentItem):
                let page = pageFactory(adjacentItem)
                return UIHostingController(rootView: page)
            case .none:
                return nil
            case .unknown:
                let loadingView = LoadingView(dismiss: dismiss) {
                    try await self.loadNextPage()
                }

                return UIHostingController(rootView: loadingView)
            }
        }

        private func adjacentItem(direction: UIPageViewController.NavigationDirection) -> MailboxCursorPeekNextResult {
            switch direction {
            case .forward:
                cursor.peekNext()
            case .reverse:
                if let previousItem = cursor.peekPrev() {
                    .some(previousItem)
                } else {
                    .none
                }
            @unknown default:
                .none
            }
        }

        private func loadNextPage() async throws -> Page {
            if let nextItem = try await cursor.fetchNext() {
                pageFactory(nextItem)
            } else {
                throw CursorError.nextPagePromisedButNotProvided
            }
        }

        // MARK: UIPageViewControllerDelegate

        public func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            if completed {
                let reachedViewController = pageViewController.viewControllers![0]
                let previousViewController = previousViewControllers[0]

                if reachedViewController.view.tag > previousViewController.view.tag {
                    cursor.gotoNext()
                } else if reachedViewController.view.tag < previousViewController.view.tag {
                    cursor.gotoPrev()
                }
            }
        }
    }
}

private enum CursorError: Error {
    case nextPagePromisedButNotProvided
}
