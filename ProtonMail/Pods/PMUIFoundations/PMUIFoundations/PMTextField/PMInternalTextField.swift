//
//  TextInsetTextField.swift
//  PMLogin
//
//  Created by Igor Kulman on 03/11/2020.
//

import Foundation
import UIKit

final class PMInternalTextField: UITextField {

    // MARK: - Properties

    var isError: Bool = false {
        didSet {
            setBorder()
        }
    }

    override var isSecureTextEntry: Bool {
        didSet {
            guard isSecureTextEntry else {
                rightView = nil
                rightViewMode = .never
                return
            }

            showMaskButton()
        }
    }

    var suffixMarging: CGFloat = 0

    private let topBottomInset: CGFloat = 13
    private let leftRightInset: CGFloat = 12

    private lazy var unmaskButton: UIButton = {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 48, height: 48)
        button.addTarget(self, action: #selector(self.togglePasswordVisibility), for: .touchUpInside)
        return button
    }()

    // MARK: - Setup

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        layer.masksToBounds = true
        layer.cornerRadius = 3
        layer.borderWidth = 1
        layer.borderColor = UIColorManager.InteractionWeakDisabled.cgColor
    }

    override var clearButtonMode: UITextField.ViewMode {
        didSet {
            setNeedsDisplay()
        }
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        var rightPadding: CGFloat = clearButtonMode == .whileEditing ? 16 : 0
        if rightView != nil {
            rightPadding += 24
        }
        return CGRect(x: bounds.origin.x + topBottomInset, y: bounds.origin.y + leftRightInset, width: bounds.size.width - 2 * leftRightInset - rightPadding - suffixMarging, height: bounds.size.height - 2 * topBottomInset)
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.origin.x + topBottomInset, y: bounds.origin.y + leftRightInset, width: bounds.size.width - 2 * leftRightInset - suffixMarging, height: bounds.size.height - 2 * topBottomInset)
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.rightViewRect(forBounds: bounds)
        rect.origin.x -= 10
        return rect
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setBorder()
    }

    // MARK: - Actions

    func setBorder() {
        if isError {
            layer.borderColor = UIColorManager.NotificationError.cgColor
            return
        }

        layer.borderColor = isEditing ? UIColorManager.BrandNorm.cgColor : UIColorManager.InteractionWeakDisabled.cgColor
    }

    @objc private func togglePasswordVisibility() {
        isSecureTextEntry = !isSecureTextEntry

        showMaskButton()

        if let existingText = text, isSecureTextEntry {
            /* When toggling to secure text, all text will be purged if the user
             continues typing unless we intervene. This is prevented by first
             deleting the existing text and then recovering the original text. */
            deleteBackward()

            if let textRange = textRange(from: beginningOfDocument, to: endOfDocument) {
                replace(textRange, withText: existingText)
            }
        }

        /* Reset the selected text range since the cursor can end up in the wrong
         position after a toggle because the text might vary in width */
        if let existingSelectedTextRange = selectedTextRange {
            selectedTextRange = nil
            selectedTextRange = existingSelectedTextRange
        }
    }

    private func showMaskButton() {
        unmaskButton.setImage(UIImage(named: isSecureTextEntry ? "UnmaskIcon" : "MaskIcon", in: PMUIFoundations.bundle, compatibleWith: nil), for: .normal)

        rightViewMode = .always
        rightView = unmaskButton
    }
}
