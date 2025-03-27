//
//  SettingsDeviceViewController.swift
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

import LifetimeTracker
import MBProgressHUD
import ProtonCoreUIFoundations
import UIKit

class SettingsDeviceViewController: ProtonMailTableViewController, LifetimeTrackable {
    class var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }

    enum Key {
        static let headerCell = "header_cell"
        static let footerCell = "footer_cell"
        static let headerCellHeight: CGFloat = 52.0
    }

    private let viewModel: SettingsDeviceViewModel
    private weak var coordinator: SettingsDeviceCoordinator?

    var cleaning: Bool = false

    init(viewModel: SettingsDeviceViewModel, coordinator: SettingsDeviceCoordinator) {
        self.viewModel = viewModel
        self.coordinator = coordinator

        super.init(style: .grouped)
        trackLifetime()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        emptyBackButtonTitleForNextView()

        self.updateTitle()

        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.footerCell)
        self.tableView.register(SettingsGeneralCell.self)
        self.tableView.register(SettingsButtonCell.self)
        self.tableView.register(SettingsAccountCell.self)
        self.tableView.register(SwitchTableViewCell.self)

            NotificationCenter.default.addObserver(self, selector: #selector(updateNotificationStatus), name: UIScene.willEnterForegroundNotification, object: nil)

        self.view.backgroundColor = ColorProvider.BackgroundSecondary

        let closeBtn = UIBarButtonItem(
            image: IconProvider.cross,
            style: .plain,
            target: self,
            action: #selector(self.close)
        )
        closeBtn.accessibilityLabel = LocalString._general_close_action
        navigationItem.leftBarButtonItem = closeBtn
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func updateTitle() {
        self.title = LocalString._menu_settings_title
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)

        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .layoutChanged,
                                 argument: self.navigationController?.view)
        }

        self.tableView.reloadData()
    }

    @objc
    private func close() {
        dismiss(animated: true)
    }

    @objc private func updateNotificationStatus(_: NSNotification) {
        if let section = self.viewModel.sections.firstIndex(of: .general),
           let row = self.viewModel.generalSettings.firstIndex(of: .notification) {
            let indexPath = IndexPath(row: row, section: section)
            self.tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }

    private func cleanCache() {
        if !cleaning {
            cleaning = true
            let nview = self.navigationController?.view ?? UIView()
            let hud: MBProgressHUD = MBProgressHUD.showAdded(to: nview, animated: true)
            hud.label.text = LocalString._settings_resetting_cache
            hud.removeFromSuperViewOnHide = true

            self.viewModel.cleanCache { result in
                self.cleaning = false

                switch result {
                case .failure(let error):
                    hud.hide(animated: true, afterDelay: 0)
                    error.alertToast()
                case .success:
                    hud.mode = MBProgressHUDMode.text
                    hud.label.text = LocalString._general_done_button
                    hud.hide(animated: true, afterDelay: 1)
                }
            }
        }
    }
}

// MARK: - table view delegate

extension SettingsDeviceViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.viewModel.sections.count > section {
            switch self.viewModel.sections[section] {
            case .account:
                return self.viewModel.accountSettings.count
            case .app:
                return self.viewModel.appSettings.count
            case .general:
                return self.viewModel.generalSettings.count
            case .clearCache, .induceSlowdown:
                return 1
            }
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        let eSection = self.viewModel.sections[section]

