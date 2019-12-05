//
//  LabelCell.swift
//  ProtonMail - Created on 2/7/19.
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
    

import UIKit

class LabelCell: UICollectionViewCell {

    @IBOutlet weak var label: UILabel!
    
    /// expose this later
    private static let font = Fonts.h6.light
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.label.sizeToFit()
        self.label.clipsToBounds = true
        self.label.layer.borderWidth = 1
        self.label.layer.cornerRadius = 2
        self.label.font = LabelCell.font
    }

    func config(color: String, text: String) {
        self.label.text = LabelCell.buildText(text)
        self.label.textColor = UIColor(hexString: color, alpha: 1.0)
        self.label.layer.borderColor = UIColor(hexString: color, alpha: 1.0).cgColor
    }
    
    func size() -> CGSize {
        return self.label.sizeThatFits(CGSize.zero)
    }
    
    class private func buildText(_ text: String) -> String {
        if text.isEmpty {
            return text
        }
        return "  \(text)  "
    }
    
    class func estimateSize(_ text: String) -> CGSize {
         let size = buildText(text).size(withAttributes: [NSAttributedString.Key.font: font])
        
        return size
    }
    
}
