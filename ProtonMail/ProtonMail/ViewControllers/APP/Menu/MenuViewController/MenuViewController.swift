//
//  MenuViewController.swift
//  Proton Mail
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

import UIKit
import ProtonCoreAccountSwitcher
import ProtonCoreFoundations
import ProtonCoreUIFoundations
import ProtonMailUI

final class MenuViewController: UIViewController, AccessibleView {

    @IBOutlet weak var accountSwitcherTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var menuWidth: NSLayoutConstraint!
    @IBOutlet private var shortNameView: UIView!
    @IBOutlet private var primaryUserview: UIView!
    @IBOutlet private var avatarLabel: UILabel!
    @IBOutlet private var displayName: UILabel!
    @IBOutlet private var arrowBtn: UIButton!
    @IBOutlet private var addressLabel: UILabel!
    @IBOutlet private(set) var tableView: UITableView!

    let viewModel: MenuVMProtocol
    private var upsellCoordinator: UpsellCoordinator?

    init(viewModel: MenuVMProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var prefersStatusBarHidden: Bool {
            return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.viewModel.userDataInit()
        self.viewModel.reloadClosure = { [weak self] in
            self?.tableView.reloadData()
        }
        self.viewInit()

        generateAccessibilityIdentifiers()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.appDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(preferredContentSizeChanged),
                         name: UIContentSizeCategory.didChangeNotification,
                         object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.menuViewInit()

        self.view.accessibilityElementsHidden = false
        self.view.becomeFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if UIAccessibility.isVoiceOverRunning {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0),
                                  at: .top, animated: true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.sideMenuController?.contentViewController.view.isUserInteractionEnabled = true
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        let newWidth = size.width
        let properWidth = MenuViewController.calcProperMenuWidth(referenceWidth: newWidth)
        guard properWidth != self.viewModel.menuWidth else { return }
        self.menuWidth.constant = properWidth
        self.viewModel.set(menuWidth: properWidth)
    }

    static func calcProperMenuWidth(
        keyWindow: UIWindow? = UIApplication.shared.topMostWindow,
        referenceWidth: CGFloat? = nil,
        expectedMenuWidth: CGFloat = 327
    ) -> CGFloat {

        let windowWidth = referenceWidth ?? keyWindow?.bounds.width ?? expectedMenuWidth
        let menuWidth = min(expectedMenuWidth, windowWidth)
        return menuWidth
    }
}

// MARK: Private functions
extension MenuViewController {
    private func viewInit() {
        self.view.backgroundColor = ColorProvider.SidebarBackground
        self.menuWidth.constant = self.viewModel.menuWidth
        self.tableView.backgroundColor = .clear
        self.tableView.register(MenuItemTableViewCell.self)
        self.tableView.register(MaxStorageTableViewCell.self, forCellReuseIdentifier: "\(MaxStorageTableViewCell.self)")
        self.tableView.tableFooterView = self.createTableFooter()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        //self.tableView.contentInset = .init(top: 28.0, left: 0.0, bottom: 0.0, right: 0.0)

        self.setPrimaryUserview(highlight: false)
        displayName.set(text: nil,
                        preferredFont: .subheadline,
                        weight: .regular,
                        textColor: ColorProvider.SidebarTextNorm)
        addressLabel.set(text: nil,
                         preferredFont: .footnote,
                         weight: .regular,
                         textColor: ColorProvider.SidebarTextWeak)
        self.arrowBtn.setImage(IconProvider.chevronDown, for: .normal)
        self.arrowBtn.imageView?.tintColor = ColorProvider.SidebarIconNorm
        self.primaryUserview.setCornerRadius(radius: 12)
        self.primaryUserview.accessibilityTraits = [.button]
        self.primaryUserview.accessibilityHint = LocalString._menu_open_account_switcher
        if (!UIDevice.hasNotch || UIDevice.current.userInterfaceIdiom == .pad) {
            self.accountSwitcherTopConstraint.constant = 10
        } else {
            self.accountSwitcherTopConstraint.constant = 0
        }

        self.shortNameView.setCornerRadius(radius: 8)
        self.avatarLabel.adjustsFontSizeToFitWidth = true
        avatarLabel.set(text: nil,
                        preferredFont: .footnote,
                        weight: .regular,
                        textColor: ColorProvider.SidebarTextNorm)
        self.avatarLabel.accessibilityElementsHidden = true
        self.addGesture()
    }

