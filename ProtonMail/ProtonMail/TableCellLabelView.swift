//
//  TableCellLabelView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/16/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class TableCellLabelView: UIView {
    private var textLabel:UILabel!
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        textLabel = UILabel(frame: CGRect(x: 0,y: 0, width: 50, height: 20))
        
        textLabel.text = ""
        textLabel.textColor = UIColor.greenColor()
        textLabel.layer.borderWidth = 1.0
        textLabel.layer.borderColor = UIColor.greenColor().CGColor
        textLabel.font = UIFont.robotoLight(size: 12)
        self.addSubview(textLabel)
        
        
        textLabel.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self)
            make.bottom.equalTo()(self)
            make.right.equalTo()(self)
            make.left.equalTo()(self).offset() //(-5)
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    
    func setText(label  :  String, color : UIColor) ->CGFloat {
        self.textLabel.text = label;
        let s = self.textLabel.sizeThatFits(CGSizeZero)
        
        textLabel.textColor = color
        textLabel.layer.borderColor = color.CGColor
        return s.width;
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    
    

}
