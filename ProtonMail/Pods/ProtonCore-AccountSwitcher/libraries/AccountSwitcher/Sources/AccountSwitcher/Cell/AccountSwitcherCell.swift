//
//  AccountSwitcherCell.swift
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

public final class AccountSwitcherCell: UITableViewCell, AccessibleCell {

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
    @IBOutlet private var separatorView: UIView!

    private weak var delegate: AccountSwitchCellProtocol?
    private var userID: String?

    public class func nib() -> UINib {
        return UINib(nibName: "AccountSwitcherCell", bundle: Bundle.switchBundle)
    }

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.unreadView.roundCorner(10)
        self.signInBtn.roundCorner(8)
        self.avatar.roundCorner(2)
        self.shortNameView.roundCorner(8)
        self.shortName.adjustsFontSizeToFitWidth = true
        self.contentView.backgroundColor = ColorProvider.BackgroundNorm
        self.name.textColor = ColorProvider.TextNorm
        self.mailAddress.textColor = ColorProvider.TextWeak
        self.shortNameView.backgroundColor = ColorProvider.BrandNorm
        self.shortName.backgroundColor = ColorProvider.BrandNorm
        self.shortName.textColor = AccountSwitcherStyle.smallTextColor
        self.signInBtn.backgroundColor = ColorProvider.InteractionWeak
        self.signInBtn.setTitleColor(ColorProvider.TextNorm, for: .normal)
        self.unreadView.backgroundColor = ColorProvider.BrandNorm
        self.unread.backgroundColor = ColorProvider.BrandNorm
        self.unread.textColor = AccountSwitcherStyle.smallTextColor
        self.separatorView.backgroundColor = ColorProvider.InteractionWeak
        let pressView = UIView(frame: .zero)
        pressView.backgroundColor = ColorProvider.BackgroundSecondary
        self.selectedBackgroundView = pressView
    }

    public func config(data: AccountSwitcher.AccountData, delegate: AccountSwitchCellProtocol) {
        self.delegate = delegate
        self.userID = data.userID
        // todo support avatar
        self.avatar.image = nil
        let name = data.name.isEmpty ? data.mail: data.name
        self.name.text = name
        self.shortName.text = self.name.text?.initials()
        self.mailAddress.text = data.mail
        
        if data.isSignin {
            self.signInBtn.isHidden = true
            self.unreadView.isHidden = data.unread == 0
            self.setupUnread(num: data.unread)
            self.name.textColor = ColorProvider.TextNorm
        } else {
            self.unreadView.isHidden = true
            self.signInBtn.isHidden = false
            self.name.textColor = ColorProvider.TextWeak
        }
        self.setupLabelConstraint(isSignin: data.isSignin)
        self.generateCellAccessibilityIdentifiers(name)
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
