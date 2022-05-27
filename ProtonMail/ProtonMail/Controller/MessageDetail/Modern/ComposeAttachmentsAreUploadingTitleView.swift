// Copyright (c) 2021 Proton AG
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
        label.attributedText = LocalString._attachmets_are_uploading_info
            .apply(style: FontManager.Caption.alignment(.right))
    }

    private func setUpLayout() {
        [
            label.topAnchor.constraint(equalTo: topAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ].activate()
    }

    required init?(coder: NSCoder) {
        nil
    }

}
