//
//  AttachmentListTableViewCell.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations
import UIKit

class AttachmentListTableViewCell: UITableViewCell {

    static var CellID: String {
        return "\(self)"
    }

    @IBOutlet private weak var fileIconView: UIImageView!
    @IBOutlet private weak var fileNameLabel: UILabel!
    @IBOutlet private weak var fileSizeLabel: UILabel!
    @IBOutlet private weak var arrowIconView: UIImageView!
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView!

    override func awakeFromNib() {
        super.awakeFromNib()

        setupView()
    }

    private func setupView() {
        backgroundColor = ColorProvider.BackgroundNorm

        arrowIconView.image = IconProvider.chevronRight.withRenderingMode(.alwaysTemplate)
        arrowIconView.tintColor = ColorProvider.TextNorm

        addSeparator(padding: 0)

        fileNameLabel.set(text: nil, preferredFont: .body)
        fileSizeLabel.set(text: nil, preferredFont: .subheadline)
    }

    func configure(type: AttachmentType,
                   fileName: String,
                   fileSize: String,
                   isDownloading: Bool) {
        fileIconView.image = type.bigIcon
        fileIconView.tintColor = ColorProvider.TextNorm

        fileNameLabel.text = fileName
        fileSizeLabel.text = fileSize
        if isDownloading {
            arrowIconView.isHidden = true
            loadingIndicator.startAnimating()
            fileNameLabel.textColor = ColorProvider.TextDisabled
            fileSizeLabel.textColor = ColorProvider.TextDisabled
        } else {
            arrowIconView.isHidden = false
            loadingIndicator.stopAnimating()
            fileNameLabel.textColor = ColorProvider.TextNorm
            fileSizeLabel.textColor = ColorProvider.TextWeak
        }
    }
}
