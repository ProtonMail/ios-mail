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

import UIKit

final class SectionTitleUITableViewDiffableDataSource<SectionIdentifier, ItemIdentifier>:
    UITableViewDiffableDataSource<SectionIdentifier, ItemIdentifier>
    where SectionIdentifier: Hashable, ItemIdentifier: Hashable {

    typealias SectionTitleProvider = (UITableView, SectionIdentifier) -> String?

    var sectionTitleProvider: SectionTitleProvider?
    var useSectionIndex = false

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        guard useSectionIndex, let sectionTitleProvider = sectionTitleProvider else { return nil }
        return snapshot().sectionIdentifiers.compactMap { sectionTitleProvider(tableView, $0) }
    }

    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        guard useSectionIndex else { return 0 }
        return snapshot().sectionIdentifiers.firstIndex(where: { sectionTitleProvider?(tableView, $0) == title }) ?? 0
    }

    override func apply(
        _ snapshot: NSDiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier>,
        animatingDifferences: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        super.applySnapshotUsingReloadData(snapshot, completion: completion)
    }
}
