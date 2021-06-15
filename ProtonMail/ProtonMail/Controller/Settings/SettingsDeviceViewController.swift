//
//  SettingsDeviceViewController.swift
//  ProtonMail - Created on 3/17/15.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import MBProgressHUD
import ProtonCore_UIFoundations

class SettingsDeviceViewController: ProtonMailTableViewController, ViewModelProtocol, CoordinatedNew {
    struct Key {
        static let headerCell = "header_cell"
        static let footerCell = "footer_cell"
        static let headerCellHeight: CGFloat = 52.0
        static let accountCell = "AccountSwitcherCell"
        static let cellHeight: CGFloat = 48.0
        static let accountCellHeight: CGFloat = 64.0
    }

    internal var viewModel: SettingsDeviceViewModel!
    internal var coordinator: SettingsDeviceCoordinator?

    var cleaning: Bool = false

    func set(viewModel: SettingsDeviceViewModel) {
        self.viewModel = viewModel
    }

    func set(coordinator: SettingsDeviceCoordinator) {
        self.coordinator = coordinator
    }

    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }

    class func instance() -> SettingsDeviceViewController {
        let board = UIStoryboard.Storyboard.settings.storyboard
        let vc = board.instantiateViewController(withIdentifier: "SettingsDeviceViewController") as! SettingsDeviceViewController
        _ = UINavigationController(rootViewController: vc)
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateTitle()

        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.footerCell)
        self.tableView.register(SettingsGeneralCell.self)
        self.tableView.register(SettingsButtonCell.self)
        self.tableView.register(SettingsAccountCell.self)
        self.tableView.register(SwitchTableViewCell.self)

        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(updateNotificationStatus), name: UIScene.willEnterForegroundNotification, object: nil)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(updateNotificationStatus), name: UIApplication.willEnterForegroundNotification, object: nil)
        }

        self.view.backgroundColor = UIColorManager.BackgroundSecondary
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func updateTitle() {
        self.title = LocalString._menu_settings_title
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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

    private func inAppLanguage(_ indexPath: IndexPath) {
        let current_language = LanguageManager.currentLanguageEnum()
        let title = LocalString._settings_current_language_is + current_language.nativeDescription
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        for l in self.viewModel.languages {
            if l != current_language {
                alertController.addAction(UIAlertAction(title: l.nativeDescription, style: .default) { _ in
                    _ = self.navigationController?.popViewController(animated: true)
                    LanguageManager.saveLanguage(byCode: l.code)
                    LocalizedString.reset()
                    self.updateTitle()
                    self.tableView.reloadData()
                })
            }
        }
        let cell = tableView.cellForRow(at: indexPath)
        alertController.popoverPresentationController?.sourceView = cell ?? self.view
        alertController.popoverPresentationController?.sourceRect = (cell == nil ? self.view.frame : cell!.bounds)
        present(alertController, animated: true, completion: nil)
    }

    @objc private func updateNotificationStatus(_ notification: NSNotification) {
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

            self.viewModel.cleanCache { (result) in
                self.cleaning = false

                switch result {
                case .failure(let error):
                    hud.hide(animated: true, afterDelay: 0)
                    let alert = error.alertController()
                    alert.addOKAction()
                    self.present(alert, animated: true, completion: nil)
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
            switch  self.viewModel.sections[section] {
            case .account:
                return 1
            case .app:
                return self.viewModel.appSettigns.count
            case .general:
                return self.viewModel.generalSettings.count
            case .clearCache:
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
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingsAccountCell.CellID, for: indexPath)
            if let settingsAccountCell = cell as? SettingsAccountCell {
                settingsAccountCell.configure(name: self.viewModel.name, email: self.viewModel.email)
            }
            return cell
        case .app:
            let item = self.viewModel.appSettigns[row]

            let cell = tableView.dequeueReusableCell(withIdentifier: SettingsGeneralCell.CellID, for: indexPath)
            if let settingsGeneralCell = cell as? SettingsGeneralCell {
                settingsGeneralCell.configure(left: item.description)
                switch item {
                case .autolock:
                    let status = self.viewModel.lockOn ? LocalString._settings_On_title : LocalString._settings_Off_title
                    settingsGeneralCell.configure(left: LocalString._security)
                    settingsGeneralCell.configure(right: status)
                case .combinContacts:
                    let status = self.viewModel.combineContactOn ? LocalString._settings_On_title : LocalString._settings_Off_title
                    settingsGeneralCell.configure(right: status)
                case .browser:
                    let browser = userCachedStatus.browser
                    settingsGeneralCell.configure(left: item.description)
                    settingsGeneralCell.configure(right: browser.isInstalled ? browser.title : LinkOpener.safari.title)
                case .swipeAction:
                    settingsGeneralCell.configure(left: item.description)
                case .alternativeRouting:
                    settingsGeneralCell.configure(left: item.description)
                    let status = self.viewModel.isDohOn ? LocalString._settings_On_title : LocalString._settings_Off_title
                    settingsGeneralCell.configure(right: status)
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
                    current.getNotificationSettings(completionHandler: { (settings) in
                        switch settings.authorizationStatus {
                        case .notDetermined:// Notification permission has not been asked yet, go for it!
                            { cellToConfig.configure(right: "Off") } ~> .main
                            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
                                guard granted else { return }
                                DispatchQueue.main.async {
                                    UIApplication.shared.registerForRemoteNotifications()
                                    self?.tableView.reloadRows(at: [indexPath], with: .none)
                                }
                            }
                        case .denied:// Notification permission was previously denied, go to settings & privacy to re-enable
                            { cellToConfig.configure(right: "Off", imageType: .system) } ~> .main
                        case .authorized:
                            { cellToConfig.configure(right: "On", imageType: .system) } ~> .main
                        default:
                            break
                        }
                    })
                case .language:
                    let language: ELanguage =  LanguageManager.currentLanguageEnum()
                    cellToConfig.configure(right: language.nativeDescription, imageType: .system)
                }
            }
            return cell
        case .clearCache:
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingsButtonCell.CellID, for: indexPath)
            if let cellToConfig = cell as? SettingsButtonCell {
                cellToConfig.configue(title: LocalString._empty_cache)
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

            var textAttribute = FontManager.DefaultSmallWeak
            textAttribute.addTextAlignment(.left)
            textLabel.attributedText = NSAttributedString(string: eSection.description, attributes: textAttribute)
            textLabel.translatesAutoresizingMaskIntoConstraints = false

            headerCell.contentView.addSubview(textLabel)

            NSLayoutConstraint.activate([
                textLabel.heightAnchor.constraint(equalToConstant: 20.0),
                textLabel.topAnchor.constraint(equalTo: headerCell.topAnchor, constant: 24),
                textLabel.bottomAnchor.constraint(equalTo: headerCell.bottomAnchor, constant: -8),
                textLabel.leftAnchor.constraint(equalTo: headerCell.leftAnchor, constant: 16),
                textLabel.rightAnchor.constraint(equalTo: headerCell.rightAnchor, constant: -8)
            ])
        }
        return header
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.viewModel.sections[section] == .clearCache {
            return 20.0
        }
        return Key.headerCellHeight
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return Key.headerCellHeight
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .account:
            self.coordinator?.go(to: .accountSetting)
        case .app:
            let item = self.viewModel.appSettigns[row]
            switch item {
            case .autolock:
                self.coordinator?.go(to: .autoLock)
                break
            case .combinContacts:
                self.coordinator?.go(to: .combineContact)
                break
            case .browser:
                let browsers = LinkOpener.allCases.filter {
                    $0.isInstalled
                }.compactMap { app in
                    return UIAlertAction(title: app.title, style: .default) { [weak self] _ in
                        userCachedStatus.browser = app
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
                self.present(alert, animated: true, completion: nil)
            case .alternativeRouting:
                self.coordinator?.go(to: .alternativeRouting)
            case .swipeAction:
                self.coordinator?.go(to: .swipeAction)
            }
        case .general:
            let item = self.viewModel.generalSettings[row]
            switch item {
            case .notification:
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }

                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: nil)
                }
            case .language:
                #if targetEnvironment(simulator)
                self.inAppLanguage(indexPath)
                #else
                if #available(iOS 13.0, *) {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                } else {
                    self.inAppLanguage(indexPath)
                }
                #endif
            }
        case .clearCache:
            self.cleanCache()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let item = self.viewModel.sections[section]
        let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: Key.headerCell)
        footer?.contentView.subviews.forEach { $0.removeFromSuperview() }

        var textToAdd: NSAttributedString?
        switch item {
        case .clearCache:
            var textAttribute = FontManager.CaptionWeak
            textAttribute.addTextAlignment(.center)
            let description = "App Version: \(self.viewModel.appVersion())"
            textToAdd = NSAttributedString(string: description, attributes: textAttribute)
        default:
            return UIView()
        }

        if let headerCell = footer {
            let textLabel = UILabel()
            textLabel.isUserInteractionEnabled = true
            textLabel.numberOfLines = 0
            textLabel.attributedText = textToAdd
            textLabel.translatesAutoresizingMaskIntoConstraints = false
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
        if indexPath.section == 0 {
            return Key.accountCellHeight
        } else {
            return Key.cellHeight
        }
    }
}

extension SettingsDeviceViewController: Deeplinkable {
    var deeplinkNode: DeepLink.Node {
        return DeepLink.Node(name: String(describing: SettingsTableViewController.self), value: nil)
    }
}
