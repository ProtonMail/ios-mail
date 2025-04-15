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

import InboxCore
import InboxDesignSystem
import UIKit

final class ContactPickerController: UIViewController {

    enum Event {
        case onInputChange(text: String)
        case onContactSelected(contact: ComposerContact)
    }

    private let label = SubviewFactory.title
    private let textField = CursorTextField()
    private let tableView = SubviewFactory.tableView
    private let cellBackgroundView = SubviewFactory.cellBackgroundView
    private let separator = ComposerSeparator()

    private var contacts: [ComposerContact] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    var recipientsFieldState: RecipientFieldState? {
        didSet {
            updateView(oldState: oldValue)
        }
    }

    var onEvent: ((Event) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setUpConstraints()
    }

    private func setUpUI() {
        view.backgroundColor = DS.Color.Background.norm.toDynamicUIColor

        [label, textField, tableView, separator].forEach(view.addSubview)
        textField.onTextChanged = { [weak self] text in
            self?.onEvent?(.onInputChange(text: text ?? .empty))
        }
        tableView.registerCell(ContactPickerCell.self)
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func setUpConstraints() {
        view.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DS.Spacing.large),
            label.centerYAnchor.constraint(equalTo: textField.centerYAnchor),

            textField.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: DS.Spacing.small),
            textField.topAnchor.constraint(equalTo: view.topAnchor, constant: DS.Spacing.standard),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.standard),
            textField.heightAnchor.constraint(equalToConstant: 20),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: DS.Spacing.moderatelyLarge),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: tableView.topAnchor),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
    }

    private func updateView(oldState: RecipientFieldState?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let state = recipientsFieldState else { return }
            label.text = state.group.string
            textField.text = state.input
            view.isHidden = state.controllerState != .contactPicker || state.matchingContacts.isEmpty

            let matchedContactsChanged = oldState?.matchingContacts != state.matchingContacts
            if matchedContactsChanged {
                contacts = state.matchingContacts
                textField.becomeFirstResponder()
            }
        }
    }

    private func isContactAlreadyInTheRecipientList(contact: ComposerContact) -> Bool {
        guard let composerRecipients = recipientsFieldState?.recipients.map(\.composerRecipient) else { return false }
        switch contact.type {
        case .single:
            return !composerRecipients
                .allSingleRecipients()
                .filter { $0.address == contact.singleContact?.email }
                .isEmpty
        case .group:
            return !composerRecipients
                .allGroupRecipients()
                .filter { $0.displayName == contact.groupContact?.name }
                .isEmpty
        }
    }
}

extension ContactPickerController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        contacts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(ContactPickerCell.self)
        let contact = contacts[indexPath.row]
        let isContactAlreadySelected = isContactAlreadyInTheRecipientList(contact: contact)
        cell.configure(uiModel: contact.toUIModel(alreadySelected: isContactAlreadySelected))
        cell.selectedBackgroundView = cellBackgroundView
        return cell
    }
}

extension ContactPickerController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onEvent?(.onContactSelected(contact: contacts[indexPath.row]))
        tableView.cellForRow(at: indexPath)?.setSelected(false, animated: true)
    }
}

extension ContactPickerController {

    private enum SubviewFactory {
        static var title: UILabel {
            ComposerSubviewFactory.fieldTitle
        }

        static var tableView: UITableView {
            let view = UITableView(frame: .zero)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = DS.Color.BackgroundInverted.norm.toDynamicUIColor
            view.directionalLayoutMargins = .init(top: 0, leading: DS.Spacing.large, bottom: 0, trailing: DS.Spacing.large)
            view.separatorColor = DS.Color.Border.norm.toDynamicUIColor
            view.separatorInset = .zero

            let background = UIView()
            background.backgroundColor = DS.Color.Background.norm.toDynamicUIColor
            view.backgroundView = background

            view.estimatedRowHeight = 100.0
            view.rowHeight = UITableView.automaticDimension
            return view
        }

        static var cellBackgroundView: UIView {
            let view = UIView()
            view.backgroundColor = DS.Color.InteractionWeak.pressed.toDynamicUIColor
            return view
        }
    }
}
