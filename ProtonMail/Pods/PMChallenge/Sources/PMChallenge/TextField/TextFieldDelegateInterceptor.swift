//
//  TextFieldDelegateInterceptor.swift
//  ProtonMail - Created on 6/19/20.
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

// swiftlint:disable force_try

import UIKit

protocol TextFieldInterceptorDelegate: class {
    func beginEditing(type: PMChallenge.TextFieldType)
    func endEditing(type: PMChallenge.TextFieldType)
    func charactersTyped(chars: String, type: PMChallenge.TextFieldType) throws
    func charactersDeleted(chars: String, type: PMChallenge.TextFieldType)
    func tap(textField: UITextField, type: PMChallenge.TextFieldType)
}

final class TextFieldDelegateInterceptor: NSObject {
    private weak var delegate: TextFieldInterceptorDelegate?
    private weak var originalDelegate: UITextFieldDelegate?
    private(set) weak var textField: UITextField?
    private var touchDown: UILongPressGestureRecognizer?
    let type: PMChallenge.TextFieldType
    private var observe: NSKeyValueObservation?

    init(textField: UITextField, type: PMChallenge.TextFieldType, delegate: TextFieldInterceptorDelegate, ignoreDelegate: Bool=false) throws {
        self.delegate = delegate
        guard textField.delegate != nil || ignoreDelegate else {
            throw PMChallenge.TextFieldInterceptError.delegateMissing
        }
        self.originalDelegate = textField.delegate

        self.type = type
        self.textField = textField

        super.init()
        textField.delegate = self
        self.touchDown = UILongPressGestureRecognizer(target: self, action: #selector(tapTextField))
        self.touchDown!.minimumPressDuration = 0
        self.touchDown!.delegate = self
        self.textField?.addGestureRecognizer(self.touchDown!)
    }

    func destroy() {
        self.textField?.delegate = self.originalDelegate
        self.textField = nil
        self.delegate = nil
        textField?.removeGestureRecognizer(self.touchDown!)
    }
}

extension TextFieldDelegateInterceptor: UIGestureRecognizerDelegate {
    @objc private func tapTextField() {
        guard let del = self.delegate, let field = self.textField else {return}
        del.tap(textField: field, type: self.type)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        self.tapTextField()
        return false
    }
}

extension TextFieldDelegateInterceptor: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {

        return self.originalDelegate?.textFieldShouldBeginEditing?(textField) ?? true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.delegate?.beginEditing(type: self.type)
        self.originalDelegate?.textFieldDidBeginEditing?(textField)
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {

        return self.originalDelegate?.textFieldShouldEndEditing?(textField) ?? true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.delegate?.endEditing(type: self.type)
        self.originalDelegate?.textFieldDidEndEditing?(textField)
    }

    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        self.delegate?.endEditing(type: self.type)
        self.originalDelegate?.textFieldDidEndEditing?(textField, reason: reason)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        if range.length == 0 {
            // Add new characters
            try! self.delegate?.charactersTyped(chars: string, type: self.type)
        } else {
            // Remove characters
            if let text = textField.text {
                let start = text.index(text.startIndex, offsetBy: range.location)
                let end = text.index(start, offsetBy: range.length)
                let subStr = String(text[start..<end])
                self.delegate?.charactersDeleted(chars: subStr, type: self.type)
            }
        }
        return self.originalDelegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string) ?? true
    }

    @available(iOS 13.0, *)
    func textFieldDidChangeSelection(_ textField: UITextField) {

        self.originalDelegate?.textFieldDidChangeSelection?(textField)
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {

        return self.originalDelegate?.textFieldShouldClear?(textField) ?? true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        return self.originalDelegate?.textFieldShouldReturn?(textField) ?? true
    }
}
