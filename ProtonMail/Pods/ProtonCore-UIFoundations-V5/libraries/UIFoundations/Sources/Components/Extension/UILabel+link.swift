//
//  UILabel+helper.swift
//  ProtonCore-UIFoundations - Created on 26.07.20.
//
//  Copyright (c) 2022 Proton Technologies AG
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

public extension UILabel {
    func textWithLink(text: String, link: String, handler: (() -> Void)?) {
        let termsText = NSMutableAttributedString(string: text)
        let foregroundColor: UIColor = ColorProvider.InteractionNorm
        actionHandler(handler: handler)
        
        if termsText.setAttributes(textToFind: link, attributes: [
            NSAttributedString.Key.foregroundColor: foregroundColor,
            NSAttributedString.Key.underlineColor: UIColor.clear
        ]) {
            attributedText = termsText
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(triggerActionHandler))
            addGestureRecognizer(recognizer)
            isUserInteractionEnabled = true
        }
    }
    
    private func actionHandler(handler:(() -> Void)? = nil) {
        struct ActionHandler {
            static var handler: (() -> Void)?
        }
        if handler != nil {
            ActionHandler.handler = handler
        } else {
            ActionHandler.handler?()
        }
    }

    @objc private func triggerActionHandler() {
        self.actionHandler()
    }
}
