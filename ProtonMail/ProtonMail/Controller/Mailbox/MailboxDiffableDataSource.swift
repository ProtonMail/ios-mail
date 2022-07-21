// Copyright (c) 2021 Proton AG
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

import UIKit

protocol MailboxDataSource {
    func refreshItems(at indexPaths: [IndexPath], animate: Bool)
    func reloadSnapshot(shouldAnimateSkeletonLoading: Bool, animate: Bool)
}

@available(iOS 13.0, *)
final class MailboxDiffableDataSource<MailboxItem: MailBoxItemType>: MailboxDataSource {
    private var diffableDataSource: UITableViewDiffableDataSource<Int, MailboxItem>
    private var snapshot: NSDiffableDataSourceSnapshot<Int, MailboxItem>
    private var viewModel: MailboxViewModel

    init(viewModel: MailboxViewModel,
         tableView: UITableView,
         shouldAnimateSkeletonLoading: Bool,
         cellProvider: @escaping UITableViewDiffableDataSource<Int, MailboxItem>.CellProvider) {
        self.viewModel = viewModel
        self.diffableDataSource = UITableViewDiffableDataSource<Int, MailboxItem>(tableView: tableView,
                                                                                  cellProvider: cellProvider)
        // Double initialization but mandatory for the compiler and doesn't impact anything
        self.snapshot = NSDiffableDataSourceSnapshot()
        self.reloadSnapshot(shouldAnimateSkeletonLoading: shouldAnimateSkeletonLoading, animate: false)
    }

    func refreshItems(at indexPaths: [IndexPath], animate: Bool) {
        if !indexPaths.isEmpty {
            var itemsToReload: [MailboxItem] = []
            switch viewModel.locationViewMode {
            case .singleMessage:
                for indexPath in indexPaths {
                    if let message = diffableDataSource.itemIdentifier(for: indexPath) {
                        itemsToReload.append(message)
                    }
                }
            case .conversation:
                for indexPath in indexPaths {
                    if let conversation = diffableDataSource.itemIdentifier(for: indexPath) {
                        itemsToReload.append(conversation)
                    }
                }
            }

            if !itemsToReload.isEmpty {
                self.snapshot.reloadItems(itemsToReload)
                // animatingDifferences is ignored on iOS 15 and above, and performs animations by default
                // so we resort to applySnapshotUsingReloadData to ignore animations
                if !animate, #available(iOS 15, *) {
                    self.diffableDataSource.applySnapshotUsingReloadData(self.snapshot)
                } else {
                    self.diffableDataSource.apply(self.snapshot, animatingDifferences: animate)
                }
            }
        }
    }

    func reloadSnapshot(shouldAnimateSkeletonLoading: Bool, animate: Bool) {
        self.snapshot = NSDiffableDataSourceSnapshot()
        if shouldAnimateSkeletonLoading {
            reloadSkeletonData()
        } else {
            reloadMailData()
        }
        // animatingDifferences is ignored on iOS 15 and above, and performs animations by default
        // so we resort to applySnapshotUsingReloadData to ignore animations
        if !animate, #available(iOS 15, *) {
            self.diffableDataSource.applySnapshotUsingReloadData(self.snapshot)
        } else {
            self.diffableDataSource.apply(self.snapshot, animatingDifferences: animate)
        }
    }

    private func reloadSkeletonData() {
        self.snapshot.appendSections([0])
        var itemsToReload: [MailboxItem] = []
        for _ in 0..<10 {
            switch viewModel.locationViewMode {
            case .singleMessage:
                let fakeMsg = viewModel.makeFakeRawMessage()
                guard let item = MessageEntity(fakeMsg) as? MailboxItem else {
                    fatalError("Misconfigured")
                }
                itemsToReload.append(item)
            case .conversation:
                let fakeConversation = viewModel.makeFakeRawConversation()
                guard let item = ConversationEntity(fakeConversation) as? MailboxItem else {
                    fatalError("Misconfigured")
                }
                itemsToReload.append(item)
            }
        }
        self.snapshot.appendItems(itemsToReload, toSection: 0)
    }

    private func reloadMailData() {
        let currentSnapshot = self.diffableDataSource.snapshot()

        for section in 0..<viewModel.sectionCount() {
            self.snapshot.appendSections([section])
            var items: [MailboxItem] = []
            for row in 0..<viewModel.rowCount(section: section) {
                let indexPath = IndexPath(row: row, section: section)
                switch viewModel.locationViewMode {
                case .singleMessage:
                    if let message = viewModel.item(index: indexPath) as? MailboxItem {
                        items.append(message)
                    }
                case .conversation:
                    if let conversation = viewModel.itemOfConversation(index: indexPath) as? MailboxItem {
                        items.append(conversation)
                    }
                }
            }
            self.snapshot.appendItems(items, toSection: section)
        }

        let itemsToReload: [MailboxItem] = self.snapshot.itemIdentifiers.compactMap { itemIdentifier in
            guard let currentIndex = currentSnapshot.indexOfItem(itemIdentifier),
                  let index = snapshot.indexOfItem(itemIdentifier), index == currentIndex else {
                return nil
            }
            guard viewModel.isObjectUpdated(objectID: itemIdentifier.objectID) else {
                return nil
            }
            return itemIdentifier
        }
        self.snapshot.reloadItems(itemsToReload)
    }
}

protocol CoreDataBasedObject {
    var objectID: ObjectID { get }
}
typealias MailBoxItemType = CoreDataBasedObject & Hashable
extension ConversationEntity: CoreDataBasedObject {}
extension MessageEntity: CoreDataBasedObject {}