    private func addGesture() {
        let ges = UILongPressGestureRecognizer(target: self, action: #selector(longPressOnPrimaryUserView(ges:)))
        ges.minimumPressDuration = 0
        self.primaryUserview.addGestureRecognizer(ges)
    }

    @objc
    func longPressOnPrimaryUserView(ges: UILongPressGestureRecognizer) {

        let point = ges.location(in: self.primaryUserview)
        let origin = self.primaryUserview.bounds
        let isInside = origin.contains(point)

        let state = ges.state
        switch state {
        case .began:
            self.setPrimaryUserview(highlight: true)
        case.changed:
            if !isInside {
                self.setPrimaryUserview(highlight: false)
            }
        case .ended:
            self.setPrimaryUserview(highlight: false)
            if isInside {
                self.showAccountSwitcher()
            }
        default:
            break
        }
    }

    private func closeMenu() {
        self.sideMenuController?.hideMenu()
    }

    private func showSignupAlarm(_ sender: UIView?) {
        let shouldDeleteMessageInQueue = self.viewModel.isCurrentUserHasQueuedMessage()
        var message = LocalString._signout_confirmation

        if shouldDeleteMessageInQueue {
            message = LocalString._signout_confirmation_having_pending_message
        } else {
            if let user = self.viewModel.currentUser {
                if let nextUser = self.viewModel.secondUser {
                    message = String(format: LocalString._signout_confirmation, nextUser.defaultEmail)
                } else {
                    message = String(format: LocalString._signout_confirmation_one_account, user.defaultEmail)
                }
            }
        }

        let alertController = UIAlertController(title: LocalString._signout_title, message: message, preferredStyle: .actionSheet)

        alertController.addAction(UIAlertAction(title: LocalString._sign_out, style: .destructive, handler: { (action) -> Void in
            if shouldDeleteMessageInQueue {
                self.viewModel.removeAllQueuedMessageOfCurrentUser()
            }
            self.viewModel.signOut(userID: UserID(self.viewModel.currentUser?.userInfo.userId ?? ""),
                                   completion: nil)
        }))
        alertController.popoverPresentationController?.sourceView = sender ?? self.view
        alertController.popoverPresentationController?.sourceRect = (sender == nil ? self.view.frame : sender!.bounds)
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

    @objc
    private func showAccountSwitcher() {
        let list = self.viewModel.getAccountList()
        let switcher = try! AccountSwitcher(accounts: list)
        guard let sideMenu = self.sideMenuController else { return }
        switcher.present(on: sideMenu, reference: primaryUserview, delegate: self)
        delay(0.2) { [weak self] in
            self?.view.subviews
                .compactMap({ $0 as? AccountSwitcher })
                .forEach({ UIAccessibility.post(notification: .screenChanged, argument: $0) })
        }
    }

    private func setPrimaryUserview(highlight: Bool) {
        let color : UIColor = highlight ? ColorProvider.SidebarInteractionWeakPressed : ColorProvider.SidebarInteractionWeakNorm
        self.primaryUserview.backgroundColor = color
        self.arrowBtn.isHighlighted = highlight
    }

    @objc
    func appDidEnterBackground() {
        if let sideMenu = self.sideMenuController {
            AccountSwitcher.dismiss(from: sideMenu)
        }
    }

    private func checkAddLabelAbility(label: MenuLabel) {
        guard self.viewModel.allowToCreate(type: .label) else {
            presentUpsellPage(entryPoint: .labels)
            return
        }
        self.viewModel.go(to: label)
    }

    private func checkAddFolderAbility(label: MenuLabel) {
        guard self.viewModel.allowToCreate(type: .folder) else {
            presentUpsellPage(entryPoint: .folders)
            return
        }
        self.viewModel.go(to: label)
    }

    private func presentUpsellPage(entryPoint: UpsellPageEntryPoint) {
        guard let user = viewModel.currentUser else {
            return
        }

        upsellCoordinator = user.container.paymentsUIFactory.makeUpsellCoordinator(rootViewController: self)
        upsellCoordinator?.start(entryPoint: entryPoint)
    }

    @objc
    private func clickAddLabelFromSection() {
        self.checkAddLabelAbility(label: .init(location: .addLabel))
    }

    @objc
    private func clickAddFolderFromSection() {
        self.checkAddFolderAbility(label: .init(location: .addFolder))
    }

    @objc
    private func preferredContentSizeChanged() {
        displayName.font = .adjustedFont(forTextStyle: .subheadline, weight: .regular)
        addressLabel.font = .adjustedFont(forTextStyle: .footnote, weight: .regular)
        avatarLabel.font = .adjustedFont(forTextStyle: .footnote, weight: .regular)
    }
}

// MARK: MenuUIProtocol
extension MenuViewController: MenuUIProtocol {
    func update(email: String) {
        self.addressLabel.text = email
    }

    func update(displayName: String) {
        self.displayName.text = displayName
        self.primaryUserview.accessibilityLabel = displayName
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .screenChanged, argument: primaryUserview)
        }
    }

