//
//  ExpirationIconView.swift
//  ProtonMail - Created on 2020.
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
//

import ProtonCore_UIFoundations
import UIKit

class ExpirationIconView: PMView {
    @IBOutlet var view: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var expirationLabel: UILabel!

    struct Constant {
        static let height: CGFloat = 18.0
    }

    override func getNibName() -> String {
        return "ExpirationIconView"
    }

    override class func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setupView() {
        super.setupView()
        self.view.backgroundColor = ColorProvider.InteractionWeak
        self.view.layer.cornerRadius = Constant.height / 2.0
        self.view.layer.masksToBounds = true

        iconImageView.image = UIImage(named: "mail_list_expiration")?.toTemplateUIImage()
        iconImageView.tintColor = ColorProvider.IconNorm
    }

    func configureView(time: Date) {
        var distance: TimeInterval = 0.0
        if #available(iOS 13.0, *) {
            distance = Date().distance(to: time)
        } else {
            distance = time.timeIntervalSinceReferenceDate - Date().timeIntervalSinceReferenceDate
        }

        if distance > 86400 {
            let day = Int(distance / 86400)
            expirationLabel.text = String.localizedStringWithFormat(LocalString._day, day)
        } else if distance > 3600 {
            let hour = Int(distance / 3600)
            expirationLabel.text = String.localizedStringWithFormat(LocalString._hour, hour)
        } else {
            let minute = Int(distance / 60)
            expirationLabel.text = String.localizedStringWithFormat(LocalString._minute, minute)
        }
    }
}
