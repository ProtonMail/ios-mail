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
import SwiftUI
import proton_app_uniffi

typealias ContactItemAction = (ContactItemType) -> Void

final class ContactsController: UITableViewController {
    var groupedContacts: [GroupedContacts] {
        didSet {
            if oldValue != groupedContacts {
                setUpEmptyState(with: groupedContacts)
                tableView.reloadData()
            }
        }
    }

    init(
        contacts: [GroupedContacts],
        onDeleteItem: @escaping ContactItemAction,
        onTapItem: @escaping ContactItemAction
    ) {
        self.groupedContacts = contacts
        self.onDeleteItem = onDeleteItem
        self.onTapItem = onTapItem
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        groupedContacts.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groupedContacts[section].items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = groupedContacts[indexPath.section]
        let contactType = section.items[indexPath.row]

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

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = groupedContacts[indexPath.section]
        let contactItem = section.items[indexPath.row]

        onTapItem(contactItem)
    }

    override func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let section = groupedContacts[indexPath.section]
        let item = section.items[indexPath.row]

        let deleteAction = UIContextualAction(
            style: .destructive,
            title: nil
        ) { [weak self] _, _, completionHandler in
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            self?.onDeleteItem(item)
            completionHandler(true)
        }
        deleteAction.backgroundColor = UIColor(DS.Color.Notification.error)
        deleteAction.image = UIImage(resource: DS.Icon.icTrash)

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    // MARK: - Private

    private let onDeleteItem: ContactItemAction
    private let onTapItem: ContactItemAction

    private func setUpTableView() {
        tableView.backgroundColor = UIColor(DS.Color.BackgroundInverted.norm)
        tableView.directionalLayoutMargins = .init(vertical: .zero, horizontal: DS.Spacing.large)
        tableView.sectionFooterHeight = .zero
        tableView.sectionHeaderHeight = DS.Spacing.large
        tableView.sectionIndexColor = UIColor(DS.Color.Text.accent)
        tableView.separatorColor = UIColor(DS.Color.Border.norm)
        tableView.separatorInset = .zero
        tableView.registerCell(ContactCell.self)
        tableView.registerCell(ContactGroupCell.self)
        setUpEmptyState(with: groupedContacts)
    }

    private func setUpEmptyState(with contacts: [GroupedContacts]) {
        tableView.backgroundView = contacts.isEmpty ? NoContactsPlaceholderView() : nil
    }
}
