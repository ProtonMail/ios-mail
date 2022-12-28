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

enum MailboxRow: Hashable {
    case real(MailboxItem)
    // the Int is needed for diffable data sources to generate unique identifiers
    case skeleton(Int)
}

@available(iOS 13.0, *)
final class MailboxDiffableDataSource: MailboxDataSource {
    private let diffableDataSource: UITableViewDiffableDataSource<Int, MailboxRow>
    private let viewModel: MailboxViewModel

    init(viewModel: MailboxViewModel,
         tableView: UITableView,
         shouldAnimateSkeletonLoading: Bool,
         cellProvider: @escaping UITableViewDiffableDataSource<Int, MailboxRow>.CellProvider) {
        self.viewModel = viewModel
        self.diffableDataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: cellProvider)
        self.reloadSnapshot(shouldAnimateSkeletonLoading: shouldAnimateSkeletonLoading, animate: false)
    }

    func reloadSnapshot(shouldAnimateSkeletonLoading: Bool, animate: Bool) {
        let newSnapshot: NSDiffableDataSourceSnapshot<Int, MailboxRow>
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

    private func reloadSkeletonData() -> NSDiffableDataSourceSnapshot<Int, MailboxRow> {
        var skeletonSnapshot = NSDiffableDataSourceSnapshot<Int, MailboxRow>()

        skeletonSnapshot.appendSections([0])
        let itemsToReload: [MailboxRow] = (0..<10).map { MailboxRow.skeleton($0) }
        skeletonSnapshot.appendItems(itemsToReload, toSection: 0)

        return skeletonSnapshot
    }

    private func reloadMailData() -> NSDiffableDataSourceSnapshot<Int, MailboxRow> {
        var realSnapshot = NSDiffableDataSourceSnapshot<Int, MailboxRow>()

        var itemsToReload: [MailboxRow] = []

        for section in 0..<viewModel.sectionCount() {
            realSnapshot.appendSections([section])
            var items: [MailboxRow] = []
            for row in 0..<viewModel.rowCount(section: section) {
                let indexPath = IndexPath(row: row, section: section)
                guard let mailboxItem = viewModel.mailboxItem(at: indexPath) else {
                    continue
                }

                let rowItem = MailboxRow.real(mailboxItem)

                items.append(rowItem)

                if !viewModel.isObjectUpdated(objectID: mailboxItem.objectID) {
                    itemsToReload.append(rowItem)
                }
            }
            realSnapshot.appendItems(items, toSection: section)
        }

        realSnapshot.reloadItems(itemsToReload)

        return realSnapshot
    }
}
