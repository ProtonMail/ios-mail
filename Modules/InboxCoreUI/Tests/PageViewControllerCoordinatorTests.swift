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

import SwiftUI
import Testing

@testable import InboxCoreUI

private struct IndexedView: View {
    let index: Int

    var body: some View {
        EmptyView()
    }
}

@MainActor
final class PageViewControllerCoordinatorTests {
    private let items: [Int] = .init(0..<10)
    private let pageViewController = PageViewControllerSpy()

    private lazy var sut = PageViewController.Coordinator(
        previousItem: { [unowned self] currentItem in items.randomElement() },
        nextItem: { [unowned self] currentItem in items.randomElement() },
        pageFactory: { item in IndexedView(index: item) },
        itemForPage: { page in page.index }
    )

    @Test
    func whenTransitionStarts_thenLoadsItemsAdjacentToDestinationItem() async throws {
        let adjacentViewController = UIHostingController(rootView: IndexedView(index: 1))
        sut.pageViewController(pageViewController, willTransitionTo: [adjacentViewController])
    }

    @Test
    func whenTransitionEnds_purgesCache() async throws {
        sut.pageViewController(pageViewController, didFinishAnimating: false, previousViewControllers: [], transitionCompleted: true)
    }

    @Test
    func whenItemIsLoadedBeforeTransitionEnds_thenDoesntInvalidateCachedViewControllers() {
        sut.loadItemsAdjacent(to: 0, in: pageViewController)
        #expect(pageViewController.receivedDataSources.count == 0)
    }

    @Test
    func whenItemIsLoadedAfterTransitionEnds_thenInvalidatesCachedViewControllers() throws {
        sut.loadItemsAdjacent(to: 0, in: pageViewController)
        #expect(pageViewController.receivedDataSources.count == 2)
        #expect(pageViewController.receivedDataSources.first == nil)
        let receivedDataSource = try #require(pageViewController.receivedDataSources.last)
        #expect(receivedDataSource === sut)
    }
}

private final class PageViewControllerSpy: UIPageViewController {
    private(set) var receivedDataSources: [(any UIPageViewControllerDataSource)?] = []

    override var dataSource: (any UIPageViewControllerDataSource)? {
        didSet {
            receivedDataSources.append(dataSource)
        }
    }

    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
