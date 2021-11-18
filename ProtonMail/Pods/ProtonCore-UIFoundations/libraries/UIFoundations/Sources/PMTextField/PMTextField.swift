//
//  PMTextField.swift
//  ProtonCore-UIFoundations - Created on 03/11/2020.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import ProtonCore_Foundations

public protocol PMTextFieldDelegate: AnyObject {
    /**
     Tells the delegate that editing stopped for the specified text field.
     */
    func didEndEditing(textField: PMTextField)

    /**
     Tells the delegate the value changed for the specific text field
     */
    func didChangeValue(_ textField: PMTextField, value: String)

    /**
     Asks the delegate if the text field should process the pressing of the return button.
     */
    func textFieldShouldReturn(_ textField: PMTextField) -> Bool
    /**
     Tells the delegate that editing started for the specified text field.
     */
    func didBeginEditing(textField: PMTextField)
}

/**
 An object that displays an editable text area with a title and optional assistive text and error
 */
public class PMTextField: UIView {

    // MARK: - Outlets

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private var mainView: UIView!
    @IBOutlet private weak var textField: PMInternalTextField!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var assistiveTextLabel: UILabel!
    @IBOutlet private weak var suffixLabel: UILabel!

    // MARK: - Properties

    /**
     The receiver’s delegate.
     */
    public weak var delegate: PMTextFieldDelegate?

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
     Identifies whether the text object should disable text copying and in some cases hide the text being entered.
     */
    @IBInspectable public var isPassword: Bool = false {
        didSet {
            textField.isSecureTextEntry = isPassword
            textField.textContentType = isPassword ? .password : .none
            textField.clearButtonMode = .never
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
     Sets keyboard return key type
     */
    public var returnKeyType: UIReturnKeyType {
        get { textField.returnKeyType }
        set { textField.returnKeyType = newValue }
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
     Wether the text field is in an error state

     Enabling error states enables red border around the text field.

     This setting does not affect the `errorMessage` property, it should be set separately to display an error message.
     */
    @IBInspectable public var isError: Bool = false {
        didSet {
            textField.isError = isError
            titleLabel.textColor = isError ? ColorProvider.NotificationError : ColorProvider.TextNorm
            errorLabel.isHidden = !isError
        }
    }

    /**
     Error message displayed under the text field

     Setting this property to `nil` hides the error message but does not disable the error state of the textfield, because the text field can be in an error state without showing the error message. Use the `isError` property to completely disable the error state when needed
     */
    @IBInspectable public var errorMessage: String? {
        didSet {
            guard let message = errorMessage, !message.isEmpty else {
                assistiveTextLabel.isHidden = false
                errorLabel.text = " "
                return
            }

            isError = true
            errorLabel.text = message
            assistiveTextLabel.isHidden = true
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
            
            let foregroundColor: UIColor = ColorProvider.TextHint
            textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [
                NSAttributedString.Key.foregroundColor: foregroundColor,
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
     The optional text shown on the right side of the text field.
     */
    @IBInspectable public var suffix: String? {
        didSet {
            guard let suffix = suffix, !suffix.isEmpty else {
                textField.clearButtonMode = isPassword ? .never : .whileEditing
                textField.suffixMarging = 0
                suffixLabel.isHidden = true
                return
            }

            suffixLabel.isHidden = false
            suffixLabel.text = suffix
            textField.clearButtonMode = .never

            setNeedsLayout()
            layoutIfNeeded()

            textField.suffixMarging = suffixLabel.frame.size.width
        }
    }

    /**
     Clears error when textField gets focus
     */
    @IBInspectable public var clearErrorWhenBeginEditing: Bool = true

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
        PMUIFoundations.bundle.loadNibNamed("PMTextField", owner: self, options: nil)
        addSubview(mainView)
        mainView.frame = bounds
        mainView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mainView.backgroundColor = ColorProvider.BackgroundNorm

        textField.delegate = self
        textField.textColor = ColorProvider.TextNorm
        textField.backgroundColor = ColorProvider.InteractionWeakDisabled
        textField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)

        titleLabel.textColor = ColorProvider.TextNorm
        errorLabel.textColor = ColorProvider.NotificationError
        assistiveTextLabel.textColor = ColorProvider.TextWeak
        suffixLabel.textColor = ColorProvider.TextWeak
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

extension PMTextField: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return delegate?.textFieldShouldReturn(self) ?? true
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        if clearErrorWhenBeginEditing {
            isError = false
        }
        self.textField.setBorder()
        delegate?.didBeginEditing(textField: self)
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        self.textField.setBorder()
        delegate?.didEndEditing(textField: self)
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard allowOnlyNumbers else {
            return true
        }

        return string.isEmpty || Int(string) != nil
    }
}
