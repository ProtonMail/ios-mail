//
//  DraftTableViewCell.swift
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
import UIKit

class DraftTableViewCell: UITableViewCell {

    @IBOutlet weak var subjectLabel: UILabel!
    
    var subject: String {
        get {
            return subjectLabel.text ?? resetSubject()
        }
        set {
            subjectLabel.text = !newValue.isEmpty ? newValue : NSLocalizedString("No Subject")
        }
    }
    
    override func awakeFromNib() {
        subject = resetSubject()
        selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = UIColor.ProtonMail.Blue_5C7A99
    }
    
    override func prepareForReuse() {
        subject = resetSubject()
    }
    
    // MARK: - Private methods
    
    private func resetSubject() -> String {
        return ""
    }
}
