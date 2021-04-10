//
//  LabelsView.swift
//  ProtonMail - Created on 10/30/15.
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

class LabelsView: PMView {
    
    override func getNibName() -> String {
        return "LabelsView"
    }
    
    @IBOutlet weak var labelView5: UILabel!
    @IBOutlet weak var labelView4: UILabel!
    @IBOutlet weak var labelView3: UILabel!
    @IBOutlet weak var labelView2: UILabel!
    @IBOutlet weak var labelView1: UILabel!
    
    @IBOutlet weak var image1: UIImageView!
    @IBOutlet weak var image2: UIImageView!
    @IBOutlet weak var image3: UIImageView!
    @IBOutlet weak var image4: UIImageView!
    @IBOutlet weak var image5: UIImageView!
    
    @IBOutlet weak var leftLabelView: UILabel!
    
    @IBOutlet weak var labelConstraint1: NSLayoutConstraint!
    @IBOutlet weak var labelConstraint2: NSLayoutConstraint!
    @IBOutlet weak var labelConstraint3: NSLayoutConstraint!
    @IBOutlet weak var labelConstraint4: NSLayoutConstraint!
    @IBOutlet weak var labelConstraint5: NSLayoutConstraint!
    
    var labels : [Label]?
    var labelViews : [UILabel] = []
    var imageViews : [UIImageView] = []
    var labelLayoutConstraints : [NSLayoutConstraint] = []
    
    var sender : String = ""
    var inited : Bool = false
    
    override func draw(_ rect: CGRect) {
        if  !self.inited {
            self.inited = true
            self.update()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        labelView1.numberOfLines = 0
        labelView1.layer.borderWidth = 1
        labelView1.layer.cornerRadius = 2
        labelView1.font = Fonts.h7.light
        labelView1.lineBreakMode = .byTruncatingTail
        
        labelView2.numberOfLines = 0
        labelView2.layer.borderWidth = 1
        labelView2.layer.cornerRadius = 2
        labelView2.font = Fonts.h7.light
        labelView2.lineBreakMode = .byTruncatingTail
        
        labelView3.numberOfLines = 0
        labelView3.layer.borderWidth = 1
        labelView3.layer.cornerRadius = 2
        labelView3.font = Fonts.h7.light
        labelView3.lineBreakMode = .byTruncatingTail
        
        labelView4.numberOfLines = 0
        labelView4.layer.borderWidth = 1
        labelView4.layer.cornerRadius = 2
        labelView4.font = Fonts.h7.light
        labelView4.lineBreakMode = .byTruncatingTail
        
        labelView5.numberOfLines = 0
        labelView5.layer.borderWidth = 1
        labelView5.layer.cornerRadius = 2
        labelView5.font = Fonts.h7.light
        labelView5.lineBreakMode = .byTruncatingTail
        
        labelViews.append(labelView1)
        labelViews.append(labelView2)
        labelViews.append(labelView3)
        labelViews.append(labelView4)
        labelViews.append(labelView5)
        
        labelLayoutConstraints.append(labelConstraint1)
        labelLayoutConstraints.append(labelConstraint2)
        labelLayoutConstraints.append(labelConstraint3)
        labelLayoutConstraints.append(labelConstraint4)
        labelLayoutConstraints.append(labelConstraint5)
        
        imageViews.append(image1)
        imageViews.append(image2)
        imageViews.append(image3)
        imageViews.append(image4)
        imageViews.append(image5)
        
        leftLabelView.textAlignment = .left
        leftLabelView.font = Fonts.h6.light
        leftLabelView.numberOfLines = 1
        leftLabelView.textColor = UIColor(hexColorCode: "#838897")
        leftLabelView.lineBreakMode = .byTruncatingTail
    }
    
    func configLables (_ leftText : String, labels : [Label]?) {
        self.sender = leftText
        var tmplabels : [Label] = []
        if let alllabels = labels {
            for l in alllabels {
                if l.type == 1 {
                    tmplabels.append(l)
                }
            }
        }
        self.labels = tmplabels
        
        self.update()
    }
    
    fileprivate func update() {
        let width = self.frame.width
        
        leftLabelView.text =  self.sender
        let leftLabelSize = leftLabelView.sizeThatFits(CGSize.zero).width
        let sizeLimit : CGFloat = width - leftLabelSize
        
        var labelsSize : [CGFloat] = []
        
        if let labels = self.labels {
            if labels.count > 0 {
                for i in 0 ... 4 {
                    let labelView = labelViews[i]
                    let imageView = imageViews[i]
                    if labels.count > i {
                        
                        let label = labels[i]
                        
                        if label.managedObjectContext == nil {
                            self.hideAll()
                            return
                        }
                        labelView.text = "  \(label.name.trim())  "
                        let color = label.color.isEmpty ? UIColor.white : UIColor(hexString: label.color, alpha: 1.0)
                        labelView.textColor = color
                        labelView.layer.borderColor = color.cgColor
                        
                        let image = UIImage(named: "mail_label-collapsed")
                        imageView.image = image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
                        imageView.highlightedImage = image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
                        imageView.tintColor = color
                        
                        labelsSize.append(labelView.sizeThatFits(CGSize.zero).width)
                    } else {
                        labelView.text = ""
                        labelsSize.append(0)
                    }
                }
            }
        }
        if let labels = self.labels {
            if labels.count > 0 {
                for i in 0 ... 4 {
                    let check : CGFloat = labelsSize[0] + labelsSize[1] + labelsSize[2] + labelsSize[3] + labelsSize[4]
                    let labelView = labelViews[i]
                    let imageView = imageViews[i]
                    
                    let labelConstraint = labelLayoutConstraints[i]
                    if  labels.count == i + 1 {
                        labelView.isHidden = false
                        imageView.isHidden = true
                        labelConstraint.constant = labelsSize[i]
                    } else {
                        if labels.count > i {
                            if check > sizeLimit {
                                if let text = labelView.text?.trim(), text.count > 0 {
                                    labelView.text = "  " + text[0] + "  "
                                }
                                
                                labelView.isHidden = true
                                imageView.isHidden = false
                                labelConstraint.constant = 14.0
                                labelsSize[i] = 14
                            } else {
                                labelView.isHidden = false
                                imageView.isHidden = true
                                labelConstraint.constant = labelsSize[i]
                            }
                        } else {
                            labelConstraint.constant = labelsSize[i]
                        }
                    }
                }
            } else {
                self.hideAll()
            }
        } else {
            self.hideAll()
        }
        self.layoutIfNeeded()
        //self.updateConstraintsIfNeeded()
    }
    
    fileprivate func hideAll() {
        labelConstraint1.constant = 0
        labelConstraint2.constant = 0
        labelConstraint3.constant = 0
        labelConstraint4.constant = 0
        labelConstraint5.constant = 0
    }
    
    fileprivate func hideLabelView (_ labeView : LabelDisplayView) {
        labeView.labelTitle = ""
        labeView.isHidden = true
    }
}
