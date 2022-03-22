//
//  PinCodeView.swift
//  ProtonMail - Created on 4/6/16.
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

import AudioToolbox
import Foundation
import ProtonCore_UIFoundations
import UIKit

protocol PinCodeViewDelegate: AnyObject {
    func cancel()
    func next(_ code: String)
}

class PinCodeView: PMView {
    @IBOutlet private var roundButtons: [RoundButton]!

    @IBOutlet private weak var lockImageView: UIImageView!

    @IBOutlet private var pinView: UIView!
    @IBOutlet private var pinDisplayView: UITextField!

    @IBOutlet private var backButton: UIButton!
    @IBOutlet private weak var deletePinButton: RoundButton!

    @IBOutlet private var confirmButton: ProtonButton! {
        didSet {
            confirmButton.setMode(mode: .solid)
        }
    }

    @IBOutlet private var attempsLabel: UILabel!

    weak var delegate: PinCodeViewDelegate?

    var pinCode: String = ""

    override func getNibName() -> String {
        return "PinCodeView"
    }

    override func setup() {
        roundButtons.forEach { btn in
            btn.setTitleColor(ColorProvider.TextNorm, for: .normal)
        }
        backButton.tintColor = ColorProvider.TextNorm
        backButton.contentMode = .center
        backButton.imageView?.contentMode = .scaleAspectFit

        // swiftlint:disable:next object_literal
        let image = UIImage(named: "pin_code_del")?.toTemplateUIImage()
        deletePinButton.setImage(image, for: .normal)
        deletePinButton.tintColor = ColorProvider.IconNorm

        lockImageView.image = IconProvider.lock
        lockImageView.tintColor = ColorProvider.TextNorm

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: ColorProvider.TextHint
        ]
        pinDisplayView.attributedPlaceholder = LocalString
            ._enter_pin_to_unlock_inbox.apply(style: attributes)

        attempsLabel.setCornerRadius(radius: 8.0)

        pinDisplayView.textColor = ColorProvider.InteractionNorm
    }

    func updateBackButton(_ icon: UIImage) {
        backButton.setImage(icon.withRenderingMode(.alwaysTemplate), for: UIControl.State())
        backButton.setTitle("", for: UIControl.State())
    }

    func updateViewText(cancelText: String, resetPin: Bool) {
        confirmButton.setTitle(cancelText, for: .normal)
        if resetPin {
            self.resetPin()
        }
    }

    func showAttemptError(_ error: String, low: Bool) {
        pinDisplayView.textColor = UIColor.red
        attempsLabel.isHidden = false
        attempsLabel.text = error
        if low {
            attempsLabel.backgroundColor = ColorProvider.NotificationError
            attempsLabel.textColor = UIColor.white
        } else {
            attempsLabel.backgroundColor = UIColor.clear
            attempsLabel.textColor = ColorProvider.NotificationError
        }
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }

    func hideAttemptError(_ hide: Bool) {
        pinDisplayView.textColor = ColorProvider.InteractionNorm
        attempsLabel.isHidden = hide
    }

    func resetPin() {
        pinCode = ""
        updateCodeDisplay()
    }

    func showError() {
        attempsLabel.shake(3, offset: 10)
    }

    // MARK: Private methods
    private func add(_ number: Int) {
        pinCode += String(number)
        updateCodeDisplay()
    }

    private func remove() {
        if !pinCode.isEmpty {
            let index = pinCode.index(before: pinCode.endIndex)
            pinCode = String(pinCode[..<index])
            updateCodeDisplay()
        }
    }

    private func updateCodeDisplay() {
        pinDisplayView.text = pinCode
    }

    // MARK: Actions
    @IBAction func buttonActions(_ sender: UIButton) {
        hideAttemptError(true)
        let numberClicked = sender.tag
        add(numberClicked)
    }

    @IBAction func deleteAction(_ sender: UIButton) {
        hideAttemptError(true)
        remove()
    }

    @IBAction func confirmAction(_ sender: UIButton) {
        delegate?.next(pinCode)
    }

    @IBAction func backAction(_ sender: UIButton) {
        delegate?.cancel()
    }
}

class RoundButton: UIButton {
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(ovalIn: rect)
        let sublayer = CAShapeLayer()

        sublayer.fillColor = ColorProvider.BackgroundSecondary.cgColor
        sublayer.path = path.cgPath
        sublayer.name = "pm_border"

        layer.sublayers?.first(where: { $0.name == "pm_border" })?.removeFromSuperlayer()
        layer.insertSublayer(sublayer, at: 0)
    }
}
