//
//  ComposerAttachmentCellTableViewCell.swift
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

protocol ComposerAttachmentCellDelegate: AnyObject {
    func clickDeleteButton(for objectID: String)
}

final class ComposerAttachmentCellTableViewCell: UITableViewCell {

    @IBOutlet private var containerView: UIView!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private var fileName: UILabel!
    @IBOutlet private var fileSize: UILabel!
    @IBOutlet private var deleteButton: UIButton!
    @IBOutlet private var iconView: UIImageView!
    private var objectID: String = ""
    private weak var delegate: ComposerAttachmentCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        self.contentView.backgroundColor = .clear
        self.containerView.backgroundColor = UIColorManager.BackgroundNorm
        self.containerView.roundCorner(8)
        self.containerView.layer.borderWidth = 1
        self.containerView.layer.borderColor = UIColorManager.IconDisabled.cgColor
    }

    func config(objectID: String,
                name: String,
                size: Int,
                mime: String,
                isUploading: Bool,
                delegate: ComposerAttachmentCellDelegate?) {
        self.objectID = objectID
        self.deleteButton.tintColor = UIColorManager.IconNorm
        self.delegate = delegate

        var nameAttr = isUploading ? FontManager.DefaultSmallDisabled: .DefaultSmall
        nameAttr.addTruncatingTail(mode: .byTruncatingMiddle)
        self.fileName.attributedText = name.apply(style: nameAttr)

        let sizeAttr = isUploading ? FontManager.CaptionDisabled: FontManager.CaptionHint
        let byteCountFormatter = ByteCountFormatter()
        self.fileSize.attributedText = "\(byteCountFormatter.string(fromByteCount: Int64(size)))".apply(style: sizeAttr)

        let mimeType = MIMEType(rawValue: mime)
        self.iconView.image = isUploading ? nil: mimeType.icon
        isUploading ? self.activityIndicator.startAnimating(): self.activityIndicator.stopAnimating()
    }

    @IBAction private func clickDeleteButton(_ sender: Any) {
        self.delegate?.clickDeleteButton(for: self.objectID)
    }

}
