//
//  AccountmanagerUserCell.swift
//  ProtonMail
//
//
//  Copyright (c) 2020 Proton Technologies AG
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
import PMUIFoundations
import PMCoreTranslation

protocol AccountmanagerUserCellDelegate: class {
    /// Show more option action sheet, only call this function before iOS 14
    func showMoreOption(for userID: String, sender: UIButton)
    @available(iOS 14.0, *)
    func removeAccount(of userID: String)
    @available(iOS 14.0, *)
    func prepareSignIn(for userID: String)
    @available(iOS 14.0, *)
    func prepareSignOut(for userID: String)
}

final class AccountmanagerUserCell: UITableViewCell {

    @IBOutlet private var shortNameView: UIView!
    @IBOutlet private var shortNameLabel: UILabel!
    @IBOutlet private var name: UILabel!
    @IBOutlet private var mail: UILabel!
    @IBOutlet private var moreBtn: UIButton!
    private var userID: String = ""
    private var isLogin: Bool = false
    private weak var delegate: AccountmanagerUserCellDelegate?

    class func nib() -> UINib {
        let type = AccountmanagerUserCell.self
        let name = String(describing: type)
        let bundle = Bundle.switchBundle
        return UINib(nibName: name, bundle: bundle)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        if #available(iOS 14.0, *) {
            self.moreBtn.showsMenuAsPrimaryAction = true
        }
        self.moreBtn.roundCorner(20)
        self.shortNameView.roundCorner(2)
        self.shortNameLabel.adjustsFontSizeToFitWidth = true
    }

    func config(userID: String, name: String,
                mail: String, isLogin: Bool,
                delegate: AccountmanagerUserCellDelegate) {
        self.delegate = delegate
        self.userID = userID
        self.name.text = name.isEmpty ? mail: name
        self.shortNameLabel.text = self.name.text?.shortName()
        if isLogin {
            self.name.textColor = UIColorManager.TextNorm
        } else {
            self.name.textColor = UIColorManager.TextWeak
        }
        self.mail.text = mail
        
        self.isLogin = isLogin
        if #available(iOS 14.0, *) {
            // This will override IBAction
            self.configMoreButton(isSignin: isLogin)
        }
    }

    @available(iOS 14.0, *)
    private func configMoreButton(isSignin: Bool) {
        // todo i18n

        let signOut = UIAction(title: CoreString._as_signout, image: UIImage(named: "menu_signout", in: Bundle.switchBundle, compatibleWith: nil)) { [weak self](_) in
            guard let _self = self else {return}
            _self.delegate?.prepareSignOut(for: _self.userID)
        }

        let signIn = UIAction(title: CoreString._ls_screen_title, image: UIImage(named: "icon_signin", in: Bundle.switchBundle, compatibleWith: nil)) { [weak self](_) in
            guard let _self = self else {return}
            _self.delegate?.prepareSignIn(for: _self.userID)
        }

        let remove = UIAction(title: CoreString._as_remove_account, image: UIImage(named: "icon_minus_circle", in: Bundle.switchBundle, compatibleWith: nil), attributes: .destructive) { [weak self](_) in
            guard let _self = self else {return}
            _self.delegate?.removeAccount(of: _self.userID)
        }

        let arr = isSignin ? [signOut, remove]: [signIn, remove]
        let menu = UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: arr)
        self.moreBtn.menu = menu
        self.moreBtn.showsMenuAsPrimaryAction = true
    }

    @IBAction private func clickMoreBtn(_ sender: UIButton) {
        self.delegate?.showMoreOption(for: self.userID, sender: sender)
    }

}
