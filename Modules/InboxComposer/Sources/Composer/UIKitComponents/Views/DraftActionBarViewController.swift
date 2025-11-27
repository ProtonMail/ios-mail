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

import InboxCore
import InboxDesignSystem
import UIKit
import proton_app_uniffi

final class DraftActionBarViewController: UIViewController {
    struct State {
        let isAddingAttachmentsEnabled: Bool
        var isPasswordProtected: Bool
        var expirationTime: DraftExpirationTime
    }

    enum Event {
        case onPickAttachmentSource
        case onPasswordProtection
        case onRemovePasswordProtection
        case onExpirationTime(DraftExpirationTime)
        case onCustomExpirationTime
        case onDiscardDraft
    }

    private let stack = SubviewFactory.stack
    private let attachmentButton = SubviewFactory.attachmentButton
    private let passwordButton = SubviewFactory.passwordButton
    private let expirationButton = SubviewFactory.expirationButton
    private let discardButton = SubviewFactory.discardButton
    private let spacer = UIView()
    private let topBorder = SubviewFactory.topBorder
    private let buttonSize = 40.0
    private let messageExpirationLearnMoreUrl = URL(string: "https://proton.me/support/expiration")!
    var onEvent: ((Event) -> Void)?

    var state: State {
        didSet { applyState() }
    }

    init(state: State) {
        self.state = state
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setUpConstraints()
    }

    private func setUpUI() {
        if state.isAddingAttachmentsEnabled {
            stack.addArrangedSubview(attachmentButton)
        }

        stack.addArrangedSubview(passwordButton)
        stack.addArrangedSubview(expirationButton)
        stack.addArrangedSubview(spacer)
        stack.addArrangedSubview(discardButton)
        attachmentButton.addTarget(self, action: #selector(onAttachmentTap), for: .touchUpInside)
        passwordButton.addTarget(self, action: #selector(onPasswordProtectionTap), for: .touchUpInside)
        passwordButton.menu = UIMenu(children: getPasswordMenu())
        discardButton.addTarget(self, action: #selector(onDiscardDraftTap), for: .touchUpInside)
        view.addSubview(stack)
        view.addSubview(topBorder)

        view.backgroundColor = DS.Color.Background.norm.toDynamicUIColor

        applyState()
    }

    private func setUpConstraints() {
        view.translatesAutoresizingMaskIntoConstraints = false
        topBorder.translatesAutoresizingMaskIntoConstraints = false
        spacer.translatesAutoresizingMaskIntoConstraints = false
        attachmentButton.setContentHuggingPriority(.required, for: .horizontal)
        passwordButton.setContentHuggingPriority(.required, for: .horizontal)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        discardButton.setContentHuggingPriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DS.Spacing.standard),
            stack.topAnchor.constraint(equalTo: topBorder.bottomAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.standard),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        NSLayoutConstraint.activate([
            topBorder.heightAnchor.constraint(equalToConstant: 1),
            topBorder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBorder.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBorder.topAnchor.constraint(equalTo: view.topAnchor),
        ])
        [attachmentButton, passwordButton, discardButton].forEach { button in
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: buttonSize),
                button.heightAnchor.constraint(equalTo: button.widthAnchor),
            ])
        }
    }

    private func applyState() {
        passwordButton.buttonState = state.isPasswordProtected ? .checked : .unchecked
        passwordButton.showsMenuAsPrimaryAction = state.isPasswordProtected

        expirationButton.buttonState = state.expirationTime != .never ? .checked : .unchecked
        generateExpirationMenu(with: state.expirationTime)
    }

    private func getPasswordMenu() -> [UIMenuElement] {
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

    private func generateExpirationMenu(with expirationTime: DraftExpirationTime) {
        func action(_ title: LocalizedStringResource, time: DraftExpirationTime) -> UIAction {
            UIAction(title: title.string, state: expirationTime == time ? .on : .off) {
                [weak self] _ in self?.onEvent?(.onExpirationTime(time))
            }
        }

        var children: [UIMenuElement] = [
            specificDateAction(),
            action(L10n.MessageExpiration.afterThreeDays, time: .threeDays),
            action(L10n.MessageExpiration.afterOneDay, time: .oneDay),
            action(L10n.MessageExpiration.afterOneHour, time: .oneHour),
        ]
        if expirationTime != .never {
            children += [action(L10n.MessageExpiration.never, time: .never)]
        }
        let mainSection = UIMenu(options: .displayInline, children: children)

        let learnMore = UIAction(
            title: CommonL10n.learnMore.string,
            subtitle: L10n.MessageExpiration.howExpirationWorks.string,
            image: UIImage(symbol: .infoCircle)
        ) { [weak self] _ in
            guard let self else { return }
            UIApplication.shared.open(self.messageExpirationLearnMoreUrl)
        }
        let learnMoreSection = UIMenu(options: .displayInline, children: [learnMore])

        expirationButton.menu = UIMenu(title: L10n.MessageExpiration.menuTitle.string, children: [learnMoreSection, mainSection])
    }

    private func specificDateAction() -> UIAction {
        UIAction(
            title: L10n.MessageExpiration.specificDate.string,
            subtitle: state.expirationTime.customDateString,
            image: state.expirationTime.isCustomDate ? UIImage(resource: DS.Icon.icPencil) : nil,
            state: state.expirationTime.isCustomDate ? .on : .off,
            handler: { [weak self] _ in self?.onEvent?(.onCustomExpirationTime) }
        )
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

        static var topBorder: UIView {
            let view = UIView()
            view.backgroundColor = DS.Color.Border.light.toDynamicUIColor
            return view
        }

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

        static var passwordButton: CheckableIconButton {
            CheckableIconButton(icon: DS.Icon.icLock)
        }

        static var expirationButton: CheckableIconButton {
            let button = CheckableIconButton(icon: DS.Icon.icHourglass)
            button.showsMenuAsPrimaryAction = true
            return button
        }

        static var discardButton: UIButton {
            UIButton().configWithImage(image: UIImage(resource: DS.Icon.icTrashCross))
        }
    }
}

private extension DraftExpirationTime {

    var customDateString: String? {
        if let customDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: customDate)
        }
        return nil
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
