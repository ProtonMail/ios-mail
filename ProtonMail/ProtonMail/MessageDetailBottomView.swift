//
//  MessageDetailBottomView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/11/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

protocol MessageDetailBottomViewProtocol {
    func replyClicked()
    func replyAllClicked()
    func forwardClicked()
}

class MessageDetailBottomView: UIView {
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
    // Drawing code
    }
    */
    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var replyAllButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    
    override func awakeFromNib() {
        replyButton.setTitle(NSLocalizedString("Reply", comment: "top left back button"), for: .normal)
        replyAllButton.setTitle(NSLocalizedString("Reply All", comment: "top left back button"), for: .normal)
        forwardButton.setTitle(NSLocalizedString("Forward", comment: "top left back button"), for: .normal)
    }
    
//    override init(frame: CGRect) { // for using CustomView in code
//        super.init(frame: frame)
//        
//        replyButton.setTitle(NSLocalizedString("Reply", comment: "top left back button"), for: .normal)
//        replyAllButton.setTitle(NSLocalizedString("Reply All", comment: "top left back button"), for: .normal)
//        forwardButton.setTitle(NSLocalizedString("Forward", comment: "top left back button"), for: .normal)
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)!
//        
//    }
    
    var delegate: MessageDetailBottomViewProtocol?

    
    @IBAction func replyClicked(_ sender: AnyObject) {
        self.delegate?.replyClicked()
    }
    
    @IBAction func replyAllClicked(_ sender: AnyObject) {
        self.delegate?.replyAllClicked()
    }
    
    @IBAction func forwardClicked(_ sender: AnyObject) {
        self.delegate?.forwardClicked()
    }
}
