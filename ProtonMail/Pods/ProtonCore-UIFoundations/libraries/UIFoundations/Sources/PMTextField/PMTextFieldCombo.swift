//
//  PMTextFieldCombo.swift
//  ProtonMail - Created on 10.10.20.
//
//  Copyright (c) 2020 Proton Technologies AG
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
//

import UIKit
import ProtonCore_Foundations

public protocol PMTextFieldComboDelegate: AnyObject {
    /**
     Tells the delegate that editing stopped for the specified text field.
     */
    func didEndEditing(textField: PMTextFieldCombo)

    /**
     Tells the delegate the value changed for the specific text field
     */
    func didChangeValue(_ textField: PMTextFieldCombo, value: String)

    /**
     Asks the delegate if the text field should process the pressing of the return button.
     */
    func textFieldShouldReturn(_ textField: PMTextFieldCombo) -> Bool

    /**
     Tells the delegate that user requested data selection.
     */
    func userDidRequestDataSelection(button: UIButton)
}

/**
 An object that displays an editable text area with a title and optional assistive text and error
 */
public class PMTextFieldCombo: UIView {

    // MARK: - Outlets

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private var mainView: UIView!
    @IBOutlet private weak var textField: PMInternalTextField!
    @IBOutlet private weak var assistiveTextLabel: UILabel!
    @IBOutlet weak var pickerButton: UIButton!
    @IBOutlet private weak var pickerLabel: UILabel!
    // MARK: - Properties

    /**
     The receiver’s delegate.
     */
    public weak var delegate: PMTextFieldComboDelegate?

