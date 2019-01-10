//
//  RecipientCell.swift
//  ProtonMail - Created on 9/10/15.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import UIKit


protocol RecipientCellDelegate : AnyObject {
    
    func recipientView(at cell: RecipientCell, arrowClicked arrow: UIButton, model: ContactPickerModelProtocol)
    
    func recipientView(at cell: RecipientCell, lockClicked lock: UIButton, model: ContactPickerModelProtocol)
    
    func recipientView(lockCheck model: ContactPickerModelProtocol, progress: () -> Void, complete: LockCheckComplete?)
}


class RecipientCell: UITableViewCell {

    @IBOutlet weak var senderName: UILabel!
    @IBOutlet weak var email: UILabel!
    
    @IBOutlet weak var arrowButton: UIButton!
    @IBOutlet weak var lockImage: UIImageView!
    
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    private var _model : ContactPickerModelProtocol!
    
    private var _showLocker : Bool = true
    
    weak var delegate : RecipientCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.lockImage.isHidden = true
        
        self.arrowButton.imageView?.contentMode = .scaleAspectFit
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func arrowAction(_ sender: Any) {
        delegate?.recipientView(at: self, arrowClicked: self.arrowButton, model: self.model)
    }

    @IBAction func lockIconAction(_ sender: Any) {
        delegate?.recipientView(at: self, lockClicked: self.lockButton, model: self.model)
    }
    
    func showLock(isShow: Bool) {
        self._showLocker = isShow
    }
    
    var model : ContactPickerModelProtocol {
        get {
            return _model
        }
        set {
            self._model = newValue
            
            let n = (self._model.displayName ?? "")
            let e = (self._model.displayEmail ?? "")
            self.senderName.text = n.isEmpty ? e : n
            self.email.text =  e
            
            if _showLocker {
                self.lockButton.isHidden = false
                self.lockImage.isHidden = false
                self.checkLock()
            } else {
                self.lockButton.isHidden = true
                self.lockImage.isHidden = true
            }
        }
    }
    
    func checkLock() {
        self.delegate?.recipientView(lockCheck: self.model, progress: {
            self.lockImage.isHidden = true
            self.activityView.startAnimating()
        }, complete: { image, type in
            self.lockButton.isHidden = false
            self._model.setType(type: type)
            if let img = image {
                self.lockImage.image = img
                self.lockImage.isHidden = false
            } else if let lock = self.model.lock {
                self.lockImage.image = lock
                self.lockImage.isHidden = false
            } else {
                self.lockImage.image =  nil
                self.lockImage.isHidden = true
                self.lockButton.isHidden = true
            }
            self.activityView.stopAnimating()
        })
    }
}
