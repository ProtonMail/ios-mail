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

public struct IndexedCell<Cell: UITableViewCell> {
    public let cell: Cell
    public let indexPath: IndexPath

    init?(cell: Cell?, indexPath: IndexPath) {
        guard let cell else {
            return nil
        }

        self.cell = cell
        self.indexPath = indexPath
    }
}

extension UITableView {

    public func tapRow(withLabel label: String, inSection section: Int = 0) {
        let cell = firstIndexedCell(ofType: UITableViewCell.self, withLabel: label, inSection: section)!

        tapRow(at: cell.indexPath)
    }

    public func tapRow(at indexPath: IndexPath) {
        delegate?.tableView?(self, didSelectRowAt: indexPath)
    }

    public func allSectionHeaderViews<Header: UIView>(ofType sectionHeaderType: Header.Type) -> [Header?] {
        let numberOfSections = dataSource?.numberOfSections?(in: self) ?? 0

        return (0..<numberOfSections).map { section in
            delegate?.tableView?(self, viewForHeaderInSection: section) as? Header
        }
    }

    public func allIndexedCells<Cell: UITableViewCell>(
        ofType cellType: Cell.Type,
        inSection section: Int
    ) -> [IndexedCell<Cell>] {
        let numberOfSections = dataSource?.numberOfSections?(in: self) ?? 0
        guard section < numberOfSections else {
            return []
        }

        let rows = dataSource?.tableView(self, numberOfRowsInSection: section) ?? 0

        return (0..<rows)
            .compactMap { row in
                    .init(
                        cell: cell(Cell.self, atRow: row, inSection: section),
                        indexPath: .init(row: row, section: section)
                    )
            }
    }

    public func allCells<Cell: UITableViewCell>(ofType cellType: Cell.Type, inSection section: Int) -> [Cell] {
        allIndexedCells(ofType: cellType, inSection: section).map(\.cell)
    }

    public func cell<Cell: UITableViewCell>(
        _ cellType: Cell.Type,
        atRow row: Int,
        inSection section: Int = 0
    ) -> Cell? {
        dataSource?.tableView(self, cellForRowAt: IndexPath(row: row, section: section)) as? Cell
    }

    public func firstVisibleCell<Cell: UITableViewCell>(
        ofType cellTYpe: Cell.Type,
        withLabel text: String
    ) -> Cell? {
        return visibleCells
            .compactMap { $0 as? Cell }
            .first(where: { $0.find(for: text, by: \UILabel.text) != nil })
    }

    // MARK: - Private

    private func firstIndexedCell<Cell: UITableViewCell>(
        ofType cellType: Cell.Type,
        withLabel text: String,
        inSection section: Int = 0
    ) -> IndexedCell<Cell>? {
        allIndexedCells(ofType: cellType, inSection: section)
            .first { indexedCell in indexedCell.cell.find(for: text, by: \UILabel.text) != nil }
    }

}
