// Copyright (c) 2024 Proton Technologies AG
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

import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

final class ContactsController: UITableViewController {

    var groupedContacts: [GroupedContacts] {
        didSet { tableView.reloadData() }
    }

    init(contacts: [GroupedContacts], backgroundColor: Color) {
        self.groupedContacts = contacts
        self.backgroundColor = backgroundColor
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
    }

    // MARK: - UITableViewController

    override func numberOfSections(in tableView: UITableView) -> Int {
        groupedContacts.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groupedContacts[section].item.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = groupedContacts[indexPath.section]
        let contactType = section.item[indexPath.row]

        switch contactType {
        case .contact(let contactItem):
            let contactCell = tableView.dequeueCell(ContactCell.self)
            ContactItemCellPresenter.present(item: contactItem, in: contactCell)
            return contactCell
        case .group(let groupedItem):
            let groupCell = tableView.dequeueCell(ContactGroupCell.self)
            ContactGroupCellPresenter.present(item: groupedItem, in: groupCell)
            return groupCell
        }
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        groupedContacts.map(\.groupedBy)
    }

    // MARK: - Private

    private let backgroundColor: Color

    private func setUpTableView() {
        tableView.backgroundColor = UIColor(backgroundColor)
        tableView.directionalLayoutMargins = .init(vertical: .zero, horizontal: DS.Spacing.large)
        tableView.sectionFooterHeight = .zero
        tableView.sectionHeaderHeight = DS.Spacing.large
        tableView.sectionIndexColor = UIColor(DS.Color.Text.accent)
        tableView.separatorColor = UIColor(DS.Color.Border.norm)
        tableView.separatorInset = .zero
        tableView.registerCell(ContactCell.self)
        tableView.registerCell(ContactGroupCell.self)
    }

}
