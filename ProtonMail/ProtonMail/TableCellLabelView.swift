//
//  TableCellLabelView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/16/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class TableCellLabelView: UIView {
    private let kCoverImageViewWidth : CGFloat = 3.0
    
    private var textLabel:UILabel!
    private var contentView : UIView!
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        contentView = UIView(frame: CGRect(x: 0,y: 0, width: 50, height: 13))
        textLabel = UILabel(frame: CGRect(x: 0,y: 0, width: 50, height: 13))
        
        textLabel.text = ""
        textLabel.textColor = UIColor.greenColor()
        textLabel.layer.borderWidth = 1
        textLabel.layer.cornerRadius = 2
        textLabel.layer.borderColor = UIColor.greenColor().CGColor
        textLabel.font = UIFont.robotoLight(size: 9)
        self.contentView.addSubview(textLabel)
        self.addSubview(contentView)
        
        textLabel.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.contentView)
            make.bottom.equalTo()(self.contentView)
            make.right.equalTo()(self.contentView)
            make.left.equalTo()(self.contentView)
        }
        
        contentView.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self)
            make.bottom.equalTo()(self)
            make.left.equalTo()(self).offset()(self.kCoverImageViewWidth)
            make.right.equalTo()(self)
        }
        self.clipsToBounds = true
        self.contentView.clipsToBounds = true
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    func updateTextFont (font: UIFont){
        self.textLabel.font = font;
    }
    
    func setText(label: String, color: UIColor) ->CGFloat {
        self.textLabel.text = "  \(label)  "

        let s = self.textLabel.sizeThatFits(CGSizeZero)
                textLabel.textColor = color
        textLabel.layer.borderColor = color.CGColor
        
        return s.width + self.kCoverImageViewWidth;
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
}
