//
//  RecipientCell.swift
//  Proton Mail - Created on 9/10/15.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

protocol RecipientCellDelegate: AnyObject {
    func recipientViewNeedsLockCheck(completion: @escaping LockCheckComplete)
}

final class RecipientCell: UITableViewCell {

    @IBOutlet private var senderName: UILabel!
    @IBOutlet private var email: UILabel!

    @IBOutlet private var arrowButton: UIButton!
    @IBOutlet private var lockImage: UIImageView!

    @IBOutlet private var lockButton: UIButton!
    @IBOutlet private var activityView: UIActivityIndicatorView!

    private var _model: ContactPickerModelProtocol!

    private var _showLocker: Bool = true

    weak var delegate: RecipientCellDelegate?

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
    }

    @IBAction func lockIconAction(_ sender: Any) {
    }

    func showLock(isShow: Bool) {
        self._showLocker = isShow
    }

    var model: ContactPickerModelProtocol {
        get {
            return _model
        }
        set {
            self._model = newValue

            let name = (self._model.displayName ?? "")
            let email = (self._model.displayEmail ?? "")
            self.senderName.text = name.isEmpty ? email : name
            self.email.text = email

            if _showLocker {
                self.lockButton.isHidden = false
                self.lockImage.isHidden = false
                self.checkLock()
            } else {
                self.lockButton.isHidden = true
                self.lockImage.isHidden = true
            }

            // accessibility
            self.accessibilityLabel = name.isEmpty ? email : "\(name), \(email)"
            self.accessibilityElements = []
            self.isAccessibilityElement = true
        }
    }

    override func accessibilityActivate() -> Bool {
        self.arrowAction(self)
        return true
    }

    func checkLock() {
        self.delegate?.recipientViewNeedsLockCheck { image, _ in
            self.lockButton.isHidden = false
            if let img = image {
                self.lockImage.image = img
                self.lockImage.isHidden = false
            } else {
                self.lockImage.image = nil
                self.lockImage.isHidden = true
                self.lockButton.isHidden = true
            }
            self.activityView.stopAnimating()
        }
    }
}
