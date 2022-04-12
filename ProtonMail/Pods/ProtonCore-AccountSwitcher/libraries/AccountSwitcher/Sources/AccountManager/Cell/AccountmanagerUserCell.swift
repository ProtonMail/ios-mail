//
//  AccountmanagerUserCell.swift
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

protocol AccountmanagerUserCellDelegate: AnyObject {
    /// Show more option action sheet, only call this function before iOS 14
    func showMoreOption(for userID: String, sender: UIButton)
    @available(iOS 14.0, *)
    func removeAccount(of userID: String)
    @available(iOS 14.0, *)
    func prepareSignIn(for userID: String)
    @available(iOS 14.0, *)
    func prepareSignOut(for userID: String)
}

final class MoreButton: UIButton {
    
    override var isHighlighted: Bool {
        didSet { refreshBackgroundColor() }
    }
    
    override var isSelected: Bool {
        didSet { refreshBackgroundColor() }
    }
    
    func refreshBackgroundColor() {
        if isSelected || isHighlighted {
            backgroundColor = AccountSwitcherStyle.buttonSelectedColor
        } else {
            backgroundColor = nil
        }
    }
    
    override func layoutSubviews() {
        let circleLayer = CAShapeLayer()
        circleLayer.path = UIBezierPath(ovalIn: bounds).cgPath
        layer.mask = circleLayer
        super.layoutSubviews()
    }
}

final class AccountmanagerUserCell: UITableViewCell, AccessibleCell {

    @IBOutlet private var shortNameView: UIView!
    @IBOutlet private var shortNameLabel: UILabel!
    @IBOutlet private var name: UILabel!
    @IBOutlet private var mail: UILabel!
    @IBOutlet private var moreBtn: MoreButton!
    @IBOutlet private var separatorView: UIView!
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
        self.shortNameView.roundCorner(8)
        self.shortNameLabel.adjustsFontSizeToFitWidth = true
        self.contentView.backgroundColor = ColorProvider.BackgroundNorm
        self.name.textColor = ColorProvider.TextNorm
        self.mail.textColor = ColorProvider.TextWeak
        self.shortNameView.backgroundColor = ColorProvider.BrandNorm
        self.shortNameLabel.textColor = AccountSwitcherStyle.smallTextColor
        self.shortNameLabel.backgroundColor = ColorProvider.BrandNorm
        self.separatorView.backgroundColor = ColorProvider.InteractionWeak
        self.moreBtn.setImage(IconProvider.threeDotsHorizontal, for: .normal)
        self.moreBtn.tintColor = ColorProvider.TextNorm
    }

    func config(userID: String, name: String,
                mail: String, isLogin: Bool,
                delegate: AccountmanagerUserCellDelegate) {
        self.delegate = delegate
        self.userID = userID
        let name: String = name.isEmpty ? mail: name
        self.name.text = name
        self.shortNameLabel.text = self.name.text?.initials()
        if isLogin {
            self.name.textColor = ColorProvider.TextNorm
        } else {
            self.name.textColor = ColorProvider.TextWeak
        }
        self.mail.text = mail
        
        self.isLogin = isLogin
        if #available(iOS 14.0, *) {
            // This will override IBAction
            self.configMoreButton(isSignin: isLogin)
        }
        self.generateCellAccessibilityIdentifiers(name)
    }

    @available(iOS 14.0, *)
    private func configMoreButton(isSignin: Bool) {
        // todo i18n

        let signOut = UIAction(title: CoreString._as_signout,
                               image: IconProvider.arrowOutFromRectangle) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.prepareSignOut(for: self.userID)
        }

        let signIn = UIAction(title: CoreString._ls_screen_title,
                              image: AccountSwitcherStyle.signInIcon) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.prepareSignIn(for: self.userID)
        }

        let remove = UIAction(title: CoreString._as_remove_account,
                              image: IconProvider.minusCircle,
                              attributes: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.removeAccount(of: self.userID)
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
