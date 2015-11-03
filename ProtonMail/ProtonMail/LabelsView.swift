//
//  LabelsView.swift
//
//
//  Created by Yanfeng Zhang on 10/30/15.
//
//

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
    
    @IBOutlet weak var leftLabelView: UILabel!
    
    @IBOutlet weak var labelConstraint1: NSLayoutConstraint!
    @IBOutlet weak var labelConstraint2: NSLayoutConstraint!
    @IBOutlet weak var labelConstraint3: NSLayoutConstraint!
    @IBOutlet weak var labelConstraint4: NSLayoutConstraint!
    @IBOutlet weak var labelConstraint5: NSLayoutConstraint!
    
    var labels : [Label]?
    var labelViews : [UILabel] = []
    var labelLayoutConstraints : [NSLayoutConstraint] = []
    
    var sender : String = "";
    var inited : Bool = false;
    
    override func drawRect(rect: CGRect) {
        let width = self.frame.width
        if  !self.inited {
            self.inited = true;
            self.update();
        }
    }
    
    override func awakeFromNib() {
        let width = self.frame.width
        let defaultFrame = CGRect(x: 0, y: 0, width: self.frame.width, height: 14)
        
        labelView1.numberOfLines = 0;
        labelView1.layer.borderWidth = 1
        labelView1.layer.cornerRadius = 2
        labelView1.font = UIFont.robotoLight(size: 9)
        labelView1.lineBreakMode = .ByTruncatingTail
        
        labelView2.numberOfLines = 0;
        labelView2.layer.borderWidth = 1
        labelView2.layer.cornerRadius = 2
        labelView2.font = UIFont.robotoLight(size: 9)
        labelView2.lineBreakMode = .ByTruncatingTail
        
        labelView3.numberOfLines = 0;
        labelView3.layer.borderWidth = 1
        labelView3.layer.cornerRadius = 2
        labelView3.font = UIFont.robotoLight(size: 9)
        labelView3.lineBreakMode = .ByTruncatingTail
        
        labelView4.numberOfLines = 0;
        labelView4.layer.borderWidth = 1
        labelView4.layer.cornerRadius = 2
        labelView4.font = UIFont.robotoLight(size: 9)
        labelView4.lineBreakMode = .ByTruncatingTail
        
        labelView5.numberOfLines = 0;
        labelView5.layer.borderWidth = 1
        labelView5.layer.cornerRadius = 2
        labelView5.font = UIFont.robotoLight(size: 9)
        labelView5.lineBreakMode = .ByTruncatingTail
        
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
        
        leftLabelView.textAlignment = .Left
        leftLabelView.font = UIFont.robotoLight(size: UIFont.Size.h6)
        leftLabelView.numberOfLines = 0;
        leftLabelView.textColor = UIColor(hexColorCode: "#838897")
        leftLabelView.lineBreakMode = .ByTruncatingTail
    }
    
    func configLables (leftText : String, labels : [Label]?) {
        self.sender = leftText;
        self.labels = labels;
        
        //if self.inited {
            self.update();
       // }
    }
    
    private func update() {
        let width = self.frame.width
        
        leftLabelView.text =  self.sender
        var leftLabelSize = leftLabelView.sizeThatFits(CGSizeZero).width
        let sizeLimit : CGFloat = width - leftLabelSize
        
        var labelsSize : [CGFloat] = [];
        
        if let labels = self.labels {
            if labels.count > 0 {
                for i in 0 ... 4 {
                    let labelView = labelViews[i]
                    if labels.count > i {
                        
                        let label = labels[i]
                        
                        if label.managedObjectContext == nil {
                            self.hideAll();
                            return ;
                        }
                        
                        labelView.text = "  \(label.name.trim())  "
                        
                        let color = UIColor(hexString: label.color, alpha: 1.0)
                        labelView.textColor = color
                        labelView.layer.borderColor = color.CGColor
                        
                        labelsSize.append(labelView.sizeThatFits(CGSizeZero).width)
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
                    var check : CGFloat = labelsSize[0] + labelsSize[1] + labelsSize[2] + labelsSize[3] + labelsSize[4]
                    let labelView = labelViews[i]
                    let labelConstraint = labelLayoutConstraints[i]
                    if  labels.count == i + 1 {
                        labelConstraint.constant = labelsSize[i]
                    } else {
                        if labels.count > i {
                            var check : CGFloat = labelsSize[0] + labelsSize[1] + labelsSize[2] + labelsSize[3] + labelsSize[4]
                            let labelView = labelViews[i]
                            if check > sizeLimit {
                                labelConstraint.constant = 14.0
                                labelsSize[i] = 14
                            } else {
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
        self.updateConstraintsIfNeeded()
    }
    
    private func hideAll() {
        labelConstraint1.constant = 0;
        labelConstraint2.constant = 0;
        labelConstraint3.constant = 0;
        labelConstraint4.constant = 0;
        labelConstraint5.constant = 0;
    }
    
    private func hideLabelView (labeView : LabelDisplayView) {
        labeView.labelTitle = "";
        labeView.hidden = true;
    }
}
