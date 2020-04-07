//
//  ContactGroupSubSelectionEmailCell.swift
//  ProtonMail - Created on 2018/10/13.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import UIKit

class ContactGroupSubSelectionEmailCell: UITableViewCell {
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var isEndToEndEncryptedImage: UIImageView!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var selectionIcon: UIImageView!
    private var delegate: ContactGroupSubSelectionViewModelEmailCellDelegate!
    private var data: DraftEmailData? = nil
    private var indexPath: IndexPath? = nil
    
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
        self.delegate = delegate
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
            self.delegate.lockerCheck(model: contactVO,
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
        
        self.indexPath = indexPath
        self.data = DraftEmailData(name: name, email: email)
        emailLabel.text = getDisplayText()
        
        self.isCurrentlySelected = isCurrentlySelected
        
        self.selectionStyle = .none
    }
    
    private func getDisplayText() -> String {
        if self.data?.name == self.data?.email {
            return "\(self.data?.name ?? "")" // prevents duplication in case when contact name is similar to email address
        } else {
            return "\(self.data?.name ?? "")\n<\(self.data?.email ?? "")>" // two lines
        }
    }
    
    func rowTapped() {
        self.isCurrentlySelected = !self.isCurrentlySelected
        
        // this is the state that we currently want
        if let indexPath = self.indexPath {
            if self.isCurrentlySelected {
                delegate.select(indexPath: indexPath)
            } else {
                delegate.deselect(indexPath: indexPath)
            }
        } else {
            // TODO: error handling
            PMLog.D("This shouldn't happen!")
        }
    }
}
