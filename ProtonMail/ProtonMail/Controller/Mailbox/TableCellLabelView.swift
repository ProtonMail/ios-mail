//
//  TableCellLabelView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/16/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class TableCellLabelView: UIView {
    fileprivate let kCoverImageViewWidth : CGFloat = 3.0
    
    fileprivate var textLabel:UILabel!
    fileprivate var contentView : UIView!
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        contentView = UIView(frame: CGRect(x: 0,y: 0, width: 50, height: 13))
        textLabel = UILabel(frame: CGRect(x: 0,y: 0, width: 50, height: 13))
        
        textLabel.text = ""
        textLabel.textColor = UIColor.green
        textLabel.layer.borderWidth = 1
        textLabel.layer.cornerRadius = 2
        textLabel.layer.borderColor = UIColor.green.cgColor
        textLabel.font = Fonts.h7.light
        self.contentView.addSubview(textLabel)
        self.addSubview(contentView)
        
        textLabel.mas_makeConstraints { (make) -> Void in
            let _ = make?.top.equalTo()(self.contentView)
            let _ = make?.bottom.equalTo()(self.contentView)
            let _ = make?.right.equalTo()(self.contentView)
            let _ = make?.left.equalTo()(self.contentView)
        }
        
        contentView.mas_makeConstraints { (make) -> Void in
            let _ = make?.top.equalTo()(self)
            let _ = make?.bottom.equalTo()(self)
            let _ = make?.left.equalTo()(self)?.offset()(self.kCoverImageViewWidth)
            let _ = make?.right.equalTo()(self)
        }
        self.clipsToBounds = true
        self.contentView.clipsToBounds = true
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    func updateTextFont (_ font: UIFont){
        self.textLabel.font = font;
    }
    
    func setText(_ label: String, color: UIColor) ->CGFloat {
        self.textLabel.text = "  \(label)  "

        let s = self.textLabel.sizeThatFits(CGSize.zero)
                textLabel.textColor = color
        textLabel.layer.borderColor = color.cgColor
        
        return s.width + self.kCoverImageViewWidth;
    }    
}
