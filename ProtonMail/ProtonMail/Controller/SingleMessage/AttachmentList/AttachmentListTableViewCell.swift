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
    }

    func configure(type: AttachmentType,
                   fileName: String,
                   fileSize: String,
                   isDownloading: Bool) {
        fileIconView.image = type.bigIcon
        fileIconView.tintColor = ColorProvider.TextNorm

        var fileNameAttribute = FontManager.Default
        var fileSizeAttribute = FontManager.DefaultSmallWeak
        if isDownloading {
            arrowIconView.isHidden = true
            loadingIndicator.startAnimating()

            fileNameAttribute = FontManager.DefaultDisabled
            fileSizeAttribute = FontManager.DefaultSmallDisabled
        } else {
            arrowIconView.isHidden = false
            loadingIndicator.stopAnimating()
        }

        fileNameAttribute = fileNameAttribute.addTruncatingTail()
        fileNameLabel.attributedText = NSAttributedString(string: fileName, attributes: fileNameAttribute)

        fileSizeAttribute = fileSizeAttribute.addTruncatingTail()
        fileSizeLabel.attributedText = NSAttributedString(string: fileSize, attributes: fileSizeAttribute)
    }
}
