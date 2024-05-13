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

import ProtonCoreUIFoundations
import UIKit

final class ContactsSettingsViewController: ProtonMailTableViewController {
    private let viewModel: ContactsSettingsViewModelProtocol

    init(viewModel: ContactsSettingsViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }

    private func setUpUI() {
        navigationItem.title = LocalString._menu_contacts_title
        setupTableView()
    }

    private func setupTableView() {
        tableView.backgroundColor = ColorProvider.BackgroundSecondary
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.register(SwitchTableViewCell.self)
        tableView.separatorStyle = .none
        tableView.contentInset.top = 16.0
    }
}

extension ContactsSettingsViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.output.settings.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellType: SwitchTableViewCell.self)
        guard let setting = viewModel.output.settings[safeIndex: indexPath.section] else {
            return cell
        }
        cell.configCell(setting.title, isOn: viewModel.output.value(for: setting) ) { [weak self] newStatus, _ in
            guard let self else { return }
            if setting == .autoImportContacts && newStatus == true {
                enableAutoImportContacts(autoImportSwitch: cell.switchView)
            } else {
                self.viewModel.input.didTapSetting(setting, isEnabled: newStatus)
            }
        }
        return cell
    }

    private func enableAutoImportContacts(autoImportSwitch: UISwitch) {
        requestContactsAccess { [weak self] accessGranted in
            guard accessGranted else {
                DispatchQueue.main.async {
                    autoImportSwitch.setOn(false, animated: true)
                }
                return
            }
            self?.didEnableAutoImport()
        }
    }

    private func requestContactsAccess(completion: @escaping (_ accessGranted: Bool) -> Void) {
        if viewModel.output.isContactAccessDenied {
            informContactAccessIsDenied {
                completion(false)
            }
        } else {
            viewModel.input.requestContactAuthorization { hasAccess, accessError in
                guard hasAccess else {
                    let errorMessage = accessError?.localizedDescription ?? "contacts access denied"
                    SystemLogger.log(message: errorMessage, category: .contacts, isError: true)
                    completion(false)
                    return
                }
                completion(true)

            }
        }
    }

    private func informContactAccessIsDenied(completion: @escaping () -> Void) {
        let alert = UIAlertController.makeContactAccessDeniedAlert(completion: completion)
        present(alert, animated: true, completion: nil)
    }

    private func didEnableAutoImport() {
        let alert = UIAlertController(
            title: L10n.SettingsContacts.autoImportAlertTitle,
            message: L10n.SettingsContacts.autoImportAlertMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: LocalString._general_ok_action, style: .default) { [weak self] _ in
            self?.viewModel.input.didTapSetting(.autoImportContacts, isEnabled: true)
        })
        DispatchQueue.main.async { [weak self] in
            self?.present(alert, animated: true, completion: nil)
        }
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let setting = viewModel.output.settings[safeIndex: section] else {
            return nil
        }
        return footer(for: setting)
    }

    private func footer(for setting: ContactsSettingsViewModel.Setting) -> UIView {
        let textLabel = UILabel()
        textLabel.set(text: setting.footer, preferredFont: .subheadline, textColor: ColorProvider.TextWeak)
        textLabel.numberOfLines = 0

        let footerView = UITableViewHeaderFooterView()
        footerView.contentView.backgroundColor = ColorProvider.BackgroundSecondary
        footerView.contentView.addSubview(textLabel)
        [
            textLabel.topAnchor.constraint(equalTo: footerView.contentView.topAnchor, constant: 12),
            textLabel.bottomAnchor.constraint(equalTo: footerView.contentView.bottomAnchor, constant: -16),
            textLabel.leadingAnchor.constraint(equalTo: footerView.contentView.leadingAnchor, constant: 16),
            textLabel.trailingAnchor.constraint(equalTo: footerView.contentView.trailingAnchor, constant: -16)
        ].activate()
        return footerView
    }
}
