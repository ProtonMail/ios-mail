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
    //var labels : [String] = ["akfj", "adsfasdfasdf", "adsfasdfsadf", "asdfasfasdfasdf","asdfasfasdf"]
    
    var leftLabel : UILabel!
    var labelViews : [LabelDisplayView] = []
    
    
    override func awakeFromNib() {
        //labelViews.removeAll()
        leftLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 14))
        leftLabel.textAlignment = .Left
        leftLabel.font = UIFont.robotoLight(size: UIFont.Size.h6)
        leftLabel.numberOfLines = 0;
        leftLabel.textColor = UIColor(hexColorCode: "#838897")
        self.addSubview(leftLabel)
        
        var labelView = LabelDisplayView(frame: CGRect(x: 0, y: 0, width: 14, height: 14))
        labelView.hidden = true;
        self.addSubview(labelView)
        labelViews.append(labelView)
        labelView.mas_updateConstraints { (make) -> Void in
            make.removeExisting = true
            make.right.equalTo()(self.mas_left)
            make.bottom.equalTo()(self.mas_bottom)
            make.top.equalTo()(self.mas_top)
        }
        
        labelView = LabelDisplayView(frame: CGRect(x: 0, y: 0, width: 14, height: 14))
        labelView.hidden = true;
        self.addSubview(labelView)
        labelViews.append(labelView)
        
        labelView = LabelDisplayView(frame: CGRect(x: 0, y: 0, width: 14, height: 14))
        labelView.hidden = true;
        self.addSubview(labelView)
        labelViews.append(labelView)
        
        labelView = LabelDisplayView(frame: CGRect(x: 0, y: 0, width: 14, height: 14))
        labelView.hidden = true;
        self.addSubview(labelView)
        labelViews.append(labelView)
        
        labelView = LabelDisplayView(frame: CGRect(x: 0, y: 0, width: 14, height: 14))
        labelView.hidden = true;
        self.addSubview(labelView)
        labelViews.append(labelView)
        
    }
    
    func configLables (leftText : String, labels : [Label]) {
        
        for (let labelView : LabelDisplayView) in labelViews {
            labelView.hidden = true;
        }
        
        let width = self.frame.width
        
        leftLabel.text = leftText
        //var leftLabelSize = leftLabel.sizeThatFits(CGSizeZero).width
        //leftLabel.sizeToFit()
        
       // if let labels = labels {
            if labels.count > 0 {
                //let sizeLimit : CGFloat = width - leftLabelSize
                var right = self.frame.width
                
                let labelA = labelViews[0]
                let label = labels[0]
                
                labelA.hidden = false;
                labelA.labelTitle = label.name
                labelA.LabelTintColor = UIColor(hexString: label.color, alpha: 1.0)
                
                var leftLabelSize = labelA.sizeThatFits(CGSizeZero).width
                //labelA.sizeToFit();
                
                var f = labelA.frame
                f.origin = CGPoint(x: right - leftLabelSize, y: 0)
                //f.size.width = labelSize1
                labelA.frame = f
                right = f.origin.x
            }
        //}
        
       
        
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
        
    }
    
}
