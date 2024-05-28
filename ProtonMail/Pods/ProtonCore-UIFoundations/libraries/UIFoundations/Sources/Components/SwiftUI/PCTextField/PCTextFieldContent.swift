//
//  PCTextField.swift
//  ProtonCore-UIFoundations - Created on 27.03.2024.
//
//  Copyright (c) 2024 Proton Technologies AG
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

#if os(iOS)

import SwiftUI

@MainActor
public struct PCTextFieldContent {
    public var title: String
    public var text: String
    public var placeholder: String
    public var isSecureEntry: Bool
    public var isSecureEntryDisplayed: Bool = false
    public var showClearButton: Bool
    public var footnote: String
    public var keyboardType: UIKeyboardType
    public var autocapitalization: UITextAutocapitalizationType
    public var textContentType: UITextContentType?

    var currentFocus: String?
    private var baseFocusID: String = UUID().uuidString
    var focusID: String {
        if isSecureEntry && !isSecureEntryDisplayed {
            return baseFocusID.appending("_secure")
        } else {
            return baseFocusID.appending("_plain")
        }
    }

    public init(
        title: String,
        text: String = "",
        placeholder: String = "",
        isSecureEntry: Bool = false,
        showClearButton: Bool = true,
        footnote: String = "",
        keyboardType: UIKeyboardType = .default,
        autocapitalization: UITextAutocapitalizationType = .sentences,
        textContentType: UITextContentType? = nil
    ) {
        self.title = title
        self.text = text
        self.placeholder = placeholder
        self.isSecureEntry = isSecureEntry
        self.showClearButton = showClearButton
        self.footnote = footnote
        self.keyboardType = keyboardType
        self.autocapitalization = autocapitalization
        self.textContentType = textContentType
    }

    public var isFocused: Bool {
        currentFocus == focusID
    }

    public mutating func focus() {
        self.currentFocus = focusID
    }
}

#endif
