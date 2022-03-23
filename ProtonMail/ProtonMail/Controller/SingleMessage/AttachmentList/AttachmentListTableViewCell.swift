//
//  AttachmentListTableViewCell.swift
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

        arrowIconView.image = Asset.cellRightArrow.image.withRenderingMode(.alwaysTemplate)
        arrowIconView.tintColor = ColorProvider.TextNorm

        addSeparator(padding: 0)
    }

    func configure(mimeType: String,
                   fileName: String,
                   fileSize: String,
                   isDownloading: Bool) {
        let type = MIMEType(rawValue: mimeType)
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
