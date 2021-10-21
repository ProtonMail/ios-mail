//
//  AttachmentTableViewCell.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
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

import Foundation
import MCSwipeTableViewCell

class AttachmentTableViewCell: MCSwipeTableViewCell {
    enum Constant {
        static let identifier = "AttachmentTableViewCell"
    }

    private(set) var filename: String?
    @IBOutlet var downloadIcon: UIImageView!
    @IBOutlet var fileNameLabel: UILabel!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var attachmentIcon: UIImageView!
    @IBOutlet var spinnerView: UIActivityIndicatorView!

    func setFilename(_ filename: String, fileSize: Int) {
        self.filename = filename
        let byteCountFormatter = ByteCountFormatter()
        fileNameLabel.text = "\(filename) (\(byteCountFormatter.string(fromByteCount: Int64(fileSize))))"
    }

    func configCell(_ filename: String, fileSize: Int, showDownload: Bool = false, showSpinner: Bool = false) {
        self.filename = filename
        let byteCountFormatter = ByteCountFormatter()
        fileNameLabel.text = "\(filename) (\(byteCountFormatter.string(fromByteCount: Int64(fileSize))))"

        if showDownload {
            downloadIcon.isHidden = false
        } else {
            downloadIcon.isHidden = true
        }

        if showSpinner {
            spinnerView.startAnimating()
            isUserInteractionEnabled = false
        }
    }

    func stopSpinner() {
        spinnerView.stopAnimating()
        isUserInteractionEnabled = true
    }

    func configAttachmentIcon(_ mimeType: String) {
        // TODO: sometime see general mime type like "application/octet-stream" then need parse the extention to get types
        // PMLog.D(mimeType)
        var image: UIImage
        if mimeType == "image/jpeg" || mimeType == "image/jpg" {
            image = UIImage(named: "mail_attachment-jpeg")!
        } else if mimeType == "image/png" {
            image = UIImage(named: "mail_attachment-png")!
        } else if mimeType == "application/zip" {
            image = UIImage(named: "mail_attachment-zip")!
        } else if mimeType == "application/pdf" {
            image = UIImage(named: "mail_attachment-pdf")!
        } else if mimeType == "text/plain" {
            image = UIImage(named: "mail_attachment-txt")!
        } else if mimeType == "application/msword" {
            image = UIImage(named: "mail_attachment-doc")!
        } else {
            image = UIImage(named: "mail_attachment-file")!
        }

        attachmentIcon.image = image
        attachmentIcon.highlightedImage = image
    }
}
