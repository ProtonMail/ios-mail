//
//  AccountSwitcher.swift
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

#if os(iOS)

import UIKit
import ProtonCoreFoundations
import ProtonCoreUIFoundations
import ProtonCoreUtilities

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

        static func mock() -> AccountData {
            self.init(
                userID: "fake",
                name: "User name",
                mail: "Mail address",
                isSignin: true,
                unread: 0
            )
        }
    }
}

public final class AccountSwitcher: UIView, AccessibleView {
    private let backgroundView = AccountSwitcher.backgroundView()
    private let container = AccountSwitcher.container()
    private let primaryUserView = AccountSwitcher.PrimaryUserView()
    private let tableHeader = AccountSwitcher.tableHeader()
    private let accountTable = AccountSwitcher.tableView()
    private let accountTableHeight: NSLayoutConstraint
    private let manageView = AccountSwitcher.ManageView()

    private weak var delegate: AccountSwitchDelegate?
    private weak var parentVC: UIViewController?
    private var accounts: [AccountData]
    private let disablePanGes: Bool
    private let CELLID = "AccountSwitcherCell"
    private let CELL_HEIGHT: CGFloat = 64

    /// Account switcher initialization
    /// - Parameter accounts: The list of account data, the first data is primary user
    /// - Parameter disablePanGes: Disable pan gesturer of side menu if needed
    /// - Throws: The account number is zero or the signed in account is zero
    public init(accounts: [AccountData], disablePanGes: Bool = true) throws {
        guard accounts.count > 0 else {
            throw AccountSwitcherError.emptyAccounts
        }

        let login = accounts.filter({ $0.isSignin })
        if login.isEmpty {
            throw AccountSwitcherError.noSigninedAccount
        }

        self.accounts = accounts
        self.disablePanGes = disablePanGes

        let height = CGFloat(accounts.count - 1) * CELL_HEIGHT
        self.accountTableHeight = accountTable.heightAnchor.constraint(equalToConstant: height)
        self.accountTableHeight.isActive = true

        super.init(frame: .zero)
        self.accountTable.delegate = self
        self.accountTable.dataSource = self
        primaryUserView.update(account: accounts[0])
        setUpGesture()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.preferredContentSizeChanged),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func accessibilityPerformEscape() -> Bool {
        dismiss()
        return true
    }

    /// Present switcher
    /// - Parameters:
    ///   - parent: ViewController that switcher to present
    ///   - reference: Reference view to provide switcher topAnchor position
    ///   - delegate: AccountSwitchDelegate
    public func present(on parent: UIViewController, reference: UIView, delegate: AccountSwitchDelegate) {
        self.delegate = delegate
        self.parentVC = parent
        parent.view.addSubview(self)
        self.fillSuperview()
        accountTable.reloadData { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.accountTableHeight.constant = self.accountTable.contentSize.height
            }
        }
        setUpSubViewsConstraints(referenceItem: reference)
    }

    /// Dismiss account switcher
    @objc
    public func dismiss() {
        delegate?.switcherWillDisappear()
        removeFromSuperview()
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

    /// Update unread number of userID, in case you don't hold the switcher instance
    public class func updateUnread(on parent: UIViewController, userID: String, unread: Int) {
        let subviews = parent.view.subviews
        for vi in subviews {
            guard let switcher = vi as? AccountSwitcher else { continue }
            switcher.updateUnread(userID: userID, unread: unread)
        }
    }

    /// Update unread number of userID
    /// If the given userID doesn't exist, do nothing
    public func updateUnread(userID: String, unread: Int) {
        guard let idx = accounts.firstIndex(where: { $0.userID == userID }) else { return }
        accounts[idx].unread = unread
        // the user is not primary user
        guard idx > 0 else { return }

        accountTable.beginUpdates()
        let path = IndexPath(row: idx - 1, section: 0)
        accountTable.reloadRows(at: [path], with: .none)
        accountTable.endUpdates()
    }
}

extension AccountSwitcher: UITableViewDelegate, UITableViewDataSource, AccountSwitchCellProtocol {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        DFSSetting.enableDFS ? UITableView.automaticDimension : CELL_HEIGHT
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        accounts.count - 1
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.CELLID, for: indexPath) as! AccountSwitcherCell
        let data = accounts[indexPath.row + 1]
        let n = AccountSwitcher.AccountData(userID: data.userID, name: data.name, mail: data.mail, isSignin: data.isSignin, unread: data.unread)
        cell.config(data: n, delegate: self)
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

// MARK: - UI related
extension AccountSwitcher {

