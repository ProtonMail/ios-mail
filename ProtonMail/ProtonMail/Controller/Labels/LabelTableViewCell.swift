//
//  LabelTableViewCell.swift
//  ProtonMail - Created on 8/17/15.
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


import UIKit

internal typealias EditAction = (_ sender: LabelTableViewCell) -> Void

class LabelTableViewCell: UITableViewCell {
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
        }
        self.updateStatusButton()
    }
}
