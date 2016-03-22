//
//  ShowImageView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/22/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation

protocol ShowImageViewProtocol {
    func showImageClicked()
}
class ShowImageView: PMView {
    
    @IBOutlet weak var showImageButton: UIButton!
    var actionDelegate : ShowImageViewProtocol?
    
    override func getNibName() -> String {
        return "ShowImageView"
    }
    
    @IBAction func clickAction(sender: AnyObject) {
        actionDelegate?.showImageClicked()
    }
    
    override func setup() {
        showImageButton.layer.borderColor = UIColor.ProtonMail.Gray_C9CED4.CGColor
        showImageButton.layer.borderWidth = 1.0
        showImageButton.layer.cornerRadius = 2.0
    }
}