        switch eSection {
        case .account:
            let item = self.viewModel.accountSettings[row]
            switch item {
            case .account:
                let cell = tableView.dequeueReusableCell(withIdentifier: SettingsAccountCell.CellID, for: indexPath)
                if let settingsAccountCell = cell as? SettingsAccountCell {
                    settingsAccountCell.configure(name: self.viewModel.name, email: self.viewModel.email)
                }
                return cell
            case .scan_qr_code:
                let cell = tableView.dequeueReusableCell(withIdentifier: SettingsGeneralCell.CellID, for: indexPath)
                if let settingsGeneralCell = cell as? SettingsGeneralCell {
                    // TODO: Localize and move to the view model
                    settingsGeneralCell.configure(left: "Sign in to another device")
                }
                return cell
            }

        case .app:
            let item = self.viewModel.appSettings[row]

            let cell = tableView.dequeueReusableCell(withIdentifier: SettingsGeneralCell.CellID, for: indexPath)
            if let settingsGeneralCell = cell as? SettingsGeneralCell {
                settingsGeneralCell.configure(left: item.description)
                switch item {
                case .darkMode:
                    let status = traitCollection.userInterfaceStyle == .dark
                    let title = status ? LocalString._settings_On_title : LocalString._settings_Off_title
                    settingsGeneralCell.configure(right: title)
                case .appPIN:
                    let status = self.viewModel.lockOn ? LocalString._settings_On_title : LocalString._settings_Off_title
                    settingsGeneralCell.configure(left: viewModel.appPINTitle)
                    settingsGeneralCell.configure(right: status)
                case .combineContacts:
                    let status = self.viewModel.combineContactOn ? LocalString._settings_On_title : LocalString._settings_Off_title
                    settingsGeneralCell.configure(right: status)
                case .browser:
                    let browser = viewModel.browser
                    settingsGeneralCell.configure(left: item.description)
                    settingsGeneralCell.configure(right: browser.isInstalled ? browser.title : LinkOpener.safari.title)
                case .swipeAction:
                    settingsGeneralCell.configure(left: item.description)
                case .alternativeRouting:
                    settingsGeneralCell.configure(left: item.description)
                    let status = self.viewModel.isDohOn ? LocalString._settings_On_title : LocalString._settings_Off_title
                    settingsGeneralCell.configure(right: status)
                case .contacts:
                    settingsGeneralCell.configure(left: item.description)
                case .toolbar:
                    settingsGeneralCell.configure(left: item.description)
                case .messageSwipeNavigation:
                    settingsGeneralCell.configure(left: item.description)
                    let status = viewModel.isMessageSwipeEnabled ? LocalString._settings_On_title : LocalString._settings_Off_title
                    settingsGeneralCell.configure(right: status)
                case .applicationLogs:
                    settingsGeneralCell.configure(left: item.description)
                }
            }
            return cell
        case .general:
            let item = self.viewModel.generalSettings[row]

            let cell = tableView.dequeueReusableCell(withIdentifier: SettingsGeneralCell.CellID, for: indexPath)
            if let cellToConfig = cell as? SettingsGeneralCell {
                cellToConfig.configure(left: item.description, imageType: .system)
                switch item {
                case .notification:
                    let current = UNUserNotificationCenter.current()
                    current.getNotificationSettings(completionHandler: { settings in
                        switch settings.authorizationStatus {
                        case .notDetermined:
                            { cellToConfig.configure(right: LocalString._settings_Off_title) } ~> .main
                        case .denied: // Notification permission was previously denied, go to settings & privacy to re-enable
                            { cellToConfig.configure(right: LocalString._settings_Off_title, imageType: .system) } ~> .main
                        case .authorized: { cellToConfig.configure(right: LocalString._settings_On_title, imageType: .system) } ~> .main
                        default:
                            break
                        }
                    })
                case .language:
                    let languageCode = LanguageManager().currentLanguageCode()
                    let locale = Locale.autoupdatingCurrent
                    if let userFriendlyLanguageName = locale.localizedString(forIdentifier: languageCode) {
                        cellToConfig.configure(right: userFriendlyLanguageName.capitalized, imageType: .system)
                    } else {
                        PMAssertionFailure("Locale \(locale.identifier) has no localized string for \(languageCode)")
                    }
                }
            }
            return cell
        case .clearCache, .induceSlowdown:
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingsButtonCell.CellID, for: indexPath)
            if let cellToConfig = cell as? SettingsButtonCell {
                cellToConfig.configue(title: eSection.description)
            }
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let eSection = self.viewModel.sections[section]
        guard !eSection.description.isEmpty else {
            return UIView()
        }

        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: Key.headerCell)
        header?.contentView.subviews.forEach { $0.removeFromSuperview() }

        if let headerCell = header {
            let textLabel = UILabel()
            textLabel.set(text: eSection.description,
                          preferredFont: .subheadline,
                          textColor: ColorProvider.TextWeak)
            textLabel.translatesAutoresizingMaskIntoConstraints = false
            textLabel.setContentCompressionResistancePriority(.required, for: .vertical)

            headerCell.contentView.addSubview(textLabel)
            let contentView = headerCell.contentView

            NSLayoutConstraint.activate([
                textLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
                textLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
                textLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
                textLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -8)
            ])
        }
        return header
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.viewModel.sections[section] == .clearCache {
            return 20.0
        }
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return Key.headerCellHeight
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        let eSection = viewModel.sections[section]
        switch eSection {
        case .account:
            let item = viewModel.accountSettings[row]
            switch item {
            case .account:
                coordinator?.go(to: .accountSetting)
            case .scan_qr_code:
                coordinator?.go(to: .scanQRCode)
            }

        case .app:
            let item = viewModel.appSettings[row]
            switch item {
            case .darkMode:
                coordinator?.go(to: .darkMode)
            case .appPIN:
                coordinator?.go(to: .autoLock)
            case .combineContacts:
                coordinator?.go(to: .combineContact)
            case .browser:
                let browsers = LinkOpener.allCases.filter {
                    $0.isInstalled
                }.compactMap { app in
                    UIAlertAction(title: app.title, style: .default) { [weak self] _ in
                        self?.viewModel.browser = app
                        self?.tableView?.reloadRows(at: [indexPath], with: .fade)
                    }
                }
                let alert = UIAlertController(title: nil, message: LocalString._settings_browser_disclaimer, preferredStyle: .actionSheet)
                if let cell = tableView.cellForRow(at: indexPath) {
                    alert.popoverPresentationController?.sourceView = cell
                    alert.popoverPresentationController?.sourceRect = cell.bounds
                }
                browsers.forEach(alert.addAction)
                alert.addAction(.init(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            case .alternativeRouting:
                coordinator?.go(to: .alternativeRouting)
            case .contacts:
                coordinator?.go(to: .contactsSettings)
            case .swipeAction:
                coordinator?.go(to: .swipeAction)
            case .toolbar:
                coordinator?.openToolbarCustomizationView()
            case .messageSwipeNavigation:
                coordinator?.go(to: .messageSwipeNavigation)
            case .applicationLogs:
                coordinator?.openApplicationLogsView()
            }
        case .general:
            let item = viewModel.generalSettings[row]
            switch item {
            case .notification:
                let current = UNUserNotificationCenter.current()
                current.getNotificationSettings { settings in
                    switch settings.authorizationStatus {
                    case .notDetermined:
                        self.viewModel.requestNotificationAuthorizationPermission {
                            self.tableView.reloadRows(at: [indexPath], with: .none)
                        }
                    default:
                        DispatchQueue.main.async {
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        }
                    }
                }
            case .language:
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
        case .clearCache:
            cleanCache()
        case .induceSlowdown:
            viewModel.induceSlowdown()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let item = self.viewModel.sections[section]
        let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: Key.headerCell)
        footer?.contentView.subviews.forEach { $0.removeFromSuperview() }

        var description: String?
        switch item {
        case .clearCache:
            description = "App version: \(self.viewModel.appVersion())"
        default:
            return UIView()
        }

        if let headerCell = footer {
            let textLabel = UILabel()
            textLabel.isUserInteractionEnabled = true
            textLabel.numberOfLines = 0
            textLabel.translatesAutoresizingMaskIntoConstraints = false
            textLabel.set(text: description,
                          preferredFont: .footnote,
                          textColor: ColorProvider.TextWeak)
            textLabel.textAlignment = .center
            headerCell.contentView.addSubview(textLabel)

            NSLayoutConstraint.activate([
                textLabel.topAnchor.constraint(equalTo: headerCell.contentView.topAnchor, constant: 16),
                textLabel.bottomAnchor.constraint(equalTo: headerCell.contentView.bottomAnchor, constant: -8),
                textLabel.leftAnchor.constraint(equalTo: headerCell.contentView.leftAnchor, constant: 16),
                textLabel.rightAnchor.constraint(equalTo: headerCell.contentView.rightAnchor, constant: -16)
            ])
        }
        return footer
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if viewModel.sections[section] == .clearCache {
            return UITableView.automaticDimension
        } else {
            return CGFloat.leastNormalMagnitude
        }
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return 44.0
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}
