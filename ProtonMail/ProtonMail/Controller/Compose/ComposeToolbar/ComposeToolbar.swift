//
//  ComposeToolbar.swift
//  ProtonMail -
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

import PMUIFoundations
import UIKit

protocol ComposeToolbarDelegate: AnyObject {
    func showEncryptOutsideView()
    func showExpireView()
    func showAttachmentView()
}

final class ComposeToolbar: UIView {

    private weak var delegate: ComposeToolbarDelegate?
    private var contentView: UIView!
    @IBOutlet private var lockButton: UIButton!
    @IBOutlet private var hourButton: UIButton!
    @IBOutlet private var attachmentButton: UIButton!
    @IBOutlet private var attachmentNumView: UIView!
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
        // FIXME: use asset
        let icon = isLock ? UIImage(named: "ic_Lock_check") : UIImage(named: "ic_lock_no_ckeck")
        self.lockButton.setImage(icon, for: .normal)
    }

    func setExpirationStatus(isSetting: Bool) {
        // FIXME: use asset
        let icon = isSetting ? UIImage(named: "ic_hourglass_check") : UIImage(named: "ic_hourglass_no_check")
        self.hourButton.setImage(icon, for: .normal)
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
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColorManager.InteractionWeak.cgColor
        self.contentView.backgroundColor = UIColorManager.BackgroundNorm
        self.lockButton.tintColor = UIColorManager.IconNorm
        self.hourButton.tintColor = UIColorManager.IconNorm
        self.attachmentButton.tintColor = UIColorManager.IconNorm
        self.attachmentNumView.backgroundColor = UIColorManager.InteractionNorm
        self.attachmentNumLabel.textColor = .white
    }
}
