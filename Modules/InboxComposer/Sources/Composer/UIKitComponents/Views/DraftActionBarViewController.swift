// Copyright (c) 2024 Proton Technologies AG
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

import InboxDesignSystem
import InboxCore
import UIKit

final class DraftActionBarViewController: UIViewController {

    enum Event {
        case onPickAttachmentSource
        case onPasswordProtection
        case onRemovePasswordProtection
        case onDiscardDraft
    }

    private let stack = SubviewFactory.stack
    private let attachmentButton = SubviewFactory.attachmentButton
    private let passwordButton = SubviewFactory.passwordButton
    private let discardButton = SubviewFactory.discardButton
    private let spacer = UIView()
    private let buttonSize = 40.0
    private let isAddingAttachmentsEnabled: Bool
    var onEvent: ((Event) -> Void)?

    var passwordState: PasswordButton.State = .noPassword {
        didSet {
            passwordButton.buttonState = passwordState
            passwordButton.showsMenuAsPrimaryAction = passwordState == .hasPassword
        }
    }

    init(isAddingAttachmentsEnabled: Bool) {
        self.isAddingAttachmentsEnabled = isAddingAttachmentsEnabled
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setUpConstraints()
    }

    private func setUpUI() {
        func getPasswordMenuActions() -> [UIAction] {
            let editPassword = UIAction(
                title: L10n.PasswordProtection.editPassword.string,
                image: UIImage(resource: DS.Icon.icPencil)
            ) { [weak self] _ in
                self?.onPasswordProtectionTap()
            }
            let removePassword = UIAction(
                title: CommonL10n.remove.string,
                image: UIImage(resource: DS.Icon.icTrash)
            ) { [weak self] _ in
                self?.onEvent?(.onRemovePasswordProtection)
            }
            return [removePassword, editPassword]
        }

        if isAddingAttachmentsEnabled {
            stack.addArrangedSubview(attachmentButton)
        }

        stack.addArrangedSubview(passwordButton)
        stack.addArrangedSubview(spacer)
        stack.addArrangedSubview(discardButton)
        attachmentButton.addTarget(self, action: #selector(onAttachmentTap), for: .touchUpInside)
        passwordButton.addTarget(self, action: #selector(onPasswordProtectionTap), for: .touchUpInside)
        passwordButton.menu = UIMenu(title: "", children: getPasswordMenuActions())
        discardButton.addTarget(self, action: #selector(onDiscardDraftTap), for: .touchUpInside)
        view.addSubview(stack)

        view.backgroundColor = DS.Color.Background.norm.toDynamicUIColor
        view.layer.masksToBounds = false
        view.layer.shadowOffset = .init(width: 0.0, height: -1.0)
        view.layer.shadowColor = DS.Color.Shade.shade10.toDynamicUIColor.cgColor
        view.layer.shadowOpacity = 1.0
    }

    private func setUpConstraints() {
        view.translatesAutoresizingMaskIntoConstraints = false
        spacer.translatesAutoresizingMaskIntoConstraints = false
        attachmentButton.setContentHuggingPriority(.required, for: .horizontal)
        passwordButton.setContentHuggingPriority(.required, for: .horizontal)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        discardButton.setContentHuggingPriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DS.Spacing.standard),
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.standard),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        [attachmentButton, passwordButton, discardButton].forEach { button in
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: buttonSize),
                button.heightAnchor.constraint(equalTo: button.widthAnchor),
            ])
        }
    }

    @objc
    private func onAttachmentTap() {
        onEvent?(.onPickAttachmentSource)
    }

    @objc
    private func onPasswordProtectionTap() {
        onEvent?(.onPasswordProtection)
    }

    @objc
    private func onDiscardDraftTap() {
        onEvent?(.onDiscardDraft)
    }
}

extension DraftActionBarViewController {

    private enum SubviewFactory {

        static var stack: UIStackView {
            let view = UIStackView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.distribution = .fill
            view.alignment = .fill
            view.spacing = DS.Spacing.standard
            return view
        }

        static var attachmentButton: UIButton {
            UIButton().configWithImage(image: UIImage(resource: DS.Icon.icPaperClip))
        }

        static var passwordButton: PasswordButton {
            PasswordButton()
        }

        static var discardButton: UIButton {
            UIButton().configWithImage(image: UIImage(resource: DS.Icon.icTrashCross))
        }
    }
}

private extension UIButton {

    func configWithImage(image: UIImage) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        contentMode = .scaleAspectFit
        tintColor = DS.Color.Icon.hint.toDynamicUIColor
        setImage(image, for: .normal)
        setImage(image.withTintColor(DS.Color.Icon.norm.toDynamicUIColor, renderingMode: .alwaysOriginal), for: .highlighted)
        return self
    }
}
