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

import PMUIFoundations
import UIKit

class AttachmentListTableViewCell: UITableViewCell {

    static var CellID: String {
        return "\(self)"
    }

    enum FileType {
        case general
        case pdf
        case jpg

        var image: UIImage {
            switch self {
            case .general:
                return Asset.mailAttachmentGeneral.image
            case .pdf:
                return Asset.mailAttachmentPdfNew.image
            case .jpg:
                return Asset.mailAttachmentJpg.image
            }
        }

        init(mimeType: String) {
            switch mimeType {
            case "image/jpeg", "image/jpg":
                self = .jpg
            case "application/pdf":
                self = .pdf
            default:
                self = .general
            }
        }
    }

    @IBOutlet private weak var fileIconView: UIImageView!
    @IBOutlet private weak var fileNameLabel: UILabel!
    @IBOutlet private weak var fileSizeLabel: UILabel!
    @IBOutlet private weak var arrowIconView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        setupView()
    }

    private func setupView() {
        backgroundColor = UIColorManager.BackgroundNorm

        arrowIconView.image = Asset.cellRightArrow.image.withRenderingMode(.alwaysTemplate)
        arrowIconView.tintColor = UIColorManager.TextNorm

        addSeparator(padding: 0)
    }

    func configure(mimeType: String, fileName: String, fileSize: String) {
        let type = MIMEType(rawValue: mimeType)
        fileIconView.image = type.bigIcon
        fileIconView.tintColor = UIColorManager.TextNorm

        var fileNameAttribute = FontManager.Default
        fileNameAttribute.addTruncatingTail()
        fileNameLabel.attributedText = NSAttributedString(string: fileName, attributes: fileNameAttribute)

        var fileSizeAttribute = FontManager.DefaultSmallWeak
        fileSizeAttribute.addTruncatingTail()
        fileSizeLabel.attributedText = NSAttributedString(string: fileSize, attributes: fileSizeAttribute)
    }
}
