//
//  ComposeToolbar.swift
//  ProtonMail -
//
//
//  Copyright (c) 2021 Proton AG
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

import ProtonCore_UIFoundations
import UIKit

protocol ComposeToolbarDelegate: AnyObject {
    func showEncryptOutsideView()
    func showExpireView()
    func showAttachmentView()
}

final class ComposeToolbar: UIView {

    private weak var delegate: ComposeToolbarDelegate?
    private var contentView: UIView!
    @IBOutlet private var stack: UIStackView!
    @IBOutlet private var lockButton: UIButton!
    @IBOutlet private var lockButtonLockIcon: UIImageView!
    @IBOutlet private var hourButton: UIButton!
    @IBOutlet private var hourButtonLockIcon: UIImageView!
    @IBOutlet private var attachmentButton: UIButton!
    @IBOutlet private var attachmentNumView: UIView!
    @IBOutlet private var numContainer: UIView!
    @IBOutlet private var attachmentNumLabel: UILabel!

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(delegate: ComposeToolbarDelegate) {
        super.init(frame: .zero)
        self.nibSetup()
        self.delegate = delegate
    }

    func setLockStatus(isLock: Bool) {
        self.lockButtonLockIcon.isHidden = !isLock
    }

    func setExpirationStatus(isSetting: Bool) {
        self.hourButtonLockIcon.isHidden = !isSetting
    }

    func setAttachment(number: Int) {
        guard number > 0 else {
            self.numContainer.isHidden = true
            return
        }
        self.numContainer.isHidden = false
        let text = number == 0 ? "": "\(number)"
        self.attachmentNumLabel.text = text
        self.attachmentNumView.isHidden = number == 0
        self.attachmentNumLabel.sizeToFit()
        self.numContainer.sizeToFit()
        let height = max(self.numContainer.frame.size.height, 24)
        self.numContainer.roundCorner(height / 2)
    }

    @IBAction private func clickEOButton(_ sender: Any) {
        self.delegate?.showEncryptOutsideView()
    }

    @IBAction private func clickExpireButton(_ sender: Any) {
        self.delegate?.showExpireView()
    }

    @IBAction private func clickAttachmentButton(_ sender: Any) {
        self.delegate?.showAttachmentView()
    }
}

extension ComposeToolbar {
    private func nibSetup() {
        self.contentView = loadViewFromNib()
        self.contentView.frame = bounds
        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.contentView.translatesAutoresizingMaskIntoConstraints = true

        addSubview(self.contentView)
        self.setup()
    }

    private func loadViewFromNib() -> UIView {
        let bundle = Bundle.main
        let name = String(describing: ComposeToolbar.self)
        let nib = UINib(nibName: name, bundle: bundle)
        guard let nibView = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            return UIView(frame: .zero)
        }

        return nibView
    }

    private func setup() {
        addTopBorder()
        self.stack.setCustomSpacing(2, after: self.attachmentNumView)
        self.contentView.backgroundColor = ColorProvider.BackgroundNorm
        self.lockButton.tintColor = ColorProvider.IconNorm
        self.lockButton.setImage(IconProvider.lock, for: .normal)
        self.hourButton.tintColor = ColorProvider.IconNorm
        self.hourButton.setImage(IconProvider.hourglass, for: .normal)
        self.attachmentButton.tintColor = ColorProvider.IconNorm
        self.attachmentButton.setImage(IconProvider.paperClip, for: .normal)
        self.attachmentNumView.backgroundColor = .clear
        self.attachmentNumLabel.textColor = .white
        self.numContainer.backgroundColor = ColorProvider.InteractionNorm
        setupAccessibility()
    }

    private func addTopBorder() {
        let view = UIView()
        view.backgroundColor = ColorProvider.InteractionWeak
        addSubview(view)

        [
            view.topAnchor.constraint(equalTo: self.topAnchor),
            view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            view.heightAnchor.constraint(equalToConstant: 1)
        ].activate()
    }

    private func setupAccessibility() {
        lockButton.accessibilityLabel = LocalString._composer_voiceover_add_pwd
        hourButton.accessibilityLabel = LocalString._composer_voiceover_add_exp
        attachmentButton.accessibilityLabel = LocalString._composer_voiceover_add_attachment
    }
}