    func update(avatar: String) {
        self.avatarLabel.text = avatar
    }

    func updateMenu(section: Int?) {
        DispatchQueue.main.async { [weak self] in
            guard let _section = section else {
                self?.tableView.reloadData()
                return
            }

            self?.tableView.beginUpdates()
            self?.tableView.reloadSections(IndexSet(integer: _section),
                                          with: .fade)
            self?.tableView.endUpdates()
        }
    }

    func update(rows: [IndexPath], insertRows: [IndexPath], deleteRows: [IndexPath]) {

        self.tableView.beginUpdates()
        for indexPath in rows {
            guard let cell = self.tableView.cellForRow(at: indexPath) as? MenuItemTableViewCell,
                  let label = self.viewModel.menuItem(indexPath: indexPath) else {
                continue
            }
            cell.config(by: label, useFillIcon: self.viewModel.enableFolderColor, isUsedInSideBar: true, delegate: self)
            cell.update(iconColor: self.viewModel.getIconColor(of: label))
        }

        self.tableView.insertRows(at: insertRows, with: .fade)
        self.tableView.deleteRows(at: deleteRows, with: .fade)
        self.tableView.endUpdates()
    }

    func navigateTo(label: MenuLabel) {
        if let sideMenu = self.sideMenuController {
            AccountSwitcher.dismiss(from: sideMenu)
        }
        self.viewModel.go(to: label)
    }

