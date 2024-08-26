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

enum MailboxRow: Hashable {
    case real(MailboxItem)
    // the Int is needed for diffable data sources to generate unique identifiers
    case skeleton(Int)
}

final class MailboxDiffableDataSource {
    private let diffableDataSource: UITableViewDiffableDataSource<Int, MailboxRow>
    private var dataSnapshot: NSDiffableDataSourceSnapshot<Int, MailboxRow>?
    private let queue = DispatchQueue(label: "ch.protonmail.inbox.dataSource")

    init(
        tableView: UITableView,
        cellProvider: @escaping UITableViewDiffableDataSource<Int, MailboxRow>.CellProvider
    ) {
        self.diffableDataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: cellProvider)
    }

    func animateSkeletonLoading() {
        dataSnapshot = diffableDataSource.snapshot()
        let newSnapshot = reloadSkeletonData()
        queue.async {
            self.diffableDataSource.apply(newSnapshot, animatingDifferences: false)
        }
    }

    func cacheSnapshot(_ snapshot: NSDiffableDataSourceSnapshot<Int, MailboxRow>) {
        dataSnapshot = snapshot
    }

    func reloadSnapshot(
        snapshot: NSDiffableDataSourceSnapshot<Int, MailboxRow>?,
        forceReload: Bool = false,
        completion: (() -> Void)?
    ) {
        var snapshotToLoad: NSDiffableDataSourceSnapshot<Int, MailboxRow>?
        if let snapshot = snapshot {
            dataSnapshot = snapshot
            snapshotToLoad = snapshot
        } else {
            snapshotToLoad = dataSnapshot
        }

        guard var snapshotToLoad = snapshotToLoad else { return }

        if forceReload {
            do {
                try ObjC.catchException {
                    snapshotToLoad.reloadSections([0])
                }
            } catch {
                SystemLogger.log(error: error)
            }
        }

        queue.async {
            self.diffableDataSource.apply(
                snapshotToLoad,
                animatingDifferences: false,
                completion: completion
            )
        }
    }

    func snapshot() -> NSDiffableDataSourceSnapshot<Int, MailboxRow> {
        return diffableDataSource.snapshot()
    }

    func item(of indexPath: IndexPath) -> MailboxRow? {
        return diffableDataSource.itemIdentifier(for: indexPath)
    }

    private func reloadSkeletonData() -> NSDiffableDataSourceSnapshot<Int, MailboxRow> {
        var skeletonSnapshot = NSDiffableDataSourceSnapshot<Int, MailboxRow>()

        skeletonSnapshot.appendSections([0])
        let itemsToReload: [MailboxRow] = (0..<10).map { MailboxRow.skeleton($0) }
        skeletonSnapshot.appendItems(itemsToReload, toSection: 0)

        return skeletonSnapshot
    }
}
