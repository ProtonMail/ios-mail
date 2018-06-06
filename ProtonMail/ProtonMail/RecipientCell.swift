//
//  RecipientCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/10/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit


protocol RecipientCellDelegate {
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
    
    var delegate : RecipientCellDelegate?
    
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
                self.checkLock()
            }
        }
    }
    
    func checkLock() {
        self.delegate?.recipientView(lockCheck: self.model, progress: {
            self.lockImage.isHidden = true
            self.activityView.startAnimating()
        }, complete: { image in
            if let img = image {
                self.lockImage.image = img
                self.lockImage.isHidden = false
            } else if let lock = self.model.lock {
                self.lockImage.image = lock
                self.lockImage.isHidden = false
            } else {
                self.lockImage.image = UIImage(named: "zero_access_encryption")
                self.lockImage.isHidden = false
            }
            self.activityView.stopAnimating()
        })
    }
}
