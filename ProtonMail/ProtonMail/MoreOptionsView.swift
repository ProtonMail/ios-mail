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
    func moreOptionsViewDidMarkAsUnread(_ moreOptionsView: MoreOptionsView) -> Void
    func moreOptionsViewDidSelectMoveTo(_ moreOptionsView: MoreOptionsView) -> Void
    func moreOptionsViewDidSelectTagAs(_ moreOptionsView: MoreOptionsView) -> Void
}

class MoreOptionsView: UIView {
    
    var delegate: MoreOptionsViewDelegate?
    
    // MARK: - Private constants
    
    fileprivate let kMoveButtonMarginTop: CGFloat = 24.0
    fileprivate let kLabelMarginTop: CGFloat = 8.0
    fileprivate let kButtonsMarginLeftRight: CGFloat = 36.0
    
    
    // MARK: - Private attributes
    
    fileprivate var tagButton: UIButton!
    fileprivate var tagLabel: UILabel!
    fileprivate var moveButton: UIButton!
    fileprivate var moveLabel: UILabel!
    fileprivate var markButton: UIButton!
    fileprivate var markLabel: UILabel!
    
    
    // MARK: - Required inits
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //TODO:: need monitor
        self.backgroundColor = UIColor.ProtonMail.Blue_6789AB
        addSubviews()
        makeConstraints()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Subviews
    
    fileprivate func addSubviews() {
        let labelFont = UIFont.robotoRegular(size: UIFont.Size.h5)
        let labelColor = UIColor.ProtonMail.Gray_FCFEFF
        
        self.tagButton = UIButton.buttonWithImage(UIImage(named: "tag")!)
        self.tagButton.addTarget(self, action: #selector(MoreOptionsView.tagAction(_:)), for: .touchUpInside)
        self.addSubview(tagButton)
        
        self.tagLabel = UILabel.labelWith(labelFont, text: NSLocalizedString("Label as...", comment: "Title"), textColor: labelColor)
        self.addSubview(tagLabel)
        
        self.moveButton = UIButton.buttonWithImage(UIImage(named: "move")!)
        self.moveButton.addTarget(self, action: #selector(MoreOptionsView.moveAction(_:)), for: .touchUpInside)
        self.addSubview(moveButton)

        self.moveLabel = UILabel.labelWith(labelFont, text: NSLocalizedString("Move to...", comment: "Title"), textColor: labelColor)
        self.addSubview(moveLabel)
        
        self.markButton = UIButton.buttonWithImage(UIImage(named: "mark")!)
        self.markButton.addTarget(self, action: #selector(MoreOptionsView.markAction(_:)), for: .touchUpInside)
        self.addSubview(markButton)
        
        self.markLabel = UILabel.labelWith(labelFont, text: NSLocalizedString("Mark as unread", comment: "Action"), textColor: labelColor)
        self.addSubview(markLabel)
    }
    
    
    // MARK: - View Constraints
    
    fileprivate func makeConstraints() {
        
        moveButton.mas_makeConstraints { (make) -> Void in
            let _ = make?.centerX.equalTo()(self)
            let _ = make?.top.equalTo()(self)?.with().offset()(self.kMoveButtonMarginTop)
            let _ = make?.width.equalTo()(self.moveButton.frame.size.width)
            let _ = make?.height.equalTo()(self.moveButton.frame.size.height)
        }
        
        moveLabel.mas_makeConstraints { (make) -> Void in
            let _ = make?.centerX.equalTo()(self.moveButton)
            let _ = make?.top.equalTo()(self.moveButton.mas_bottom)?.with().offset()(self.kLabelMarginTop)
        }
        
        tagButton.mas_makeConstraints { (make) -> Void in
            let _ = make?.centerY.equalTo()(self.moveButton)
            let _ = make?.left.equalTo()(self)?.with().offset()(self.kButtonsMarginLeftRight)
            let _ = make?.width.equalTo()(self.tagButton.frame.size.width)
            let _ = make?.height.equalTo()(self.tagButton.frame.size.height)
        }
        
        tagLabel.mas_makeConstraints { (make) -> Void in
            let _ = make?.centerX.equalTo()(self.tagButton)
            let _ = make?.top.equalTo()(self.tagButton.mas_bottom)?.with().offset()(self.kLabelMarginTop)
        }
        
        markButton.mas_makeConstraints { (make) -> Void in
            let _ = make?.centerY.equalTo()(self.moveButton)
            let _ = make?.right.equalTo()(self)?.with().offset()(-self.kButtonsMarginLeftRight)
            let _ = make?.width.equalTo()(self.markButton.frame.size.width)
            let _ = make?.height.equalTo()(self.markButton.frame.size.height)
        }
        
        markLabel.mas_makeConstraints { (make) -> Void in
            let _ = make?.centerX.equalTo()(self.markButton)
            let _ = make?.top.equalTo()(self.markButton.mas_bottom)?.with().offset()(self.kLabelMarginTop)
        }
    }
    
    // MARK: - Actions
    
    @objc fileprivate func markAction(_ sender: AnyObject) {
        delegate?.moreOptionsViewDidMarkAsUnread(self)
    }
    
    @objc fileprivate func moveAction(_ sender: AnyObject) {
        delegate?.moreOptionsViewDidSelectMoveTo(self)
    }
    
    @objc fileprivate func tagAction(_ sender: AnyObject) {
        delegate?.moreOptionsViewDidSelectTagAs(self)
    }
    
}
