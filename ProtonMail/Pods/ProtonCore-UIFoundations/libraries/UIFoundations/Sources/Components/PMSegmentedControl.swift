//
//  PMSegmentedControl.swift
//  ProtonCore-UIFoundations - Created on 28.03.21.
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
import ProtonCore_Foundations

public final class PMSegmentedControl: UISegmentedControl, AccessibleView {

    private let defaultFont = UIFont.systemFont(ofSize: 14)
    private let defaultColor: UIColor = ColorProvider.TextNorm

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    init() {
        super.init(frame: .zero)
        configure()
    }

    public func setImage(image: UIImage, withText: String, forSegmentAt: Int) {
        let embeddedImage = UIImage.textEmbeded(image: image, string: withText, font: defaultFont)
        setImage(embeddedImage, forSegmentAt: forSegmentAt)
    }

    private func configure() {
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: defaultColor, NSAttributedString.Key.font: defaultFont]
        setTitleTextAttributes(titleTextAttributes, for: .selected)
        setTitleTextAttributes(titleTextAttributes, for: .normal)
        
        backgroundColor = ColorProvider.SeparatorNorm
        if #available(iOS 13.0, *) {
            selectedSegmentTintColor = ColorProvider.BackgroundNorm
        } else {
            tintColor = ColorProvider.BackgroundNorm
        }
        generateAccessibilityIdentifiers()
    }
}
