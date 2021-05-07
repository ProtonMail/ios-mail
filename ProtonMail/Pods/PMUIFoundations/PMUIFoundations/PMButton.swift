//
//  File.swift
//  ProtonMail - Created on 26.05.20.
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

import UIKit

public class PMButton: UIButton {

    public enum Style {
        case primary
        case secondary
    }

    public var style: Style = .primary {
        didSet {
            update()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    init() {
        super.init(frame: .zero)
        configure()
    }

    @objc public override var isHighlighted: Bool {
        didSet {
            update()
        }
    }

    private func configure() {
        contentEdgeInsets = UIEdgeInsets(top: 8, left: 25, bottom: 8, right: 25)
        layer.cornerRadius = 2.5
        titleLabel?.font = .preferredFont(forTextStyle: .footnote)

        update()
    }

    private func update() {
        switch style {
        case .primary:
            setTitleColor(AdaptiveTextColors._N1, for: .normal)
            setTitleColor(.gray, for: .highlighted)
            backgroundColor = AdaptiveColors._N9
        case .secondary:
            setTitleColor(AdaptiveTextColors._N5, for: .normal)
            setTitleColor(.gray, for: .highlighted)
            backgroundColor = AdaptiveColors._N1
        }
    }
}
