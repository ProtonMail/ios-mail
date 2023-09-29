// Copyright (c) 2023 Proton Technologies AG
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

class SettingsGeneralImageCell: SettingsGeneralCell {
    @IBOutlet private weak var leftImageView: UIImageView!

    override func prepareForReuse() {
        super.prepareForReuse()
        leftImageView.image = nil
    }

    func configure(left: String, right: String, leftImage: UIImage?) {
        super.configureCell(left: left, right: right, imageType: .arrow, stackViewDistribution: .equalSpacing)
        leftImageView.image = leftImage
    }
}
