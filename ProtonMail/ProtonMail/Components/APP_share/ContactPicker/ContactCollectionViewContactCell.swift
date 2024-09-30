//
//  ContactCollectionContactCell.swift
//  Proton Mail - Created on 5/3/18.
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

import ProtonCoreUIFoundations
import UIKit

protocol ContactCollectionViewContactCellDelegate: AnyObject {
    func collectionContactCell(lockCheck model: ContactPickerModelProtocol, progress: () -> Void, complete: LockCheckComplete?)
    func checkMails(in contactGroup: ContactGroupVO, progress: () -> Void, complete: LockCheckComplete?)
    func showContactMenu(contact: ContactPickerModelProtocol)
}

class ContactCollectionViewContactCell: UICollectionViewCell {

    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var contactTitleLabel: UILabel!
    @IBOutlet weak var lockImage: UIImageView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!

    @IBOutlet weak var leftConstant: NSLayoutConstraint!
    @IBOutlet weak var widthConstant: NSLayoutConstraint!

    weak var delegate: ContactCollectionViewContactCellDelegate?

    /// contact model
    var _model: ContactPickerModelProtocol!

    /// focused ?
    var _pickerFocused: Bool = false
    private var isError = false

    @objc dynamic var font: UIFont? {
        get { return contactTitleLabel.font }
        set { contactTitleLabel.font = newValue }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.isError = false
    }

