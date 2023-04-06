//
//  SettingsLockViewController.swift
//  Proton Mail - Created on 3/17/15.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_Foundations
import ProtonCore_UIFoundations
import UIKit

class SettingsLockViewController: UITableViewController, AccessibleView {
    private let viewModel: SettingsLockViewModelProtocol

    private enum Layout {
        static let headerCellHeight: CGFloat = 52.0
        static let cellHeight: CGFloat = 48.0
    }

    init(viewModel: SettingsLockViewModelProtocol) {
        self.viewModel = viewModel
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewModel.output.setUIDelegate(self)
    }

    private func setupUI() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        view.backgroundColor = ColorProvider.BackgroundSecondary
        updateTitle()
        setupTableView()
        generateAccessibilityIdentifiers()
    }

    private func updateTitle() {
        let str: String
        switch viewModel.output.biometricType {
        case .faceID:
            str = LocalString._app_pin_with_faceid
        case .touchID:
            str = LocalString._app_pin_with_touchid
        default:
            str = LocalString._app_pin
        }
        title = str
    }

    private func setupTableView() {
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = Layout.headerCellHeight
        tableView.estimatedRowHeight = Layout.cellHeight
        tableView.separatorInset = .zero
        tableView.register(viewType: UITableViewHeaderFooterView.self)
        tableView.register(SettingsGeneralCell.self)
        tableView.register(cellType: UITableViewCell.self)
        tableView.register(SwitchTableViewCell.self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.input.viewWillAppear()
    }

    private func showAutoLockTimePicker(from tableView: UITableView, indexPath: IndexPath) {
        let alertController = UIAlertController(
            title: LocalString._settings_auto_lock_time,
            message: nil,
            preferredStyle: .actionSheet
        )
        let cancelAction = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        viewModel
            .output
            .autoLockTimeOptions.forEach { time in
                let text = autoLockTimeValueToString(value: time)
                let action = UIAlertAction(title: text, style: .default, handler: { [weak self] _ -> Void in
                    self?.viewModel.input.didPickAutoLockTime(value: time)
                    self?.tableView.reloadRows(at: [indexPath], with: .fade)
                })
                alertController.addAction(action)
            }

        let sourceView: UIView
        let sourceRect: CGRect
        if let cell = tableView.cellForRow(at: indexPath) {
            sourceView = cell
            sourceRect = cell.bounds
        } else {
            sourceView = view
            sourceRect = view.frame
        }
        alertController.popoverPresentationController?.sourceView = sourceView
        alertController.popoverPresentationController?.sourceRect = sourceRect
        present(alertController, animated: true, completion: nil)
    }

    private func autoLockTimeValueToString(value: Int) -> String {
        let text: String
        if value == -1 {
            text = LocalString._general_none
        } else if value == 0 {
            text = LocalString._settings_every_time_enter_app
        } else {
            text = String(format: LocalString._settings_auto_lock_minutes, value)
        }
        return text
    }

    private func showAppKeyDisclaimer(for appKeySwitch: UISwitch) {
        let alert = UIAlertController(
            title: L11n.SettingsLockScreen.appKeyDisclaimerTitle,
            message: L11n.SettingsLockScreen.appKeyDisclaimer,
            preferredStyle: .alert
        )
        let proceed = UIAlertAction(title: LocalString._genernal_continue, style: .default) { [weak self] _ in
            self?.viewModel.input.didChangeAppKeyValue(isNewStatusEnabled: true)
        }
        let cancel = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel) { _ in
            appKeySwitch.setOn(false, animated: true)
        }
        [proceed, cancel].forEach(alert.addAction)
        present(alert, animated: true, completion: nil)
    }

    private func titleForBiometricType() -> String {
        switch viewModel.output.biometricType {
        case .faceID:
            return LocalString._security_protection_title_faceid
        case .touchID:
            return LocalString._security_protection_title_touchid
        default:
            return ""
        }
    }

    private func cellForProtectionSection(at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellType: UITableViewCell.self)
        cell.tintColor = ColorProvider.BrandNorm
        let protectionType = viewModel.output.protectionItems[indexPath.row]
        switch protectionType {
        case .none:
            cell.accessoryType = viewModel.output.isProtectionEnabled ? .none : .checkmark
            cell.accessibilityIdentifier = "SettingsLockView.nonCell"
        case .pinCode:
            cell.accessoryType = viewModel.output.isPinCodeEnabled ? .checkmark : .none
            cell.accessibilityIdentifier = "SettingsLockView.pinCodeCell"
        case .biometric:
            cell.accessoryType = viewModel.output.isBiometricEnabled ? .checkmark : .none
            cell.accessibilityIdentifier = "SettingsLockView.faceIdCell"
        }

        let title = protectionType == .biometric ? titleForBiometricType() : protectionType.description
        cell.textLabel?.set(text: title, preferredFont: .body)
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.textLabel?.translatesAutoresizingMaskIntoConstraints = false
        cell.textLabel?.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor).isActive = true
        cell.textLabel?.leadingAnchor
            .constraint(equalTo: cell.contentView.leadingAnchor, constant: 16.0).isActive = true
        return cell
    }

    private func cellForChangePinCodeSection() -> UITableViewCell {
        let cell = tableView.dequeue(cellType: UITableViewCell.self)
        cell.textLabel?.set(
            text: LocalString._settings_change_pin_code_title,
            preferredFont: .body,
            textColor: ColorProvider.InteractionNorm
        )
        return cell
    }

    private func cellForAutoLockTimeSection() -> UITableViewCell {
        let cell = tableView.dequeue(cellType: SettingsGeneralCell.self)
        let time = autoLockTimeValueToString(value: userCachedStatus.lockTime.rawValue)
        cell.configureCell(left: LocalString._timing, right: time, imageType: .arrow)
        return cell
    }

    private func cellForAppKeySection() -> UITableViewCell {
        let cell = tableView.dequeue(cellType: SwitchTableViewCell.self)
        cell.configCell(
            L11n.SettingsLockScreen.appKeyProtection,
            isOn: viewModel.output.isAppKeyEnabled
        ) { [weak self] isNewValueEnabled, feedback in
            if isNewValueEnabled {
                self?.showAppKeyDisclaimer(for: cell.switchView)
            } else {
                self?.viewModel.input.didChangeAppKeyValue(isNewStatusEnabled: false)
            }
            feedback(true)
        }
        cell.switchView.accessibilityIdentifier = "SettingsLockView.appKeySwitch"
        return cell
    }
}

