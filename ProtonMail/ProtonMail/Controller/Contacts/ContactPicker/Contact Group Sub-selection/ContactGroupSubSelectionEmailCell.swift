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
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var selectionIcon: UIImageView!
    private var delegate: ContactGroupSubSelectionViewModelEmailCellDelegate!
    private var data: DraftEmailData? = nil
    
    private var isCurrentlySelected: Bool = false {
        didSet {
            if self.isCurrentlySelected {
                selectionIcon.image = UIImage.init(named: "mail_check-active")
            } else {
                selectionIcon.image = UIImage.init(named: "mail_check")
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func checkingInProgress()
    {
        self.isEndToEndEncryptedImage.isHidden = true
        
        self.activityIndicatorView.isHidden = false
        self.activityIndicatorView.startAnimating()
    }
    
    func endCheckingInProgress()
    {
        self.activityIndicatorView.stopAnimating()
        self.activityIndicatorView.isHidden = true
    }
    
    func config(email: String,
                name: String,
                isEndToEndEncrypted: UIImage?,
                isCurrentlySelected: Bool,
                at indexPath: IndexPath,
                checkEncryptedStatus: ContactGroupSubSelectionEmailLockCheckingState,
                delegate: ContactGroupSubSelectionViewModelEmailCellDelegate) {
        // lock check
        switch checkEncryptedStatus {
        case .NotChecked:
            delegate.setRequiredEncryptedCheckStatus(at: indexPath,
                                                     to: .Checking,
                                                     isEncrypted: nil)
            let contactVO = ContactVO.init(name: name, email: email)
            
            let complete = {
                (image: UIImage?, type: Int) -> Void in
                self.endCheckingInProgress()
                
                contactVO.setType(type: type)
                
                if let img = image {
                    self.isEndToEndEncryptedImage.image = img
                    self.isEndToEndEncryptedImage.isHidden = false
                    self.delegate.setRequiredEncryptedCheckStatus(at: indexPath,
                                                                  to: .Checked,
                                                                  isEncrypted: img)
                } else if let lock = contactVO.lock {
                    self.isEndToEndEncryptedImage.image = lock
                    self.isEndToEndEncryptedImage.isHidden = false
                    self.delegate.setRequiredEncryptedCheckStatus(at: indexPath,
                                                                  to: .Checked,
                                                                  isEncrypted: lock)
                } else {
                    self.isEndToEndEncryptedImage.isHidden = true
                    self.isEndToEndEncryptedImage.image = nil
                    self.delegate.setRequiredEncryptedCheckStatus(at: indexPath,
                                                                  to: .Checked,
                                                                  isEncrypted: nil)
                }
            }
            
            sharedContactDataService.lockerCheck(model: contactVO,
                                                 progress: self.checkingInProgress,
                                                 complete: complete)
        case .Checking:
            self.checkingInProgress()
        case .Checked:
            self.endCheckingInProgress() // the cell might still be refreshing for the previous owner since networking might be slow
            
            if let isEndToEndEncrypted = isEndToEndEncrypted {
                self.isEndToEndEncryptedImage.isHidden = false
                self.isEndToEndEncryptedImage.image = isEndToEndEncrypted
            } else {
                self.isEndToEndEncryptedImage.isHidden = true
            }
        }
        
        self.data = DraftEmailData(name: name, email: email)
        emailLabel.text = getDisplayText()
        self.delegate = delegate
        
        self.isCurrentlySelected = isCurrentlySelected
        
        self.selectionStyle = .none
    }
    
    private func getDisplayText() -> String {
        return "\(self.data?.name ?? "") <\(self.data?.email ?? "")>"
    }
    
    func rowTapped() {
        self.isCurrentlySelected = !self.isCurrentlySelected
        
        // this is the state that we currently want
        if let data = self.data {
            if self.isCurrentlySelected {
                delegate.select(data: data)
            } else {
                delegate.deselect(data: data)
            }
        } else {
            // TODO: error handling
            PMLog.D("This shouldn't happen!")
        }
    }
}
