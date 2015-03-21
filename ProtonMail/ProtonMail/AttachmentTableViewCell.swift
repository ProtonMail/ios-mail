//
//  AttachmentTableViewCell.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

class AttachmentTableViewCell: UITableViewCell {
    struct Constant {
        static let identifier = "AttachmentTableViewCell"
    }
    
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    func setFilename(filename: String, fileSize: Int) {
        let byteCountFormatter = NSByteCountFormatter()
        fileNameLabel.text = "\(filename) (\(byteCountFormatter.stringFromByteCount(Int64(fileSize))))"
    }
}
