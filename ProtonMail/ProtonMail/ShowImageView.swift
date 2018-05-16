//
//  ShowImageView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/22/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation

protocol ShowImageViewProtocol {
    func showImage()
}

class ShowImageView: PMView {
    @IBOutlet weak var showImageButton: UIButton!
    var delegate : ShowImageViewProtocol?
    
    override func getNibName() -> String {
        return "ShowImageView"
    }
    
    @IBAction func clickAction(_ sender: AnyObject) {
        self.delegate?.showImage()
    }
    
    override func setup() {
        showImageButton.layer.borderColor = UIColor.ProtonMail.Gray_C9CED4.cgColor
        showImageButton.layer.borderWidth = 1.0
        showImageButton.layer.cornerRadius = 2.0
        showImageButton.setTitle(LocalString._load_remote_content, for: .normal)
    }
}
