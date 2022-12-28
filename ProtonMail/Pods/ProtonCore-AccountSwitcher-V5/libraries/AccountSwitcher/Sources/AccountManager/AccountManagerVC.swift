//
//  AccountManagerViewController.swift
//  ProtonCore-AccountSwitcher - Created on 03.06.2021
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import ProtonCore_CoreTranslation
import ProtonCore_Foundations
import ProtonCore_UIFoundations

public protocol AccountManagerUIProtocl: AnyObject {
    func reload()
    func dismiss()
}

public final class AccountManagerVC: UIViewController, AccessibleView {

    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var titleLabel: UILabel!
    private var viewModel: AccountManagerVMProtocl!
    private let CELLID = "AccountManagerUserCell"
    
    override public var preferredStatusBarStyle: UIStatusBarStyle { darkModeAwarePreferredStatusBarStyle() }

    public class func instance(withNavigationController: Bool = true) -> AccountManagerVC {
        let type = AccountManagerVC.self
        let vc = self.init(nibName: String(describing: type), bundle: Bundle.switchBundle)
        if withNavigationController {
            _ = DarkModeAwareNavigationViewController(rootViewController: vc)
        }
        return vc
    }

    override private init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(viewModel: AccountManagerVMProtocl) {
        self.viewModel = viewModel
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        assert(self.viewModel != nil, "Please use set(viewModel:) first")
        self.setupView()
        self.generateAccessibilityIdentifiers()
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(preferredContentSizeChanged(_:)),
                         name: UIContentSizeCategory.didChangeNotification,
                         object: nil)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.accountManagerWillAppear()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.viewModel.accountManagerWillDisappear()
    }
}

extension AccountManagerVC: AccountManagerUIProtocl {
    public func reload() {
        self.tableView.reloadData()
    }

    public func dismiss() {
        self.dismissView()
    }
}

extension AccountManagerVC: UITableViewDataSource, UITableViewDelegate, AccountmanagerUserCellDelegate {

    public func numberOfSections(in tableView: UITableView) -> Int {
        if self.viewModel.getSignedOutAccountAmount() == 0 {
            return 1
        } else {
            return 2
        }
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 52
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let title = section == 0 ? CoreString._as_signed_in_to_protonmail: CoreString._as_signed_out_of_protonmail
        let view = UIView(frame: .zero)
        view.backgroundColor = ColorProvider.BackgroundNorm

        let font = UIFont.adjustedFont(forTextStyle: .subheadline)
        let label = UILabel(title, font: font, textColor: ColorProvider.TextWeak)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = ColorProvider.BackgroundNorm
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])
        return view
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.viewModel.getSignedInAccountAmount()
        } else {
            return self.viewModel.getSignedOutAccountAmount()
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.CELLID, for: indexPath) as! AccountmanagerUserCell
        let section = indexPath.section
        var data: AccountSwitcher.AccountData?
        if section == 0 {
            data = self.viewModel.getSignedInAccount(in: indexPath.row)
        } else {
            data = self.viewModel.getSignedOutAccount(in: indexPath.row)
        }

        if let data = data {
            cell.config(userID: data.userID, name: data.name, mail: data.mail, isLogin: data.isSignin, delegate: self)
        } else {
            cell.config(userID: "", name: "", mail: "", isLogin: false, delegate: self)
        }

        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            guard let info = self.viewModel.getSignedInAccount(in: indexPath.row) else {
                return
            }
            self.viewModel.switchToAccount(userID: info.userID)
        } else {
            guard let info = self.viewModel.getSignedOutAccount(in: indexPath.row) else {
                return
            }
            self.viewModel.signinAccount(for: info.mail, userID: info.userID)
        }
    }

    func showMoreOption(for userID: String, sender: UIButton) {
        guard let data = self.viewModel.getAccountData(of: userID) else {
            return
        }
        // todo i18n
        let signout = UIAlertAction(title: CoreString._as_signout, style: .default) { [weak self] (_) in
            self?.checkLogoutWill(mail: data.mail, userID: userID)
        }

        let remove = UIAlertAction(title: CoreString._as_remove_account_from_this_device, style: .destructive) { [weak self] (_) in
            self?.checkRemoveWill(userID: userID)
        }

        let signin = UIAlertAction(title: CoreString._ls_screen_title, style: .default) { [weak self] (_) in
            self?.viewModel.signinAccount(for: data.mail, userID: data.userID)
        }

        let cancel = UIAlertAction(title: CoreString._hv_cancel_button, style: .cancel, handler: nil)

        let arr = data.isSignin ? [signout, remove, cancel]: [signin, remove, cancel]

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        for action in arr {
            alert.addAction(action)
        }

        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }

        self.present(alert, animated: true, completion: nil)
    }

    func prepareSignIn(for userID: String) {
        guard let data = self.viewModel.getAccountData(of: userID) else {
            return
        }
        self.viewModel.signinAccount(for: data.mail, userID: data.userID)
    }

    func prepareSignOut(for userID: String) {
        guard let data = self.viewModel.getAccountData(of: userID) else {
            return
        }
        self.checkLogoutWill(mail: data.mail, userID: userID)
    }

    func removeAccount(of userID: String) {
        guard nil != self.viewModel.getAccountData(of: userID) else {
            return
        }
        self.checkRemoveWill(userID: userID)
    }
}

