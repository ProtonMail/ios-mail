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
    func reloadSnapshot(shouldAnimateSkeletonLoading: Bool, animate: Bool)
}

@available(iOS 13.0, *)
final class MailboxDiffableDataSource<MailboxItem: MailBoxItemType>: MailboxDataSource {
    private var diffableDataSource: UITableViewDiffableDataSource<Int, MailboxItem>
    private var viewModel: MailboxViewModel

    init(viewModel: MailboxViewModel,
         tableView: UITableView,
         shouldAnimateSkeletonLoading: Bool,
         cellProvider: @escaping UITableViewDiffableDataSource<Int, MailboxItem>.CellProvider) {
        self.viewModel = viewModel
        self.diffableDataSource = UITableViewDiffableDataSource<Int, MailboxItem>(tableView: tableView,
                                                                                  cellProvider: cellProvider)
        self.reloadSnapshot(shouldAnimateSkeletonLoading: shouldAnimateSkeletonLoading, animate: false)
    }

    func reloadSnapshot(shouldAnimateSkeletonLoading: Bool, animate: Bool) {
        let newSnapshot: NSDiffableDataSourceSnapshot<Int, MailboxItem>
        if shouldAnimateSkeletonLoading {
            newSnapshot = reloadSkeletonData()
        } else {
            newSnapshot = reloadMailData()
        }

        // animatingDifferences is ignored on iOS 15 and above, and performs animations by default
        // so we resort to applySnapshotUsingReloadData to ignore animations
        if !animate, #available(iOS 15, *) {
            self.diffableDataSource.applySnapshotUsingReloadData(newSnapshot)
        } else {
            self.diffableDataSource.apply(newSnapshot, animatingDifferences: animate)
        }
    }

    private func reloadSkeletonData() -> NSDiffableDataSourceSnapshot<Int, MailboxItem> {
        var skeletonSnapshot = NSDiffableDataSourceSnapshot<Int, MailboxItem>()

        skeletonSnapshot.appendSections([0])
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
        skeletonSnapshot.appendItems(itemsToReload, toSection: 0)

        return skeletonSnapshot
    }

    private func reloadMailData() -> NSDiffableDataSourceSnapshot<Int, MailboxItem> {
        var realSnapshot = NSDiffableDataSourceSnapshot<Int, MailboxItem>()

        for section in 0..<viewModel.sectionCount() {
            realSnapshot.appendSections([section])
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
            realSnapshot.appendItems(items, toSection: section)
        }

        let itemsToReload: [MailboxItem] = realSnapshot.itemIdentifiers.compactMap { itemIdentifier in
            guard let currentIndex = realSnapshot.indexOfItem(itemIdentifier),
                  let index = realSnapshot.indexOfItem(itemIdentifier), index == currentIndex else {
                return nil
            }
            guard viewModel.isObjectUpdated(objectID: itemIdentifier.objectID) else {
                return nil
            }
            return itemIdentifier
        }
        realSnapshot.reloadItems(itemsToReload)

        return realSnapshot
    }
}

protocol CoreDataBasedObject {
    var objectID: ObjectID { get }
}
typealias MailBoxItemType = CoreDataBasedObject & Hashable
extension ConversationEntity: CoreDataBasedObject {}
extension MessageEntity: CoreDataBasedObject {}
