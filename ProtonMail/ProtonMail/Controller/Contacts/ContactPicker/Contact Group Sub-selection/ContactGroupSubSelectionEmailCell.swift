//
//  ContactGroupSubSelectionEmailCell.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/10/13.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class ContactGroupSubSelectionEmailCell: UITableViewCell {

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var isEndToEndEncryptedImage: UIImageView!
    @IBOutlet weak var selectionButton: UIButton!
    @IBOutlet weak var emailLabel: UILabel!
    private var delegate: ContactGroupSubSelectionViewModelEmailCellDelegate!
    private var email: String = ""
    
    private var isCurrentlySelected: Bool = false {
        didSet {
            if self.isCurrentlySelected {
                selectionButton.setImage(UIImage.init(named: "mail_check-active"),
                                         for: .normal)
            } else {
                selectionButton.setImage(UIImage.init(named: "mail_check"),
                                         for: .normal)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func config(emailText: String,
                email: String,
                name: String,
                isEndToEndEncrypted: UIImage?,
                isCurrentlySelected: Bool,
                delegate: ContactGroupSubSelectionViewModelEmailCellDelegate) {
        self.email = email
        emailLabel.text = emailText
        self.delegate = delegate
        
        self.isCurrentlySelected = isCurrentlySelected
        
        // lock check
        if let isEndToEndEncrypted = isEndToEndEncrypted {
            self.isEndToEndEncryptedImage.image = isEndToEndEncrypted
        } else {
            let progress = {
                self.isEndToEndEncryptedImage.isHidden = true
                self.activityIndicatorView.startAnimating()
            }
            
            let contactVO = ContactVO.init(name: name, email: email)
            
            let complete = {
                (image: UIImage?, type: Int) -> Void in
                self.activityIndicatorView.stopAnimating()
                self.activityIndicatorView.isHidden = true
                
                contactVO.setType(type: type)
                
                if let img = image {
                    self.isEndToEndEncryptedImage.image = img
                    self.isEndToEndEncryptedImage.isHidden = false
                    self.delegate.setIsEncrypted(email: email, isEncrypted: img)
                } else if let lock = contactVO.lock {
                    self.isEndToEndEncryptedImage.image = lock
                    self.isEndToEndEncryptedImage.isHidden = false
                    self.delegate.setIsEncrypted(email: email, isEncrypted: lock)
                } else {
                    self.isEndToEndEncryptedImage.image = nil
                }
            }
            
            sharedContactDataService.lockerCheck(model: contactVO,
                                                 progress: progress,
                                                 complete: complete)
        }
    }
    
    @IBAction func tappedSelectButton(_ sender: UIButton) {
        self.isCurrentlySelected = !self.isCurrentlySelected
        
        // this is the state that we currently want
        if self.isCurrentlySelected {
            delegate.select(email: self.email)
        } else {
            delegate.deselect(email: self.email)
        }
    }
}