    private func setUpSubViewsConstraints(referenceItem: UIView) {
        addSubview(backgroundView)
        backgroundView.fillSuperview()

        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: referenceItem.topAnchor),
            container.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            container.widthAnchor.constraint(lessThanOrEqualToConstant: 375),
            container.bottomAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
        let containerTrail = container.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16)
        containerTrail.priority = .init(999)
        containerTrail.isActive = true

        container.addSubview(primaryUserView)
        NSLayoutConstraint.activate([
            primaryUserView.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            primaryUserView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            primaryUserView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        var tableViewTopReference: UIView = primaryUserView
        if accounts.count > 1 {
            tableViewTopReference = tableHeader
            container.addSubview(tableHeader)
            NSLayoutConstraint.activate([
                tableHeader.topAnchor.constraint(equalTo: primaryUserView.bottomAnchor, constant: 24),
                tableHeader.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                tableHeader.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
            ])
        }

        container.addSubview(accountTable)
        NSLayoutConstraint.activate([
            accountTable.topAnchor.constraint(equalTo: tableViewTopReference.bottomAnchor, constant: 8),
            accountTable.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            accountTable.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        container.addSubview(manageView)
        NSLayoutConstraint.activate([
            manageView.topAnchor.constraint(equalTo: accountTable.bottomAnchor),
            manageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            manageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            manageView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
    }

    private func setUpGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        backgroundView.addGestureRecognizer(tap)

        let tap2 = UILongPressGestureRecognizer(target: self, action: #selector(clickManager(gesture:)))
        tap2.minimumPressDuration = 0
        manageView.addGestureRecognizer(tap2)

        if self.disablePanGes {
            let pan = UIPanGestureRecognizer(target: self, action: nil)
            self.backgroundView.addGestureRecognizer(pan)
            let pan2 = UIPanGestureRecognizer(target: self, action: nil)
            self.container.addGestureRecognizer(pan2)
        }
    }

    private static func backgroundView() -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = ColorProvider.BlenderNorm
        view.accessibilityTraits = .button
        view.accessibilityLabel = ASTranslation.dismiss_button.l10n
        return view
    }

    private static func container() -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = ColorProvider.BackgroundNorm
        view.roundCorner(6)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    private static func tableHeader() -> UILabel {
        let label = UILabel(frame: .zero)
        label.text = ASTranslation.switch_to_title.l10n
        label.font = .adjustedFont(forTextStyle: .subheadline)
        label.textColor = ColorProvider.TextWeak
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private static func tableView() -> UITableView {
        let CELLID = "AccountSwitcherCell"
        let table = UITableView(frame: .zero)
        table.backgroundColor = .clear
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(AccountSwitcherCell.nib(), forCellReuseIdentifier: CELLID)
        table.tableFooterView = UIView(frame: .zero)
        table.separatorColor = .clear
        table.separatorStyle = .none
        return table
    }

    @objc
    private func preferredContentSizeChanged() {
        DispatchQueue.main.async {
            self.accountTableHeight.constant = self.accountTable.contentSize.height
        }
    }
}

// MARK: - Actions
extension AccountSwitcher {

    @objc
    private func clickManager(gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: manageView)
        let origin = manageView.bounds
        let isInside = origin.contains(point)

        let state = gesture.state
        switch state {
        case .began:
            manageView.isHighlight = true
        case.changed:
            if !isInside {
                manageView.isHighlight = false
            }
        case .ended:
            manageView.isHighlight = false
            if isInside {
                self.presentAccountManager()
                self.dismiss()
            }
        default:
            break
        }
    }

    private func presentAccountManager() {
        guard let _delegate = self.delegate else { return }
        let vc = AccountManagerVC.instance()
        let vm = AccountManagerViewModel(accounts: accounts, uiDelegate: vc)
        vm.set(delegate: _delegate)
        guard let nav = vc.navigationController else { return }
        self.parentVC?.present(nav, animated: true, completion: nil)
    }
}

extension AccountSwitcher {
    private final class PrimaryUserView: UIView {
        private var account = AccountData.mock()
        private let userName = PrimaryUserView.userName()
        private let mailAddress = PrimaryUserView.mailAddress()
        private let initials = PrimaryUserView.initials()
        private let initialsContainer = PrimaryUserView.initialsContainer()
        private let separator = PrimaryUserView.separator()

        init() {
            super.init(frame: .zero)
            translatesAutoresizingMaskIntoConstraints = false
            update(account: account)
            addSubComponents()
            setUpConstraints()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update(account: AccountData) {
            self.account = account
            userName.text = account.name.isEmpty ? account.mail : account.name
            mailAddress.text = account.mail
            let ref = account.name.isEmpty ? account.mail : account.name
            initials.text = ref.initials()
        }

        private func addSubComponents() {
            addSubview(initialsContainer)
            initialsContainer.addSubview(initials)
            addSubview(userName)
            addSubview(mailAddress)
            addSubview(separator)
        }

        private func setUpConstraints() {
            NSLayoutConstraint.activate([
                initialsContainer.topAnchor.constraint(equalTo: topAnchor, constant: 18),
                initialsContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
                initialsContainer.heightAnchor.constraint(equalToConstant: 28),
                initialsContainer.widthAnchor.constraint(equalToConstant: 28)
            ])

            NSLayoutConstraint.activate([
                initials.topAnchor.constraint(equalTo: initialsContainer.topAnchor, constant: 4),
                initials.leadingAnchor.constraint(equalTo: initialsContainer.leadingAnchor),
                initials.trailingAnchor.constraint(equalTo: initialsContainer.trailingAnchor),
                initials.bottomAnchor.constraint(equalTo: initialsContainer.bottomAnchor, constant: -4)
            ])

            NSLayoutConstraint.activate([
                userName.topAnchor.constraint(equalTo: topAnchor, constant: 14),
                userName.leadingAnchor.constraint(equalTo: initialsContainer.trailingAnchor, constant: 14),
                userName.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
            ])

            NSLayoutConstraint.activate([
                mailAddress.topAnchor.constraint(equalTo: userName.bottomAnchor),
                mailAddress.leadingAnchor.constraint(equalTo: userName.leadingAnchor),
                mailAddress.trailingAnchor.constraint(equalTo: userName.trailingAnchor),
                mailAddress.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15)
            ])

            NSLayoutConstraint.activate([
                separator.bottomAnchor.constraint(equalTo: bottomAnchor),
                separator.leadingAnchor.constraint(equalTo: leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: trailingAnchor),
                separator.heightAnchor.constraint(equalToConstant: 1)
            ])
        }

        private static func userName() -> UILabel {
            let label = UILabel(frame: .zero)
            label.font = .adjustedFont(forTextStyle: .subheadline)
            label.adjustsFontForContentSizeCategory = true
            label.adjustsFontSizeToFitWidth = true
            label.textColor = ColorProvider.TextNorm
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }

        private static func mailAddress() -> UILabel {
            let label = UILabel(frame: .zero)
            label.font = .adjustedFont(forTextStyle: .footnote)
            label.adjustsFontForContentSizeCategory = true
            label.adjustsFontSizeToFitWidth = true
            label.textColor = ColorProvider.TextWeak
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }

        private static func initials() -> UILabel {
            let label = UILabel(frame: .zero)
            label.font = .adjustedFont(forTextStyle: .footnote)
            label.adjustsFontForContentSizeCategory = true
            label.adjustsFontSizeToFitWidth = true
            label.textColor = ColorProvider.White
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }

        private static func initialsContainer() -> UIView {
            let view = UIView(frame: .zero)
            view.backgroundColor = ColorProvider.BrandNorm
            view.roundCorner(8)
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }

        private static func separator() -> UIView {
            let view = UIView(frame: .zero)
            view.backgroundColor = ColorProvider.InteractionWeak
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }
    }

    private final class ManageView: UIView {
        private let manageLabel = ManageView.manageLabel()
        private let icon = ManageView.icon()
        var isHighlight = false {
            didSet {
                let color: UIColor = isHighlight ? ColorProvider.BackgroundSecondary : ColorProvider.BackgroundNorm
                backgroundColor = color
            }
        }

        init() {
            super.init(frame: .zero)
            accessibilityTraits = .button
            translatesAutoresizingMaskIntoConstraints = false
            backgroundColor = ColorProvider.BackgroundNorm
            setUpConstraints()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setUpConstraints() {
            addSubview(icon)
            NSLayoutConstraint.activate([
                icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
                icon.centerYAnchor.constraint(equalTo: centerYAnchor),
                icon.widthAnchor.constraint(equalToConstant: 24),
                icon.heightAnchor.constraint(equalToConstant: 24)
            ])

            addSubview(manageLabel)
            NSLayoutConstraint.activate([
                manageLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 16),
                manageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                manageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
                manageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
            ])
        }

        private static func manageLabel() -> UILabel {
            let label = UILabel(frame: .zero)
            label.text = ASTranslation.manage_accounts.l10n
            label.backgroundColor = .clear
            label.font = .adjustedFont(forTextStyle: .subheadline)
            label.adjustsFontSizeToFitWidth = true
            label.adjustsFontForContentSizeCategory = true
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }

        private static func icon() -> UIImageView {
            let view = UIImageView(image: IconProvider.cogWheel)
            view.backgroundColor = .clear
            view.tintColor = ColorProvider.IconNorm
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }
    }
}

private extension UITableView {
    func reloadData(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0, animations: reloadData) { _ in
            completion()
        }
    }
}

#endif
