//
//  DropLandingZone.swift
//  ProtonMail - Created on 29/04/2019.
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

@available(iOS 11.0, *)
class DropLandingZone: UIVisualEffectView {
    convenience init(frame: CGRect) {
        let blur = UIBlurEffect(style: .prominent)
        self.init(effect: blur)

        self.frame = frame
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let vibrancy = UIVibrancyEffect(blurEffect: blur)
        let vibrancyOverlay = UIVisualEffectView(effect: vibrancy)
        vibrancyOverlay.frame = frame
        vibrancyOverlay.autoresizingMask = [.flexibleWidth]

        let subtitle = UILabel()
        subtitle.text = LocalString._drop_here
        subtitle.textColor = .black
        subtitle.sizeToFit()
        subtitle.center = vibrancyOverlay.center

        vibrancyOverlay.contentView.addSubview(subtitle)
        self.contentView.addSubview(vibrancyOverlay)
    }
}