    func setup() {
        self.bgView.clipsToBounds = true
        self.bgView.layer.cornerRadius = 8.0
        self.bgView.translatesAutoresizingMaskIntoConstraints = false
        self.bgView.backgroundColor = ColorProvider.InteractionWeak
        contactTitleLabel.set(text: nil,
                              preferredFont: .footnote,
                              lineBreakMode: .byTruncatingMiddle)

        let long = UILongPressGestureRecognizer(target: self, action: #selector(self.showMenu(gesture:)))
        long.minimumPressDuration = 0.5
        self.addGestureRecognizer(long)

        #if DEBUG_BORDERS
        self.contactTitleLabel.layer.borderColor = UIColor(hexColorCode: "0x6789AB").cgColor
        self.contactTitleLabel.layer.borderWidth = 1.0
        #endif
    }

    @objc func showMenu(gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        self.pickerFocused = true
        self.delegate?.showContactMenu(contact: self._model)
    }

    override func tintColorDidChange() {
        let p = self.pickerFocused
        self.pickerFocused = p
    }

    var pickerFocused: Bool {
        get {
            return _pickerFocused
        }
        set {
            _pickerFocused = newValue
            if self._pickerFocused {
                self.contactTitleLabel.textColor = ColorProvider.TextInverted
                self.lockImage.tintColor = ColorProvider.IconInverted
                self.bgView.backgroundColor = ColorProvider.InteractionNorm
                return
            }

            if isError {
                self.bgView.backgroundColor = ColorProvider.NotificationError
                self.contactTitleLabel.textColor = .white
                return
            }
            self.bgView.backgroundColor = ColorProvider.InteractionWeak
            self.contactTitleLabel.textColor = ColorProvider.TextNorm

            if let _ = _model as? ContactGroupVO {
                self.lockImage.isHighlighted = false
                self.lockImage.tintColor = ColorProvider.IconNorm
            }
        }
    }

    var model: ContactPickerModelProtocol {
        get {
            return _model
        }
        set {
            self._model = newValue

            if let _ = self._model as? ContactVO {
                let title = self._model.contactTitle
                let subTitle = self._model.contactSubtitle ?? ""
                let text = title == subTitle ? title : "\(title) <\(subTitle)>"
                DispatchQueue.main.async {
                    self.contactTitleLabel.text = text
                    self.checkLock(caller: self.model)
                }
            } else if let _ = self._model as? ContactGroupVO {
                prepareTitleForContactGroup()
            }
        }
    }

    func prepareTitleForContactGroup(shouldCheckMails: Bool = true) {
        guard let contactGroup = self._model as? ContactGroupVO else { return }

        let (selectedCount, totalCount, color) = contactGroup.getGroupInformation()
        let text = "\(contactGroup.contactTitle) (\(selectedCount)/\(totalCount))"
        contactTitleLabel.text = text
        self.contactTitleLabel.textAlignment = .left
        self.lockImage.image = UIImage.init(named: "ic-contact-groups-filled")
        self.lockImage.setupImage(scale: 1,
                                  tintColor: UIColor.white,
                                  backgroundColor: UIColor.init(hexString: color, alpha: 1))
        if shouldCheckMails {
            self.checkMails(in: contactGroup)
        }
    }

    private func checkLock(caller: ContactPickerModelProtocol) {
        self.delegate?.collectionContactCell(lockCheck: self.model, progress: {
            self.leftConstant.constant = 8
            self.widthConstant.constant = 16
            self.lockImage.isHidden = true
            self.activityView.startAnimating()
        }, complete: { image, type in
            guard caller.equals(self.model) else {
                return
            }
            self.activityView.stopAnimating()
            guard self.isEmailVerified(type: type) else { return }
            self.lockImage.backgroundColor = nil
            self.lockImage.tintColor = nil
            if let img = image {
                self.lockImage.image = img
                self.lockImage.isHidden = false
                self.leftConstant.constant = 8
                self.widthConstant.constant = 16

                self.contactTitleLabel.textAlignment = .left
            } else {
                self.lockImage.image = nil
                self.lockImage.isHidden = true
                self.leftConstant.constant = 0
                self.widthConstant.constant = 0

                self.contactTitleLabel.textAlignment = .center
            }
        })
    }

    private func checkMails(in group: ContactGroupVO) {
        self.delegate?.checkMails(in: group, progress: { [weak self] in
            self?.leftConstant.constant = 8
            self?.widthConstant.constant = 16
            self?.lockImage.isHidden = true
            self?.activityView.isHidden = false
            self?.activityView.startAnimating()
        }, complete: { [weak self](_, type) in
            let (_, _, _) = group.getGroupInformation()

            self?.activityView.isHidden = true
            self?.activityView.stopAnimating()
            guard self?.isEmailVerified(type: type) ?? true else { return }
            self?.lockImage.image = IconProvider.usersFilled
            self?.lockImage.tintColor = ColorProvider.IconNorm
            self?.lockImage.backgroundColor = .clear
            self?.lockImage.isHidden = false
        })
    }

    func widthForCell() -> CGFloat {
        let text = self.contactTitleLabel.text ?? self._model.contactTitle
        let font = self.font ?? Fonts.h5.light
        let size = text.size(withAttributes: [NSAttributedString.Key.font: font])
        let offset = self.widthConstant.constant == 0 ? 8: 28
        let rightPadding: CGFloat = 8
        return size.width.rounded(.up) + CGFloat(offset) + rightPadding
    }

    func widthForCellWithContact(model: ContactPickerModelProtocol) -> CGFloat {
        // TODO:: i feel it isn't good
        if let contactGroup = model as? ContactGroupVO {
            let (selectedCount, totalCount, _) = contactGroup.getGroupInformation()
            let title = "\(contactGroup.contactTitle) (\(selectedCount)/\(totalCount))"
            let size = title.size(withAttributes: [NSAttributedString.Key.font: Fonts.h5.light])
            return size.width.rounded(.up) + 20 + 14 //
        }

        let size = model.contactTitle.size(withAttributes: [NSAttributedString.Key.font: Fonts.h5.light])
        return size.width.rounded(.up) + 20 + 14 // 34 //20 + self.contactTitleLabel.frame.height + 6
    }

    private func isEmailVerified(type: Int) -> Bool {
        self.isError = false
        // Code=33101 "Email address failed validation"
        // Code=33102 "Recipient could not be found"
        let isBadMail = [PGPTypeErrorCode.recipientNotFound.rawValue,
                         PGPTypeErrorCode.emailAddressFailedValidation.rawValue].contains(type)
        guard isBadMail else { return true }
        self.isError = true
        self.bgView.backgroundColor = ColorProvider.NotificationError
        self.contactTitleLabel.textColor = .white
        self.lockImage.image = IconProvider.exclamationCircle
        self.lockImage.contentMode = .scaleAspectFit
        self.lockImage.tintColor = .white
        self.lockImage.backgroundColor = .clear
        self.lockImage.isHidden = false
        return false
    }
}
