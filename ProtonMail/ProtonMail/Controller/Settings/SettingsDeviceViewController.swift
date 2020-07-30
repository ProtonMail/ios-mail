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
import PMKeymaker

class SettingsDeviceViewController: ProtonMailTableViewController, ViewModelProtocol, CoordinatedNew {
    struct Key {
        static let headerCell : String        = "header_cell"
        static let headerCellHeight : CGFloat = 36.0
    }
    
    internal var viewModel : SettingsDeviceViewModel!
    internal var coordinator : SettingsDeviceCoordinator?
    
    
    let SwitchTwolineCell             = "switch_two_line_cell"
    
    ///
    var cleaning : Bool      = false
    
    ///
    func set(viewModel: SettingsDeviceViewModel) {
        self.viewModel = viewModel
    }
    
    func set(coordinator: SettingsDeviceCoordinator) {
        self.coordinator = coordinator
    }
    
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
    
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateTitle()
        
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)
        self.tableView.register(SettingsGeneralCell.self)
        self.tableView.register(SettingsTwoLinesCell.self)
        self.tableView.register(GeneralSettingActionCell.self)
        
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(updateNotificationStatus), name: UIScene.willEnterForegroundNotification, object: nil)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(updateNotificationStatus), name: UIApplication.willEnterForegroundNotification, object: nil)
        }
        
        self.tableView.estimatedRowHeight = 50.0
        self.tableView.rowHeight = UITableView.automaticDimension
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
        
        self.tableView.reloadData()
    }
    
    private func inAppLanguage(_ indexPath: IndexPath) {
        let current_language = LanguageManager.currentLanguageEnum()
        let title = LocalString._settings_current_language_is + current_language.nativeDescription
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        for l in self.viewModel.languages {
            if l != current_language {
                alertController.addAction(UIAlertAction(title: l.nativeDescription, style: .default, handler: { (action) -> Void in
                    let _ = self.navigationController?.popViewController(animated: true)
                    LanguageManager.saveLanguage(byCode: l.code)
                    LocalizedString.reset()
                    self.updateTitle()
                    self.tableView.reloadData()
                }))
            }
        }
        let cell = tableView.cellForRow(at: indexPath)
        alertController.popoverPresentationController?.sourceView = cell ?? self.view
        alertController.popoverPresentationController?.sourceRect = (cell == nil ? self.view.frame : cell!.bounds)
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func updateNotificationStatus(_ notification: NSNotification) {
        if let section = self.viewModel.sections.firstIndex(of: .app),
            let row = self.viewModel.appSettigns.firstIndex(of: .push) {
            let indexPath = IndexPath(row: row, section: section)
            self.tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }
    
    private func cleanCache() {
        if !cleaning {
            cleaning = true
            let nview = self.navigationController?.view ?? UIView()
            let hud : MBProgressHUD = MBProgressHUD.showAdded(to: nview, animated: true)
            hud.label.text = LocalString._settings_resetting_cache
            hud.removeFromSuperViewOnHide = true
            self.viewModel.userManager.messageService.cleanLocalMessageCache() { task, res, error in
                self.cleaning = false
                if let error = error {
                    hud.hide(animated: true, afterDelay: 0)
                    let alert = error.alertController()
                    alert.addOKAction()
                    self.present(alert, animated: true, completion: nil)
                } else {
                    hud.mode = MBProgressHUDMode.text
                    hud.label.text = LocalString._general_done_button
                    hud.hide(animated: true, afterDelay: 1)
                }
            }
        }
    }
}

//MARK: - table view delegate
extension SettingsDeviceViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.sections.count
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.viewModel.sections.count > section {
            switch( self.viewModel.sections[section]) {
            case .account:
                return 1
            case .app:
                return self.viewModel.appSettigns.count
            case .info:
                return 1
            case .network:
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
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTwoLinesCell.CellID, for: indexPath)
            cell.accessoryType = .disclosureIndicator
            if let c = cell as? SettingsTwoLinesCell {
                c.config(top: self.viewModel.name, bottom: self.viewModel.email)
            }
            return cell
        case .app:
            let item = self.viewModel.appSettigns[row]
            
            if item == .cleanCache {
                if let cell = tableView.dequeueReusableCell(withIdentifier: GeneralSettingActionCell.CellID, for: indexPath) as? GeneralSettingActionCell {
                    cell.configCell(left: item.description, action: LocalString._empty_cache) { [weak self] in
                        self?.cleanCache()
                    }
                    cell.selectionStyle = .none
                    return cell
                }
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingsGeneralCell.CellID, for: indexPath)
            cell.accessoryType = .disclosureIndicator
            if let c = cell as? SettingsGeneralCell {
                c.config(left: item.description)
                switch item {
                case .push:
                    let current = UNUserNotificationCenter.current()
                    current.getNotificationSettings(completionHandler: { (settings) in
                        if settings.authorizationStatus == .notDetermined {
                            // Notification permission has not been asked yet, go for it!
                            { c.config(right: "off") } ~> .main
                            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
                                guard granted else { return }
                                DispatchQueue.main.async {
                                    UIApplication.shared.registerForRemoteNotifications()
                                    self?.tableView.reloadRows(at: [indexPath], with: .none)
                                }
                            }
                        } else if settings.authorizationStatus == .denied {
                            // Notification permission was previously denied, go to settings & privacy to re-enable
                            { c.config(right: "off") } ~> .main
                        } else if settings.authorizationStatus == .authorized {
                            // Notification permission was already granted
                            { c.config(right: "on") } ~> .main
                        }
                    })
                case .autolock:
                    let status = self.viewModel.lockOn ? "on" : "off"
                    switch UIDevice.current.biometricType {
                    case .none:
                        c.config(left: LocalString._pin)
                    case .touchID:
                        c.config(left: LocalString._pin_and_touch_id)
                    case .faceID:
                        c.config(left: LocalString._pin_and_face_id)
                    }
                    c.config(right: status)
                case .language:
                    let language: ELanguage =  LanguageManager.currentLanguageEnum()
                    c.config(right: language.nativeDescription)
                case .combinContacts:
                    let status = self.viewModel.combineContactOn ? "on" : "off"
                    c.config(right: status)
                case .cleanCache:
//                    c.config(right: LocalString._empty_cache)
                    break
                case .browser:
                    let browser = userCachedStatus.browser
                    c.config(left: item.description)
                    c.config(right: browser.isInstalled ? browser.title : LinkOpener.safari.title)
                }
            }
            return cell
            
        case .network:
            let netItem = self.viewModel.networkItems[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTwolineCell, for: indexPath)
            if netItem == .doh, let c = cell as? SwitchTwolineCell {
                c.accessoryType = UITableViewCell.AccessoryType.none
                c.selectionStyle = UITableViewCell.SelectionStyle.none
                let topline = "Allow alternative routing"
                let holder = "In case Proton sites are blocked, this setting allows the app to try alternative network routing to reach Proton, which can be useful for bypassing firewalls or network issues. We recommend keeping this setting on for greater reliability. %1$@"
                let learnMore = "Learn more"
                
                let full = String.localizedStringWithFormat(holder, learnMore)
                let attributedString = NSMutableAttributedString(string: full,
                                                                 attributes: [.font : UIFont.preferredFont(forTextStyle: .footnote),
                                                                              .foregroundColor : UIColor.darkGray])
                if let subrange = full.range(of: learnMore) {
                    let nsRange = NSRange(subrange, in: full)
                    attributedString.addAttribute(.link,
                                                  value: "http://protonmail.com/blog/anti-censorship-alternative-routing",
                                                  range: nsRange)
                }
                c.configCell(topline, bottomLine: attributedString, showSwitcher: true, status: DoHMail.default.status == .on) { (cell, newStatus, feedback) in
                    if newStatus {
                        DoHMail.default.status = .on
                        userCachedStatus.isDohOn = true
                    } else {
                        DoHMail.default.status = .off
                        userCachedStatus.isDohOn = false
                    }
                }
            }
            return cell
        case .info:
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingsGeneralCell.CellID, for: indexPath)
            cell.accessoryType = .none
            if let c = cell as? SettingsGeneralCell {
                c.config(left: "AppVersion")
                c.config(right: self.viewModel.appVersion())
            }
            return cell
        }
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: Key.headerCell)
        header?.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        if let headerCell = header {
            let textLabel = UILabel()
            
            textLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
            textLabel.adjustsFontForContentSizeCategory = true
            textLabel.textColor = UIColor.ProtonMail.Gray_8E8E8E
            let eSection = self.viewModel.sections[section]
            textLabel.text = eSection.description
            
            headerCell.contentView.addSubview(textLabel)
            
            textLabel.mas_makeConstraints({ (make) in
                let _ = make?.top.equalTo()(headerCell.contentView.mas_top)?.with()?.offset()(8)
                let _ = make?.bottom.equalTo()(headerCell.contentView.mas_bottom)?.with()?.offset()(-8)
                let _ = make?.left.equalTo()(headerCell.contentView.mas_left)?.with()?.offset()(8)
                let _ = make?.right.equalTo()(headerCell.contentView.mas_right)?.with()?.offset()(-8)
            })
        }
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
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
            case .push:
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                            print("Settings opened: \(success)") // Prints true
                        })
                    } else {
                        UIApplication.shared.openURL(settingsUrl as URL)
                    }
                }
            case .autolock:
                self.coordinator?.go(to: .autoLock)
                break
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
            case .combinContacts:
                self.coordinator?.go(to: .combineContact)
                break
            case .cleanCache:
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
            }
        case .info, .network:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.none
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

}

extension SettingsDeviceViewController: Deeplinkable {
    var deeplinkNode: DeepLink.Node {
        return DeepLink.Node(name: String(describing: SettingsTableViewController.self), value: nil)
    }
}