    /**
     The text shown above the text field.

     This property shoould always be set, otherwise there will be an empty space above the text field.
     */
    @IBInspectable public var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }

    /**
     Wether text input should be constrained to numbers

     Also affects the keyboard type
     */
    @IBInspectable public var allowOnlyNumbers: Bool = false {
        didSet {
            textField.keyboardType = allowOnlyNumbers ? .numberPad : keyboardType
        }
    }

    /**
     The text displayed by the text field.
     */
    @IBInspectable public var value: String {
        get {
            return textField.text ?? ""
        }
        set {
            textField.text = newValue
            delegate?.didChangeValue(self, value: newValue)
        }
    }

    /**
     The string that is displayed when there is no other text in the text field.
     */
    @IBInspectable public var placeholder: String? {
        didSet {
            guard let placeholder = placeholder, !placeholder.isEmpty else {
                textField.attributedPlaceholder = nil
                return
            }

            textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [
                NSAttributedString.Key.foregroundColor: SolidColors._N5,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)
            ])
        }
    }

    /**
     The optional text shown under the text field.
     */
    @IBInspectable public var assistiveText: String? {
        didSet {
            assistiveTextLabel.text = assistiveText
        }
    }

    /**
    The optional text shown in button title.
    */
   @IBInspectable public var buttonTitleText: String? {
       didSet {
           pickerLabel.text = buttonTitleText
       }
   }

    /**
     The keyboard style associated with the text object.

     Text objects can be targeted for specific types of input, such as plain text, email, numeric entry, and so on. The keyboard style identifies what keys are available on the keyboard and which ones appear by default. The default value for this property is `UIKeyboardType.default`.
     */
    public var keyboardType: UIKeyboardType {
        get {
            textField.keyboardType
        }
        set {
            textField.keyboardType = newValue
        }
    }

    /**
     The semantic meaning expected by a text input area.

     Use this property to give the keyboard and the system information about the expected semantic meaning for the content that users enter. For example, you might specify ``emailAddress` for a text field that users fill in to receive an email confirmation. When you provide this information about the content you expect users to enter in a text input area, the system can in some cases automatically select an appropriate keyboard and improve keyboard corrections and proactive integration with other text input opportunities.

     Because the expected semantic meaning for each text input area should be identified as specifically as possible, you can’t combine multiple values for one `textContentType` property. For possible values you can use, see `Text Content Types`; by default, the value of this property is `nil`.
     */
    public var textContentType: UITextContentType? {
        get {
            return textField.textContentType
        }
        set {
            textField.textContentType = newValue
        }
    }

    /**
     The auto-capitalization style for the text object.

     This property determines at what times the Shift key is automatically pressed, thereby making the typed character a capital letter. The default value for this property is `UITextAutocapitalizationType.sentences`.

     Some keyboard types do not support auto-capitalization. Specifically, this option is ignored if the value in the keyboardType property is set to `UIKeyboardType.numberPad`, `UIKeyboardType.phonePad`, or `UIKeyboardType.namePhonePad`.
     */
    public var autocapitalizationType: UITextAutocapitalizationType {
        get {
            return textField.autocapitalizationType
        }
        set {
            textField.autocapitalizationType = newValue
        }
    }

    /**
     The autocorrection style for the text object.

     This property determines whether autocorrection is enabled or disabled during typing. With autocorrection enabled, the text object tracks unknown words and suggests a more suitable replacement candidate to the user, replacing the typed text automatically unless the user explicitly overrides the action.

     The default value for this property is UITextAutocorrectionType.default, which for most input methods results in autocorrection being enabled.
     */
    public var autocorrectionType: UITextAutocorrectionType {
        get {
            return textField.autocorrectionType
        }
        set {
            textField.autocorrectionType = newValue
        }
    }

    /**
     The spell-checking style for the text object.

     This property determines whether spell-checking is enabled or disabled during typing. With spell-checking enabled, the text object generates red underlines for all misspelled words. If the user taps on a misspelled word, the text object presents the user with a list of possible corrections.

     The default value for this property is UITextSpellCheckingType.default, which enables spell-checking when autocorrection is also enabled. The value in this property overrides the spell-checking setting set by the user in Settings > General > Keyboard.
     */
    public var spellCheckingType: UITextSpellCheckingType {
        get {
            return textField.spellCheckingType
        }
        set {
            textField.spellCheckingType = newValue
        }
    }

    // MARK: - Outlets

    @IBAction func onPickerButtonTouchUp(_ sender: UIButton) {
        pickerButton.layer.borderWidth = 0
        delegate?.userDidRequestDataSelection(button: sender)
    }

    @IBAction func onPickerButtonTouchDown(_ sender: UIButton) {
        textField.resignFirstResponder()
        pickerButton.layer.borderWidth = 1
    }

    // MARK: - Setup

    override init(frame: CGRect) {
        super.init(frame: frame)
        load()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        load()
    }

    private func load() {
        PMUIFoundations.bundle.loadNibNamed("PMTextFieldCombo", owner: self, options: nil)
        addSubview(mainView)
        mainView.frame = bounds
        mainView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mainView.backgroundColor = UIColorManager.BackgroundNorm

        textField.delegate = self
        textField.textColor = UIColorManager.TextNorm
        textField.backgroundColor = UIColorManager.InteractionWeakDisabled
        textField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)

        pickerButton.layer.cornerRadius = textField.layer.cornerRadius
        pickerButton.contentHorizontalAlignment = .right
        pickerButton.layer.borderColor = UIColorManager.BrandNorm.cgColor
        pickerButton.tintColor = UIColorManager.IconNorm
        pickerButton.backgroundColor = UIColorManager.InteractionWeakDisabled

        titleLabel.textColor = UIColorManager.TextNorm
        assistiveTextLabel.textColor = UIColorManager.TextWeak
        pickerLabel.textColor = UIColorManager.TextNorm
    }

    @objc private func textFieldDidChange(textField: UITextField) {
        delegate?.didChangeValue(self, value: value)
    }

    public func setUpChallenge(_ challenge: ChallengeProtocol, type: ChallengeTextFieldType) throws {
        try challenge.observeTextField(textField, type: type)
    }

    // MARK: - Responder overrides

    override public var isFirstResponder: Bool {
        return textField.isFirstResponder
    }

    override public func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }

    override public func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
}

// MARK: - Text field delegate

extension PMTextFieldCombo: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return delegate?.textFieldShouldReturn(self) ?? true
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        self.textField.setBorder()
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        self.textField.setBorder()
        delegate?.didEndEditing(textField: self)
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard allowOnlyNumbers else {
            return true
        }

        return Int(string) != nil
    }
}
