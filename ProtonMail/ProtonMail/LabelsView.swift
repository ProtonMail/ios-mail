//
//  LabelsView.swift
//
//
//  Created by Yanfeng Zhang on 10/30/15.
//
//

import UIKit

class LabelsView: UIView {
    //var leftText : String = "a1hj1hhjkjkasdfljas"
    var labels : [Label]? //["akfj", "adsfasdfasdf", "adsfasdfsadf", "asdfasfasdfasdf","asdfasfasdf"]
    
    var leftLabel : UILabel!
    var labelViews : [LabelDisplayView] = []
    
    var sender : String = "";
    
    var inited : Bool = false;
    
    override func drawRect(rect: CGRect) {
        let width = self.frame.width
//        if !self.inited {
            self.inited = true;
            self.update();
//        }
    }
    
    override func awakeFromNib() {
        let width = self.frame.width

        
        var labelView1 = UILabel(frame: CGRect(x: 0, y: 0, width: 14, height: 14))
        labelView1.hidden = true;
        self.addSubview(labelView1)
        labelViews.append(labelView1)
//        labelView1.mas_updateConstraints { (make) -> Void in
//            make.removeExisting = true
//            make.right.equalTo()(self.mas_right)
//            make.bottom.equalTo()(self.mas_bottom)
//            make.top.equalTo()(self.mas_top)
//        }
        
        var labelView2 = LabelDisplayView(frame: CGRect(x: 0, y: 0, width: 14, height: 14))
        labelView2.hidden = true;
        self.addSubview(labelView2)
        labelViews.append(labelView2)
        labelView2.mas_updateConstraints { (make) -> Void in
            make.removeExisting = true
            make.right.equalTo()(labelView1.mas_left)
            make.bottom.equalTo()(self.mas_bottom)
            make.top.equalTo()(self.mas_top)
        }

        var labelView3 = LabelDisplayView(frame: CGRect(x: 0, y: 0, width: 14, height: 14))
        labelView3.hidden = true;
        self.addSubview(labelView3)
        labelViews.append(labelView3)
        labelView3.mas_updateConstraints { (make) -> Void in
            make.removeExisting = true
            make.right.equalTo()(labelView2.mas_left)
            make.bottom.equalTo()(self.mas_bottom)
            make.top.equalTo()(self.mas_top)
        }

        
        var labelView4 = LabelDisplayView(frame: CGRect(x: 0, y: 0, width: 14, height: 14))
        labelView4.hidden = true;
        self.addSubview(labelView4)
        labelViews.append(labelView4)
        labelView4.mas_updateConstraints { (make) -> Void in
            make.removeExisting = true
            make.right.equalTo()(labelView3.mas_left)
            make.bottom.equalTo()(self.mas_bottom)
            make.top.equalTo()(self.mas_top)
        }

        var labelView5 = LabelDisplayView(frame: CGRect(x: 0, y: 0, width: 14, height: 14))
        labelView5.hidden = true;
        self.addSubview(labelView5)
        labelViews.append(labelView5)
        labelView5.mas_updateConstraints { (make) -> Void in
            make.removeExisting = true
            make.right.equalTo()(labelView4.mas_left)
            make.bottom.equalTo()(self.mas_bottom)
            make.top.equalTo()(self.mas_top)
        }

        leftLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 14))
        leftLabel.textAlignment = .Left
        leftLabel.font = UIFont.robotoLight(size: UIFont.Size.h6)
        leftLabel.numberOfLines = 0;
        leftLabel.textColor = UIColor(hexColorCode: "#838897")
        leftLabel.lineBreakMode = .ByTruncatingTail
        self.addSubview(leftLabel)
    }
    
    func configLables (leftText : String, labels : [Label]?) {
        self.sender = leftText;
        self.labels = labels;
        
        if self.inited {
            self.update();
        }
    }
    
    private func update() {
        leftLabel.text = self.sender
        var leftLabelSize = leftLabel.sizeThatFits(CGSizeZero).width
        //leftLabel.sizeToFit();
        
        self.hideAll()
        self.layoutIfNeeded()
        self.updateConstraintsIfNeeded()
        
        let viewWidth = self.frame.width
        let sizeLimit : CGFloat = viewWidth - leftLabelSize
        var right = self.frame.width
        
        
        var labelsSize : [CGFloat] = [];
        
        if let labels = self.labels {
            if labels.count > 0 {
                for i in 0 ... 4 {
                    let labelView = labelViews[i]
                    if labels.count > i {
                        let label = labels[i]
                        
                        labelView.hidden = false;
                        labelView.labelTitle = label.name
                        labelView.LabelTintColor = UIColor(hexString: label.color, alpha: 1.0)
                        self.layoutIfNeeded()
                        self.updateConstraintsIfNeeded()
                        let labelViewSize = labelView.frame.width;
                        labelsSize.append(labelViewSize)
                    } else {
                        labelsSize.append(0)
                        self.hideLabelView(labelView)
                    }
                }
            }
        }
        
        if let labels = self.labels {
            if labels.count > 0 {
                for i in 0 ... 4 {
                    
                    if labels.count == (i + 1) {
                        break;
                    }
                    
                    var check : CGFloat = labelsSize[0] + labelsSize[1] + labelsSize[2] + labelsSize[3] + labelsSize[4]
                    let labelView = labelViews[i]
                    
                    if check > sizeLimit {
                        //labelView.setIcon(UIColor.redColor())
                        labelsSize[0] = labelView.frame.width
                    }
                }
            } else {
                self.hideAll()
            }
        } else {
            self.hideAll()
        }
        
//        var newWidth : CGFloat = viewWidth - (labelsSize.count > 0 ? (labelsSize[0] + labelsSize[1] + labelsSize[2] + labelsSize[3] + labelsSize[4]) : 0);
//        var f = leftLabel.frame
//        f.origin.x = 0
//        f.origin.y = 0
//        f.size.width = newWidth < 0 ? leftLabelSize : newWidth;
//        leftLabel.frame = f
//
//        
        self.layoutIfNeeded()
        self.updateConstraintsIfNeeded()
        
    }
    
    private func hideAll() {
        for i in 0 ... 4 {
            let labelView = labelViews[0]
            self.hideLabelView(labelView)
        }
    }
    
    private func hideLabelView (labeView : LabelDisplayView) {
        labeView.labelTitle = "";
        labeView.hidden = true;
    }
    
    
    
    
    
    
    //        var check : CGFloat = labelSize1 + labelSize2 + labelSize3 + labelSize4 + labelSize5
    //        if check > sizeLimit{
    //            var f = label5.frame
    //            f.origin = CGPoint(x: right - 15, y: 6.75)
    //            f.size.width = 15
    //            label5.frame = f
    //            right = f.origin.x
    //        } else {
    //            var f = label5.frame
    //            f.origin = CGPoint(x: right - labelSize5, y: 6.75)
    //            f.size.width = labelSize5
    //            label5.frame = f
    //            right = f.origin.x
    //        }
    
    
    
    //        var f = leftLabel.frame
    //        f.origin = CGPoint(x: 0, y: 0)
    //        f.size.width = right
    //        leftLabel.frame = f
    
    //        var leftLabel = UILabel(frame: self.frame)
    //        leftLabel.textAlignment = .Left
    //        leftLabel.font = UIFont(name: "Helvetica-Bold", size: 14)
    //        leftLabel.numberOfLines = 0;
    //        leftLabel.textColor = UIColor.blueColor()
    //        leftLabel.text = leftText
    //        var leftLabelSize = leftLabel.sizeThatFits(CGSizeZero).width
    //        self.addSubview(leftLabel)
    //
    //        var label1 = UILabel(frame: self.frame)
    //        label1.textAlignment = .Center
    //        label1.numberOfLines = 0; //will wrap text in new line
    //        label1.font = UIFont(name: "Helvetica-Bold", size: 14)
    //        label1.textColor = UIColor.greenColor()
    //        label1.backgroundColor = UIColor.darkGrayColor()
    //        label1.text = labels[0]
    //        var labelSize1 = label1.sizeThatFits(CGSizeZero).width
    //        self.addSubview(label1)
    //
    //
    //        var label2 = UILabel(frame: self.frame)
    //        label2.textAlignment = .Center
    //        label2.numberOfLines = 0; //will wrap text in new line
    //        label2.font = UIFont(name: "Helvetica-Bold", size: 14)
    //        label2.textColor = UIColor.blueColor()
    //        label2.backgroundColor = UIColor.grayColor()
    //        label2.text = labels[1]
    //        var labelSize2 = label2.sizeThatFits(CGSizeZero).width
    //        self.addSubview(label2)
    //
    //        var label3 = UILabel(frame: self.frame)
    //        label3.textAlignment = .Center
    //        label3.numberOfLines = 0; //will wrap text in new line
    //        label3.font = UIFont(name: "Helvetica-Bold", size: 14)
    //        label3.textColor = UIColor.blueColor()
    //        label3.backgroundColor = UIColor.darkGrayColor()
    //        label3.text = labels[2]
    //        var labelSize3 = label3.sizeThatFits(CGSizeZero).width
    //        self.addSubview(label3)
    //
    //        var label4 = UILabel(frame: self.frame)
    //        label4.textAlignment = .Center
    //        label4.numberOfLines = 0; //will wrap text in new line
    //        label4.font = UIFont(name: "Helvetica-Bold", size: 14)
    //        label4.textColor = UIColor.blueColor()
    //        label4.backgroundColor = UIColor.grayColor()
    //        label4.text = labels[3]
    //        var labelSize4 = label4.sizeThatFits(CGSizeZero).width
    //        self.addSubview(label4)
    //
    //        var label5 = UILabel(frame: self.frame)
    //        label5.textAlignment = .Center
    //        label5.numberOfLines = 0; //will wrap text in new line
    //        label5.font = UIFont(name: "Helvetica-Bold", size: 14)
    //        label5.textColor = UIColor.greenColor()
    //        label5.backgroundColor = UIColor.darkGrayColor()
    //        label5.text = labels[4]
    //        var labelSize5 = label5.sizeThatFits(CGSizeZero).width
    //        self.addSubview(label5)
    //
    //        label1.sizeToFit();
    //        label2.sizeToFit();
    //        label3.sizeToFit();
    //        label4.sizeToFit();
    //        label5.sizeToFit();
    //
    //
    //        var check : CGFloat = labelSize1 + labelSize2 + labelSize3 + labelSize4 + labelSize5
    //        if check > sizeLimit{
    //            var f = label5.frame
    //            f.origin = CGPoint(x: right - 15, y: 6.75)
    //            f.size.width = 15
    //            label5.frame = f
    //            right = f.origin.x
    //        } else {
    //            var f = label5.frame
    //            f.origin = CGPoint(x: right - labelSize5, y: 6.75)
    //            f.size.width = labelSize5
    //            label5.frame = f
    //            right = f.origin.x
    //        }
    //
    //        check = labelSize1 + labelSize2 + labelSize3 + labelSize4 + 15
    //        if check > sizeLimit {
    //            var f = label4.frame
    //            f.origin = CGPoint(x: right - 15, y: 6.75)
    //            f.size.width = 15
    //            label4.frame = f
    //            right = f.origin.x
    //        } else {
    //            var f = label4.frame
    //            f.origin = CGPoint(x: right - labelSize4, y: 6.75)
    //            f.size.width = labelSize4
    //            label4.frame = f
    //            right = f.origin.x
    //        }
    //
    //        check = labelSize1 + labelSize2 + labelSize3 + 15 + 15
    //        if check > sizeLimit {
    //            var f = label3.frame
    //            f.origin = CGPoint(x: right - 15, y: 6.75)
    //            f.size.width = 15
    //            label3.frame = f
    //            right = f.origin.x
    //        } else {
    //            var f = label3.frame
    //            f.origin = CGPoint(x: right - labelSize3, y: 6.75)
    //            f.size.width = labelSize3
    //            label3.frame = f
    //            right = f.origin.x
    //        }
    //
    //        check = labelSize1 + labelSize2 + 15 + 15 + 15
    //        if check > sizeLimit {
    //            var f = label2.frame
    //            f.origin = CGPoint(x: right - 15, y: 6.75)
    //            f.size.width = 15
    //            label2.frame = f
    //            right = f.origin.x
    //        } else {
    //            var f = label2.frame
    //            f.origin = CGPoint(x: right - labelSize2, y: 6.75)
    //            label2.frame = f
    //            right = f.origin.x
    //        }
    //
    //        var f = label1.frame
    //        f.origin = CGPoint(x: right - labelSize1, y: 6.75)
    //        f.size.width = labelSize1
    //        label1.frame = f
    //        right = f.origin.x
    //
    
    // }
    
}
