//
// Copyright (c) 2025 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import UIKit

public enum DynamicFontSize {
    public static let largestSupportedSizeCategory = UIContentSizeCategory.extraExtraExtraLarge

    public static func capSupportedSizeCategories() {
        bypassAccessibilityRestrictions()
        UIViewController.swizzleDynamicFontSizeLimitation()
    }

    private static func bypassAccessibilityRestrictions() {
        let allConformingTypes: [UIContentSizeCategoryAdjusting] = [
            UILabel.appearance(),
            UISearchTextField.appearance(),
            UITextField.appearance(),
            UITextView.appearance(),
        ]

        for contentSizeCategoryAdjusting in allConformingTypes {
            contentSizeCategoryAdjusting.adjustsFontForContentSizeCategory = true
        }
    }
}

private extension UIViewController {
    static func swizzleDynamicFontSizeLimitation() {
        guard
            let original = class_getInstanceMethod(Self.self, #selector(viewDidLoad)),
            let swizzled = class_getInstanceMethod(Self.self, #selector(viewDidLoadWithSizeCategory))
        else {
            return
        }
        method_exchangeImplementations(original, swizzled)
    }

    @objc private func viewDidLoadWithSizeCategory() {
        view.maximumContentSizeCategory = DynamicFontSize.largestSupportedSizeCategory
        viewDidLoadWithSizeCategory()
    }
}
