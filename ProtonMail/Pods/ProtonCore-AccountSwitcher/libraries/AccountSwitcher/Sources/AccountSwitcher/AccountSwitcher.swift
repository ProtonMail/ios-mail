//
//  AccountSwitcher.swift
//  ProtonCore-AccountSwitcher - Created on 03.06.2021
//
//  Copyright (c) 2020 Proton Technologies AG
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
import ProtonCore_Utilities

public extension AccountSwitcher {

    struct AccountData {
        public let userID: String
        public let name: String
        public let mail: String
        public let isSignin: Bool
        public var unread: Int
        // todo: avatar

        public init(userID: String, name: String, mail: String, isSignin: Bool, unread: Int) {
            self.userID = userID
            self.name = name
            self.mail = mail
            self.isSignin = isSignin
            self.unread = unread
        }
    }
}

public final class AccountSwitcher: UIView, AccessibleView {

    @IBOutlet private var containerView: UIView!
    @IBOutlet private var containerViewTop: NSLayoutConstraint!
    @IBOutlet var bgView: UIView!

    @IBOutlet private var titleView: UIView!
    @IBOutlet private var titleViewHeight: NSLayoutConstraint!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var primaryViewTop: NSLayoutConstraint!
    @IBOutlet private var shortUserNameView: UIView!
    @IBOutlet private var shortUserName: UILabel!
    @IBOutlet private var username: UILabel!
    @IBOutlet private var usermail: UILabel!
    @IBOutlet private var accountTable: UITableView!
    @IBOutlet private var accountTableHeight: NSLayoutConstraint!
    @IBOutlet private var primaryView: UIView!
    @IBOutlet private var manageView: UIView!
    @IBOutlet private var manageAccountLabel: UILabel!
    @IBOutlet private var manageAccountIcon: UIImageView!
    @IBOutlet private var primaryViewSeparator: UIView!

    private var accounts: [AccountData]
    private let origin: CGPoint
    private let CELLID = "AccountSwitcherCell"
    private let CELL_HEIGHT: CGFloat = 64
    private let HEADER_HEIGHT: CGFloat = 52
    private let disablePanGes: Bool
    private weak var delegate: AccountSwitchDelegate?
    private weak var parentVC: UIViewController?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Account switcher initialization
    /// - Parameter accounts: The list of account data, the first data is primary user
    /// - Parameter origin: A point that specifies the coordinates of the rectangle’s origin. Note: only y is used, x will be ignored
    /// - Parameter disablePanGes: Disable pan gesturer of side menu if needed
    /// - Throws: The account number is zero or the signed in account is zero
    public init(accounts: [AccountData], origin: CGPoint, disablePanGes: Bool = true) throws {
        self.origin = origin
        self.accounts = accounts
        self.disablePanGes = disablePanGes
        guard accounts.count > 0 else {
            throw AccountSwitcherError.emptyAccounts
        }

        let login = accounts.filter({ $0.isSignin })
        guard login.count > 0 else {
            throw AccountSwitcherError.noSigninedAccount
        }
        super.init(frame: .zero)
        self.nibSetup()
    }

    public func present(on parent: UIViewController, delegate: AccountSwitchDelegate) {
        self.delegate = delegate
        self.parentVC = parent
        self.delegate?.switcherWillAppear()
        parent.view.addSubview(self)
        self.fillSuperview()
    }

    /// Dismiss account switcher, in case you don't hold the switcher instance
    public class func dismiss(from parent: UIViewController) {
        let subviews = parent.view.subviews
        for vi in subviews {
            if let v = vi as? AccountSwitcher {
                v.dismiss()
            }
        }
    }

    /// Dismiss account switcher
    @objc public func dismiss() {
        self.delegate?.switcherWillDisappear()
        self.removeFromSuperview()
    }

    /// Update unread number of userID, in case you don't hold the switcher instance
    public class func updateUnread(on parent: UIViewController, userID: String, unread: Int) {
        let subviews = parent.view.subviews
        for vi in subviews {
            if let v = vi as? AccountSwitcher {
                v.updateUnread(userID: userID, unread: unread)
                break
            }
        }
    }

    /// Update unread number of userID
    /// If the given userID doesn't exist, do nothing
    public func updateUnread(userID: String, unread: Int) {
        guard let idx = self.accounts.firstIndex(where: { $0.userID == userID }) else { return }
        self.accounts[idx].unread = unread
        // the user is not primary user
        guard idx > 0 else { return }

        self.accountTable.beginUpdates()
        let path = IndexPath(row: idx - 1, section: 0)
        self.accountTable.reloadRows(at: [path], with: .none)
        self.accountTable.endUpdates()
    }

    @objc private func clickManager(ges: UILongPressGestureRecognizer) {
        let point = ges.location(in: self.manageView)
        let origin = self.manageView.bounds
        let isInside = origin.contains(point)

        let state = ges.state
        switch state {
        case .began:
            self.setManageView(hightlight: true)
        case.changed:
            if !isInside {
                self.setManageView(hightlight: false)
            }
        case .ended:
            self.setManageView(hightlight: false)
            if isInside {
                self.presentAccountManager()
                self.dismiss()
            }
        default:
            break
        }
    }

    private func setManageView(hightlight: Bool) {
        let color: UIColor = hightlight ? ColorProvider.BackgroundSecondary : ColorProvider.BackgroundNorm
        self.manageView.backgroundColor = color
        self.manageAccountLabel.backgroundColor = color
        self.manageAccountLabel.textColor = ColorProvider.TextNorm
        self.manageAccountIcon.image = IconProvider.cogWheel
        self.manageAccountIcon.backgroundColor = color
        self.manageAccountIcon.tintColor = ColorProvider.IconNorm
    }

