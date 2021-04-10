//
//  StackViewContainer.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

class StackViewContainer: UIView {

    private let view: UIView
    private let top: CGFloat
    private let leading: CGFloat
    private let trailing: CGFloat
    private let bottom: CGFloat

    init(view: UIView, top: CGFloat = 0, leading: CGFloat = 0, trailing: CGFloat = 0, bottom: CGFloat = 0) {
        self.view = view
        self.top = top
        self.leading = leading
        self.trailing = trailing
        self.bottom = bottom
        super.init(frame: .zero)
        setUpSubviews()
    }

    private func setUpSubviews() {
        addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        [
            view.topAnchor.constraint(equalTo: topAnchor, constant: top),
            view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leading),
            view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: trailing),
            view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: bottom)
        ]
            .activate()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
