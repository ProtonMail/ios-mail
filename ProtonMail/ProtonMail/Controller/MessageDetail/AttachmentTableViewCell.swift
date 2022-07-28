//
//  AttachmentTableViewCell.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
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

import Foundation
import MCSwipeTableViewCell

class AttachmentTableViewCell: MCSwipeTableViewCell {
    struct Constant {
        static let identifier = "AttachmentTableViewCell"
    }

    @IBOutlet weak var downloadIcon: UIImageView!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var attachmentIcon: UIImageView!

    func setFilename(_ filename: String, fileSize: Int) {
        let byteCountFormatter = ByteCountFormatter()
        fileNameLabel.text = "\(filename) (\(byteCountFormatter.string(fromByteCount: Int64(fileSize))))"
    }

    func configAttachmentIcon(_ attachmentType: AttachmentType) {
        // TODO:: sometime see general mime type like "application/octet-stream" then need parse the extention to get types
        let image = attachmentType.icon
        attachmentIcon.image = image
        attachmentIcon.highlightedImage = image
    }
}