    private func presentAccountManager() {
        guard let _delegate = self.delegate else { return }
        let vc = AccountManagerVC.instance()
        let vm = AccountManagerViewModel(accounts: self.accounts,
                                         uiDelegate: vc)
        vm.set(delegate: _delegate)
        guard let nav = vc.navigationController else { return }
        self.parentVC?.present(nav, animated: true, completion: nil)
    }

    override public func accessibilityPerformEscape() -> Bool {
        self.dismiss()
        return true
    }
}

// MARK: UI Initialization
extension AccountSwitcher {
    private func nibSetup() {
        let view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        addSubview(view)
        self.setup()
    }

    private func loadViewFromNib() -> UIView {
        let bundle = Bundle.switchBundle
        let name = String(describing: AccountSwitcher.self)
        let nib = UINib(nibName: name, bundle: bundle)
        let nibView = nib.instantiate(withOwner: self, options: nil).first as! UIView

        return nibView
    }

    private func setup() {
        self.setupContainerView()
        self.setupGesture()
        self.setupTitleView()
        self.setupPrimaryUserData()
        self.setupAccountTable()
        self.setManageView(hightlight: false)
        self.accessibilityViewIsModal = true
        self.shouldGroupAccessibilityChildren = true
        self.accessibilityContainerType = .list
        self.manageAccountLabel.text = CoreString._as_manage_accounts
        self.generateAccessibilityIdentifiers()
    }

    private func setupContainerView() {
        self.containerViewTop.constant = self.origin.y
        self.containerView.backgroundColor = ColorProvider.BackgroundNorm
        self.containerView.roundCorner(6)
    }

    private func setupTitleView() {
        self.titleView.backgroundColor = ColorProvider.BackgroundNorm
        self.titleLabel.backgroundColor = ColorProvider.BackgroundNorm
        self.titleLabel.textColor = ColorProvider.TextNorm
        self.primaryViewSeparator.backgroundColor = ColorProvider.InteractionWeak
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.titleView.isHidden = false
            self.titleLabel.text = CoreString._as_accounts
            self.titleViewHeight.constant = 44
            self.primaryViewTop.constant = 6
            return
        }
        // iPhone and other device
        self.titleView.isHidden = true
        self.titleViewHeight.constant = 0
        self.primaryViewTop.constant = 0
    }

    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismiss))
        self.bgView.addGestureRecognizer(tap)
        self.bgView.accessibilityTraits = .button
        self.bgView.accessibilityLabel = CoreString._as_dismiss_button

        let tap2 = UILongPressGestureRecognizer(target: self, action: #selector(self.clickManager))
        tap2.minimumPressDuration = 0
        self.manageView.addGestureRecognizer(tap2)
        self.manageView.accessibilityTraits = .button

        if self.disablePanGes {
            let pan = UIPanGestureRecognizer(target: self, action: nil)
            self.bgView.addGestureRecognizer(pan)
            let pan2 = UIPanGestureRecognizer(target: self, action: nil)
            self.containerView.addGestureRecognizer(pan2)
        }
    }

    private func setupPrimaryUserData() {
        let user = self.accounts[0]
        self.shortUserNameView.roundCorner(8)
        self.shortUserName.adjustsFontSizeToFitWidth = true
        if user.name.isEmpty {
            self.shortUserName.text = user.mail.initials()
            self.username.text = user.mail
        } else {
            self.shortUserName.text = user.name.initials()
            self.username.text = user.name
        }
        self.usermail.text = user.mail
        self.username.textColor = ColorProvider.TextNorm
        self.usermail.textColor = ColorProvider.TextWeak
        self.primaryView.backgroundColor = ColorProvider.BackgroundNorm
        self.username.backgroundColor = ColorProvider.BackgroundNorm
        self.usermail.backgroundColor = ColorProvider.BackgroundNorm
        self.shortUserNameView.backgroundColor = ColorProvider.BrandNorm
        self.shortUserName.backgroundColor = ColorProvider.BrandNorm
        self.shortUserName.textColor = AccountSwitcherStyle.smallTextColor
    }

    private func setupAccountTable() {
        var height = CGFloat((self.accounts.count - 1)) * self.CELL_HEIGHT + self.HEADER_HEIGHT
        height = self.accounts.count > 1 ? height: 0
        self.accountTableHeight.constant = height
        self.accountTable.register(AccountSwitcherCell.nib(), forCellReuseIdentifier: self.CELLID)
        self.accountTable.tableFooterView = UIView(frame: .zero)
        self.accountTable.backgroundColor = ColorProvider.BackgroundNorm
        self.accountTable.separatorColor = .clear
        self.accountTable.separatorStyle = .none
    }
}

extension AccountSwitcher: UITableViewDataSource, UITableViewDelegate, AccountSwitchCellProtocol {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.CELL_HEIGHT
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.accounts.count - 1
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.HEADER_HEIGHT
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = ColorProvider.BackgroundNorm
        let label = UILabel(CoreString._as_switch_to_title, font: .systemFont(ofSize: 15), textColor: ColorProvider.TextWeak)
        view.addSubview(label)
        label.constraintToSuperview(top: 24, right: 0, bottom: -8, left: 16)
        label.backgroundColor = ColorProvider.BackgroundNorm
        return view
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.CELLID, for: indexPath) as! AccountSwitcherCell
        let data = self.accounts[indexPath.row + 1]
        cell.config(data: data, delegate: self)
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = self.accounts[indexPath.row + 1]
        if data.isSignin {
            self.delegate?.switchTo(userID: data.userID)
        } else {
            self.delegate?.signinAccount(for: data.mail, userID: data.userID)
        }

        self.dismiss()
    }

    public func signinTo(mail: String, userID: String?) {
        self.delegate?.signinAccount(for: mail, userID: userID)
        self.dismiss()
    }
}
