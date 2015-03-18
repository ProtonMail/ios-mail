//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

protocol MoreOptionsViewDelegate {
    func moreOptionsViewDidMarkAsUnread(moreOptionsView: MoreOptionsView) -> Void
    func moreOptionsViewDidSelectMoveTo(moreOptionsView: MoreOptionsView) -> Void
}

class MoreOptionsView: UIView {
    
    var delegate: MoreOptionsViewDelegate?
    
    // MARK: - Private constants
    
    private let kMoveButtonMarginTop: CGFloat = 24.0
    private let kLabelMarginTop: CGFloat = 8.0
    private let kButtonsMarginLeftRight: CGFloat = 36.0
    
    
    // MARK: - Private attributes
    
//    private var tagButton: UIButton!
//    private var tagLabel: UILabel!
    private var moveButton: UIButton!
    private var moveLabel: UILabel!
    private var markButton: UIButton!
    private var markLabel: UILabel!
    
    
    // MARK: - Required inits
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init() {
        super.init()
        self.backgroundColor = UIColor.ProtonMail.Blue_6789AB
        addSubviews()
        makeConstraints()
    }
    
    
    // MARK: - Subviews
    
    private func addSubviews() {
        let labelFont = UIFont.robotoRegular(size: UIFont.Size.h5)
        let labelColor = UIColor.ProtonMail.Gray_FCFEFF
        
//        self.tagButton = UIButton.buttonWithImage(UIImage(named: "tag")!)
//        self.addSubview(tagButton)
//        
//        self.tagLabel = UILabel.labelWith(labelFont, text: NSLocalizedString("Tag as..."), textColor: labelColor)
//        self.addSubview(tagLabel)
        
        self.moveButton = UIButton.buttonWithImage(UIImage(named: "move")!)
        self.moveButton.addTarget(self, action: "moveAction:", forControlEvents: .TouchUpInside)
        self.addSubview(moveButton)

        self.moveLabel = UILabel.labelWith(labelFont, text: NSLocalizedString("Move to..."), textColor: labelColor)
        self.addSubview(moveLabel)
        
        self.markButton = UIButton.buttonWithImage(UIImage(named: "mark")!)
        self.markButton.addTarget(self, action: "markAction:", forControlEvents: .TouchUpInside)
        self.addSubview(markButton)
        
        self.markLabel = UILabel.labelWith(labelFont, text: NSLocalizedString("Mark as unread"), textColor: labelColor)
        self.addSubview(markLabel)
    }
    
    
    // MARK: - View Constraints
    
    private func makeConstraints() {
        
        moveButton.mas_makeConstraints { (make) -> Void in
            make.centerX.equalTo()(self)
            make.top.equalTo()(self).with().offset()(self.kMoveButtonMarginTop)
            make.width.equalTo()(self.moveButton.frame.size.width)
            make.height.equalTo()(self.moveButton.frame.size.height)
        }
        
        moveLabel.mas_makeConstraints { (make) -> Void in
            make.centerX.equalTo()(self.moveButton)
            make.top.equalTo()(self.moveButton.mas_bottom).with().offset()(self.kLabelMarginTop)
        }
        
//        tagButton.mas_makeConstraints { (make) -> Void in
//            make.centerY.equalTo()(self.moveButton)
//            make.left.equalTo()(self).with().offset()(self.kButtonsMarginLeftRight)
//            make.width.equalTo()(self.tagButton.frame.size.width)
//            make.height.equalTo()(self.tagButton.frame.size.height)
//        }
//        
//        tagLabel.mas_makeConstraints { (make) -> Void in
//            make.centerX.equalTo()(self.tagButton)
//            make.top.equalTo()(self.tagButton.mas_bottom).with().offset()(self.kLabelMarginTop)
//        }
        
        markButton.mas_makeConstraints { (make) -> Void in
            make.centerY.equalTo()(self.moveButton)
            make.right.equalTo()(self).with().offset()(-self.kButtonsMarginLeftRight)
            make.width.equalTo()(self.markButton.frame.size.width)
            make.height.equalTo()(self.markButton.frame.size.height)
        }
        
        markLabel.mas_makeConstraints { (make) -> Void in
            make.centerX.equalTo()(self.markButton)
            make.top.equalTo()(self.markButton.mas_bottom).with().offset()(self.kLabelMarginTop)
        }
    }
    
    // MARK: - Actions
    
    @objc private func markAction(sender: AnyObject) {
        delegate?.moreOptionsViewDidMarkAsUnread(self)
    }
    
    @objc private func moveAction(sender: AnyObject) {
        delegate?.moreOptionsViewDidSelectMoveTo(self)
    }
    
}