//
//  AttachmentTableViewCell.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation
import MCSwipeTableViewCell

class AttachmentTableViewCell: MCSwipeTableViewCell {
    struct Constant {
        static let identifier = "AttachmentTableViewCell"
    }
    
    private(set) var filename: String?
    @IBOutlet weak var downloadIcon: UIImageView!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var attachmentIcon: UIImageView!
    
    func setFilename(_ filename: String, fileSize: Int) {
        self.filename = filename
        let byteCountFormatter = ByteCountFormatter()
        fileNameLabel.text = "\(filename) (\(byteCountFormatter.string(fromByteCount: Int64(fileSize))))"
    }
    
    
    func configCell ( _ filename : String, fileSize : Int, showDownload : Bool = false) {
        self.filename = filename
        let byteCountFormatter = ByteCountFormatter()
        fileNameLabel.text = "\(filename) (\(byteCountFormatter.string(fromByteCount: Int64(fileSize))))"
        
        if showDownload {
            downloadIcon.isHidden = false
        } else {
            downloadIcon.isHidden = true
        }
    }
    
    func configAttachmentIcon (_ mimeType : String) {
        //TODO:: sometime see general mime type like "application/octet-stream" then need parse the extention to get types
        //PMLog.D(mimeType)
        var image : UIImage;
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