    func showToast(message: String) {
        message.alertToastBottom()
    }
}

// MARK: TableViewDelegate
extension MenuViewController: UITableViewDelegate, UITableViewDataSource, MenuItemTableViewCellDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfRowsIn(section: section)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let _section = self.viewModel.sections[indexPath.section]
        if _section == .maxStorage { return 60 }
        return 48
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let _section = self.viewModel.sections[indexPath.section]
        switch _section {
        case .maxStorage:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(MaxStorageTableViewCell.self)", for: indexPath) as! MaxStorageTableViewCell
            cell.configure(
                storageVisibility: viewModel.storageAlertVisibility,
                delegate: self
            )
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(MenuItemTableViewCell.self)", for: indexPath) as! MenuItemTableViewCell
            if let label = self.viewModel.menuItem(indexPath: indexPath) {
                cell.config(by: label, useFillIcon: self.viewModel.enableFolderColor, isUsedInSideBar: true, delegate: self)
                cell.update(iconColor: self.viewModel.getIconColor(of: label))
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let _section = self.viewModel.sections[indexPath.section]
        if _section == .maxStorage { return }
        tableView.deselectRow(at: indexPath, animated: true)
        guard let label = self.viewModel.menuItem(indexPath: indexPath) else {
            return
        }
        switch label.location {
        case .lockapp:
            viewModel.lockTheScreen()
            self.closeMenu()
        case .signout:
            let cell = tableView.cellForRow(at: indexPath)
            self.showSignupAlarm(cell)
        case .customize:
            self.viewModel.go(to: label)
        case .addLabel:
            self.checkAddLabelAbility(label: label)
        case .addFolder:
            self.checkAddFolderAbility(label: label)
        default:
            self.viewModel.go(to: label)
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let _section = self.viewModel.sections[section]
        switch _section {
        case .maxStorage: return 8
        case .inboxes where self.viewModel.storageAlertVisibility != .hidden: return CGFloat.leastNonzeroMagnitude
        case .inboxes: return 8
        default:
            return 48
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let _section = self.viewModel.sections[section]
        let view = self.createHeaderView(section: _section)
        return view
    }

    func clickCollapsedArrow(labelID: LabelID) {
        self.viewModel.clickCollapsedArrow(labelID: labelID)
    }

    private func createHeaderView(section: MenuSection) -> UIView {
        let vi = UIView()
        vi.backgroundColor = .clear

        if section == .inboxes
            || section == .maxStorage { return vi }

        let line = UIView()
        line.backgroundColor = ColorProvider.SidebarSeparator
        vi.addSubview(line)
        [
            line.topAnchor.constraint(equalTo: vi.topAnchor),
            line.leadingAnchor.constraint(equalTo: vi.leadingAnchor),
            line.trailingAnchor.constraint(equalTo: vi.trailingAnchor),
            line.heightAnchor.constraint(equalToConstant: 1)
        ].activate()

        let label = UILabel()
        label.set(text: section.title,
                  preferredFont: .footnote,
                  weight: .regular,
                  textColor: ColorProvider.SidebarTextWeak)
        label.translatesAutoresizingMaskIntoConstraints = false

        vi.addSubview(label)
        [
            label.leadingAnchor.constraint(equalTo: vi.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: vi.centerYAnchor)
        ].activate()
        return self.addPlusButtonIfNeeded(vi: vi, section: section)
    }

    private func addPlusButtonIfNeeded(vi: UIView, section: MenuSection) -> UIView {
        guard section == .folders || section == .labels else {
            return vi
        }
        let addTypes: [LabelLocation] = [.addFolder, .addLabel]
        if let label = self.viewModel.menuItem(in: section, at: 0),
           addTypes.contains(label.location) {
            return vi
        }

        let plusView = UIView()
        plusView.backgroundColor = .clear
        plusView.isUserInteractionEnabled = true
        vi.addSubview(plusView)
        [
            plusView.topAnchor.constraint(equalTo: vi.topAnchor),
            plusView.trailingAnchor.constraint(equalTo: vi.trailingAnchor),
            plusView.bottomAnchor.constraint(equalTo: vi.bottomAnchor),
            plusView.widthAnchor.constraint(equalToConstant: 50)
        ].activate()
        let selector = section == .folders ? #selector(self.clickAddFolderFromSection): #selector(self.clickAddLabelFromSection)
        let tapGesture = UITapGestureRecognizer(target: self, action: selector)
        plusView.addGestureRecognizer(tapGesture)

        let plusIcon = UIImageView(image: IconProvider.plus)
        plusIcon.tintColor = ColorProvider.SidebarIconWeak

        plusView.addSubview(plusIcon)
        [
            plusIcon.trailingAnchor.constraint(equalTo: plusView.trailingAnchor, constant: -20),
            plusIcon.centerYAnchor.constraint(equalTo: plusView.centerYAnchor),
            plusIcon.widthAnchor.constraint(equalToConstant: 20),
            plusIcon.heightAnchor.constraint(equalToConstant: 20)
        ].activate()

        if section == .folders {
            plusView.accessibilityLabel = LocalString._labels_add_folder_action
        } else if section == .labels {
            plusView.accessibilityLabel = LocalString._labels_add_label_action
        }

        plusView.isAccessibilityElement = true
        plusView.accessibilityTraits = .button

        if let labelView = vi.subviews.filter({ $0 is UILabel }).first {
            vi.accessibilityElements = [labelView, plusView]
        } else {
            vi.accessibilityElements = [plusView]
        }

        return vi
    }

    private func createTableFooter() -> UIView {
        let version = self.viewModel.appVersion()
        let label = UILabel(font: .systemFont(ofSize: 13), text: "Proton Mail \(version)", textColor: ColorProvider.SidebarTextWeak)
        label.frame = CGRect(x: 0, y: 0, width: self.menuWidth.constant, height: 64)
        label.textAlignment = .center
        return label
    }
}

extension MenuViewController: AccountSwitchDelegate {
    func switchTo(userID: String) {
        self.viewModel.activateUser(id: UserID(userID))
    }

    func signinAccount(for mail: String, userID: String?) {
        if let id = userID {
            self.viewModel.prepareLogin(userID: UserID(id))
        } else {
            self.viewModel.prepareLogin(mail: mail)
        }
    }

    func signoutAccount(userID: String, viewModel: AccountManagerVMDataSource) {
        self.viewModel.signOut(userID: UserID(userID)) { [weak self] in
            guard let _self = self else {return}
            let list = _self.viewModel.getAccountList()
            viewModel.updateAccountList(list: list)
        }
    }

    func removeAccount(userID: String, viewModel: AccountManagerVMDataSource) {
        self.viewModel.signOut(userID: UserID(userID)) { [weak self] in
            guard let _self = self else {return}
            _self.viewModel.removeDisconnectAccount(userID: UserID(userID))
            let list = _self.viewModel.getAccountList()
            viewModel.updateAccountList(list: list)
        }
    }

    func accountManagerWillAppear() {
        guard let sideMenu = self.sideMenuController else { return }
        sideMenu.hideMenu()
    }

    func switcherWillDisappear() {
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .screenChanged, argument: primaryUserview)
        }
    }
}

extension MenuViewController: MaxStorageTableViewCellDelegate {
    func upgradeStorageTapped() {
        viewModel.go(to: .init(location: .subscription))
    }
}
