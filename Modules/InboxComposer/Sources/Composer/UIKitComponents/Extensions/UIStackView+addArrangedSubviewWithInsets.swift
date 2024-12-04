// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import UIKit

extension UIStackView {

    func addArrangedSubviewWithInsets(_ view: UIView, insets: UIEdgeInsets)
    {
        let container = UIView()
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: insets.left),
            view.topAnchor.constraint(equalTo: container.topAnchor, constant: insets.top),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: insets.right),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: insets.bottom),
        ])
        addArrangedSubview(container)
    }
}
