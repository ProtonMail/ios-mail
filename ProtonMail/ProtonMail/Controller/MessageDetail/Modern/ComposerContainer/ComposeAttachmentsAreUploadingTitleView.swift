// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import UIKit

class ComposeAttachmentsAreUploadingTitleView: UIView {

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        addSubviews()
        setUpLayout()
    }

    override var intrinsicContentSize: CGSize {
        UIView.layoutFittingExpandedSize
    }

    private let label = UILabel(frame: .zero)

    private func addSubviews() {
        addSubview(label)
        label.numberOfLines = 2
        label.textAlignment = .right
        label.text = LocalString._attachmets_are_uploading_info
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 13.0)
    }

    private func setUpLayout() {
        [
            label.topAnchor.constraint(equalTo: topAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ].forEach { constraint in
            constraint.isActive = true
            guard let view = constraint.firstItem as? UIView,
                  view.translatesAutoresizingMaskIntoConstraints else { return }
            view.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    required init?(coder: NSCoder) {
        nil
    }

}
