//
//  LabelTableViewCell.swift
//  ProtonMail - Created on 8/17/15.
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

internal typealias EditAction = (_ sender: LabelTableViewCell) -> Void

class LabelTableViewCell: UITableViewCell, AccessibleCell {
    var model : LabelMessageModel!
    let maxLabelCount : Int = 100

    var editLabelAction : EditAction?
    
    @IBOutlet weak var labelView: TableCellLabelView!
    @IBOutlet weak var selectStatusButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var labelIcon: UIImageView!
    @IBOutlet weak var labelleft: NSLayoutConstraint!
    @IBOutlet weak var labelWidth: NSLayoutConstraint!
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.zeroMargin()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.labelView.updateTextFont(Fonts.s20.light)
        selectStatusButton.isEnabled = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func buttonAction(_ sender: UIButton) {

    }
    
    @IBAction func editAction(_ sender: UIButton) {
        editLabelAction?(self)
    }
    
    func updateStatusButton () {
        switch self.model.currentStatus {
        case 0:
            selectStatusButton.setImage(UIImage(named:"mail_check"), for: UIControl.State())
            break
        case 1:
            selectStatusButton.setImage(UIImage(named:"mail_check-neutral"), for: UIControl.State())
            break
        case 2:
            selectStatusButton.setImage(UIImage(named:"mail_check-active"), for: UIControl.State())
            break
        default:
            selectStatusButton.setImage(UIImage(named:"mail_check"), for: UIControl.State())
            break
        }
    }
    
    func ConfigCell(model : LabelMessageModel!, showIcon : Bool, showEdit : Bool, editAction : EditAction?) {
        self.editLabelAction = editAction
        self.model = model
        if model.label.managedObjectContext != nil {
            var offset : CGFloat = 30
            if showIcon {
                offset += 16
                labelIcon.isHidden = false
                labelleft.priority = UILayoutPriority(rawValue: 500)
                let color = UIColor(hexString: model.label.color, alpha:1)
                var image = UIImage(named: "menu_label")
                if model.label.exclusive {
                    image = UIImage(named: "menu_folder")
                }
                
                labelIcon.image = image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
                labelIcon.highlightedImage = image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
                labelIcon.tintColor = color
            } else {
                labelIcon.isHidden = true
                labelleft.priority = UILayoutPriority(rawValue: 900)
            }
            
            if showEdit {
                offset += 52
                editButton.isHidden = false
                editButton.isEnabled = true
                
                if model.label.exclusive {
                    editButton.setImage(UIImage(named: "folder_edit-active"), for: .normal)
                    editButton.setImage(UIImage(named: "folder_edit"), for: .highlighted)
                } else {
                    editButton.setImage(UIImage(named: "label_edit-active"), for: .normal)
                    editButton.setImage(UIImage(named: "label_edit"), for: .highlighted)
                }
                
            } else {
                editButton.isHidden = true
                editButton.isEnabled = false
            }
            
            var name = model.label.name
            var color =  UIColor(hexString: model.label.color, alpha: 1.0)
            if let location = Message.Location.init(rawValue: model.label.labelID) {
                name = location.title
                color = .black
            }
            
            let w = labelView.setText(name, color: color)
            let check = self.frame.width - offset
            
            labelWidth.constant = w > check ? check : w
            generateCellAccessibilityIdentifiers(name)
        }
        
        self.updateStatusButton()
    }
}