extension SettingsLockViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.output.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < viewModel.output.sections.count else { return 0 }
        switch viewModel.output.sections[section] {
        case .protection:
            return viewModel.output.protectionItems.count
        case .changePin, .autoLockTime, .appKeyProtection:
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableSection = viewModel.output.sections[indexPath.section]
        switch tableSection {
        case .protection:
            return cellForProtectionSection(at: indexPath)
        case .changePin:
            return cellForChangePinCodeSection()
        case .autoLockTime:
            return cellForAutoLockTimeSection()
        case .appKeyProtection:
            return cellForAppKeySection()
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let tableSection = viewModel.output.sections[section]
        guard !tableSection.description.isEmpty else {
            return nil
        }

        let headerCell = tableView.dequeue(viewType: UITableViewHeaderFooterView.self)
        headerCell.contentView.subviews.forEach { $0.removeFromSuperview() }
        let textLabel = UILabel()
        textLabel.set(text: tableSection.description, preferredFont: .subheadline)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.numberOfLines = 0
        headerCell.contentView.addSubview(textLabel)
        [
            textLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
            textLabel.topAnchor.constraint(equalTo: headerCell.contentView.topAnchor, constant: 24.0),
            textLabel.leadingAnchor.constraint(equalTo: headerCell.contentView.leadingAnchor, constant: 16.0),
            textLabel.trailingAnchor.constraint(equalTo: headerCell.contentView.trailingAnchor, constant: -16.0),
            textLabel.bottomAnchor.constraint(equalTo: headerCell.contentView.bottomAnchor, constant: -8.0)
        ].activate()
        return headerCell
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let section = viewModel.output.sections[section]
        guard section.hasFooter else { return nil }
        let footerCell = tableView.dequeue(viewType: UITableViewHeaderFooterView.self)
        configFooterCell(footerCell, for: section)
        return footerCell
    }

    private func configFooterCell(_ footerCell: UITableViewHeaderFooterView, for section: SettingLockSection) {
        footerCell.contentView.subviews.forEach { $0.removeFromSuperview() }

        switch section {
        case .appKeyProtection:
            let textView = SubviewFactory.appKeyProtectionTextView
            footerCell.contentView.addSubview(textView)
            [
                textView.topAnchor.constraint(equalTo: footerCell.contentView.topAnchor, constant: 8),
                textView.leftAnchor.constraint(equalTo: footerCell.contentView.leftAnchor, constant: 12)
            ].activate()
            textView.centerInSuperview()
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch viewModel.output.sections[indexPath.section] {
        case .protection:
            switch viewModel.output.protectionItems[indexPath.row] {
            case .none:
                viewModel.input.didTapNoProtection()
            case .pinCode:
                viewModel.input.didTapPinProtection()
            case .biometric:
                viewModel.input.didTapBiometricProtection()
            }
        case .changePin:
            viewModel.input.didTapChangePinCode()
        case .autoLockTime:
            showAutoLockTimePicker(from: tableView, indexPath: indexPath)
        case .appKeyProtection:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch viewModel.output.sections[indexPath.section] {
        case .protection, .changePin:
            return Layout.cellHeight
        default:
            return UITableView.automaticDimension
        }
    }
}

extension SettingsLockViewController: SettingsLockUIProtocol {

    func reloadData() {
        tableView.reloadData()
    }
}

extension SettingsLockViewController {

    private enum SubviewFactory {

        static var appKeyProtectionTextView: UITextView {
            let textView = UITextView()
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.isScrollEnabled = false
            textView.isEditable = false
            textView.backgroundColor = .clear
            textView.font = .preferredFont(forTextStyle: .footnote)

            let learnMore = LocalString._learn_more
            let text = String.localizedStringWithFormat(L11n.SettingsLockScreen.appKeyProtectionDescription, learnMore)
            let attributes = FontManager.CaptionWeak.lineBreakMode(.byWordWrapping)
            let attributedString = NSMutableAttributedString(string: text, attributes: attributes)
            if let subrange = text.range(of: learnMore) {
                let nsRange = NSRange(subrange, in: text)
                attributedString.addAttribute(.link, value: Link.LearnMore.appKeyProtection, range: nsRange)
                textView.linkTextAttributes = [.foregroundColor: ColorProvider.InteractionNorm as UIColor]
            }
            textView.attributedText = attributedString
            return textView
        }
    }
}

private extension SettingLockSection {
    var hasFooter: Bool {
        self == .appKeyProtection
    }

    var description: String {
        switch self {
        case .protection:
            let title = "\n\n\(L11n.SettingsLockScreen.protectionTitle)"
            return LocalString._lock_wipe_desc + title
        case .appKeyProtection:
            return L11n.SettingsLockScreen.advancedSettings
        case .autoLockTime:
            return LocalString._timing
        default:
            return ""
        }
    }
}

private extension ProtectionType {
    var description: String {
        switch self {
        case .none:
            return LocalString._security_protection_title_none
        case .pinCode:
            return LocalString._security_protection_title_pin
        case .biometric:
            return LocalString._security_protection_title_faceid
        }
    }
}