extension AccountManagerVC {
    private func setupView() {
        self.setupNavigationBar()
        self.setupTableview()
        self.titleLabel.text = CoreString._as_manage_accounts
        self.titleLabel.textColor = ColorProvider.TextNorm
        titleLabel.font = .adjustedFont(forTextStyle: .title2, weight: .bold)
        self.view.backgroundColor = ColorProvider.BackgroundNorm
    }

    private func setupNavigationBar() {
        // Transparent background
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = .clear

        // Left item
        let closeBtn = UIBarButtonItem(image: IconProvider.crossSmall, style: .plain, target: self, action: #selector(self.dismissView))
        closeBtn.accessibilityLabel = CoreString._as_dismiss_button
        closeBtn.tintColor = ColorProvider.TextNorm
        self.navigationItem.leftBarButtonItem = closeBtn

        let addBtn = UIBarButtonItem(image: IconProvider.plus,
                                     style: .plain,
                                     target: self,
                                     action: #selector(self.clickAddButton))
        addBtn.tintColor = ColorProvider.TextNorm
        addBtn.accessibilityLabel = CoreString._as_sign_in_button
        self.navigationItem.rightBarButtonItem = addBtn
        
        self.navigationItem.assignNavItemIndentifiers()
    }

    private func setupTableview() {
        self.tableView.tableFooterView = UIView(frame: .zero)
        self.tableView.register(AccountmanagerUserCell.nib(), forCellReuseIdentifier: self.CELLID)
        self.tableView.backgroundColor = ColorProvider.BackgroundNorm
        self.tableView.separatorColor = ColorProvider.InteractionWeak
        if DFSSetting.enableDFS {
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 64
        } else {
            tableView.rowHeight = 64
        }
    }
}

extension AccountManagerVC {
    @objc private func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc private func clickAddButton() {
        self.viewModel.signinAccount(for: "", userID: nil)
    }

    @objc
    private func preferredContentSizeChanged(_ notification: Notification) {
        titleLabel.font = .adjustedFont(forTextStyle: .title2, weight: .bold)
    }

    private func checkLogoutWill(mail: String, userID: String) {
        let title = CoreString._as_signout
        let message = String(format: CoreString._as_signout_alert_text, mail)
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let cancel = UIAlertAction(title: CoreString._hv_cancel_button, style: .default, handler: nil)
        let logout = UIAlertAction(title: CoreString._as_signout, style: .destructive) { [weak self] (_) in
            self?.viewModel.signoutAccount(userID: userID)
        }
        alert.addAction(cancel)
        alert.addAction(logout)
        self.present(alert, animated: true, completion: nil)
    }

    private func checkRemoveWill(userID: String) {
        let title = CoreString._as_remove_account_from_this_device + "?"
        let message = CoreString._as_remove_account_alert_text
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let cancel = UIAlertAction(title: CoreString._hv_cancel_button, style: .default, handler: nil)
        let remove = UIAlertAction(title: CoreString._as_remove_button, style: .destructive) { [weak self](_) in
            self?.viewModel.removeAccount(userID: userID)
        }
        alert.addAction(cancel)
        alert.addAction(remove)
        self.present(alert, animated: true, completion: nil)
    }
}
