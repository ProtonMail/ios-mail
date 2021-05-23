//
//  AccountSwitcherCell.swift
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
import ProtonCore_CoreTranslation
import ProtonCore_UIFoundations

public final class AccountSwitcherCell: UITableViewCell {

    @IBOutlet private var avatar: UIImageView!
    @IBOutlet private var shortNameView: UIView!
    @IBOutlet private var shortName: UILabel!
    @IBOutlet private var name: UILabel!
    @IBOutlet private var nameRightToUnread: NSLayoutConstraint!
    @IBOutlet private var nameRightToSignin: NSLayoutConstraint!
    @IBOutlet private var mailAddress: UILabel!
    @IBOutlet private var signInBtn: UIButton!
    @IBOutlet private var unreadView: UIView!
    @IBOutlet private var unread: UILabel!

    private weak var delegate: AccountSwitchCellProtocol?
    private var userID: String?

    public class func nib() -> UINib {
        return UINib(nibName: "AccountSwitcherCell", bundle: Bundle.switchBundle)
    }

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.unreadView.roundCorner(10)
        self.signInBtn.roundCorner(3)
        self.avatar.roundCorner(2)
        self.shortNameView.roundCorner(2)
        self.shortName.adjustsFontSizeToFitWidth = true

        let pressView = UIView(frame: .zero)
        pressView.backgroundColor = UIColorManager.BackgroundSecondary
        self.selectedBackgroundView = pressView

    }

    public func config(data: AccountSwitcher.AccountData, delegate: AccountSwitchCellProtocol) {
        self.delegate = delegate
        self.userID = data.userID
        // todo support avatar
        self.avatar.image = nil
        self.name.text = data.name.isEmpty ? data.mail: data.name
        self.shortName.text = self.name.text?.shortName()
        self.mailAddress.text = data.mail
        
        if data.isSignin {
            self.signInBtn.isHidden = true
            self.unreadView.isHidden = data.unread == 0
            self.setupUnread(num: data.unread)
        } else {
            self.unreadView.isHidden = true
            self.signInBtn.isHidden = false
        }
        self.setupLabelConstraint(isSignin: data.isSignin)
    }

    private func setupLabelConstraint(isSignin: Bool) {
        if isSignin {
            self.nameRightToUnread.isActive = true
            self.nameRightToSignin.isActive = false
        } else {
            self.nameRightToUnread.isActive = false
            self.nameRightToSignin.isActive = true
        }
    }

    private func setupUnread(num: Int) {
        let n = num > 9999 ? "9999+": "\(num)"
        self.unread.text = n
    }

    @IBAction private func clickSigninBtn(_ sender: Any) {
        self.delegate?.signinTo(mail: self.mailAddress.text!,
                                userID: self.userID)
    }
}
