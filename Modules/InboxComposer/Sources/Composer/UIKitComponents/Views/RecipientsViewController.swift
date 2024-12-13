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
import UIKit

enum RecipientFieldsVisibility {
    case ccAndBccCollapsed
    case allExpandedByUser
    case allExpandedByContent
}

final class RecipientsViewController: UIViewController {
    private let recipientsStack = SubviewFactory.recipientsStack
    private let toStack = SubviewFactory.toStack
    private let toField = RecipientsFieldController(group: .to)
    private let ccField = RecipientsFieldController(group: .cc)
    private let bccField = RecipientsFieldController(group: .bcc)
    private let chevronButton = SubviewFactory.chevronButton
    private let ccAndBccViews: [UIView]

    private var visibilityState: RecipientFieldsVisibility = .ccAndBccCollapsed {
        didSet {
            updateCcAndBccVisibility()
        }
    }

    var onEvent: ((RecipientsFieldEvent, RecipientGroupType) -> Void)? {
        didSet {
            toField.onEvent = { [weak self] in self?.onEvent?($0, .to) }
            ccField.onEvent = { [weak self] in self?.onEvent?($0, .cc) }
            bccField.onEvent = { [weak self] in self?.onEvent?($0, .bcc) }
        }
    }

    init() {
        self.ccAndBccViews = [ComposerSeparator(), ccField.view, ComposerSeparator(), bccField.view]
        super.init(nibName: nil, bundle: nil)
        setUpUI()
        setUpConstraints()
    }
    required init?(coder: NSCoder) { nil }

    private func setUpUI() {
        updateCcAndBccVisibility()

        toStack.addArrangedSubview(toField.view)
        toStack.addArrangedSubviewWithInsets(chevronButton, insets: .init(top: DS.Spacing.small, left: 0, bottom: 0, right: 0))
        ([toStack] + ccAndBccViews).forEach(recipientsStack.addArrangedSubview)

        // Adding the main `recipientsStack` to the view and the VCs to the view controller hierarchy
        [toField, ccField, bccField].forEach { addChild($0) }
        view.addSubview(recipientsStack)
        [toField, ccField, bccField].forEach { $0.didMove(toParent: self) }

        chevronButton.addTarget(self, action: #selector(onChevronTap), for: .touchUpInside)
    }

    private func setUpConstraints() {
        view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            recipientsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            recipientsStack.topAnchor.constraint(equalTo: view.topAnchor),
            recipientsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.standard),
            recipientsStack.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            chevronButton.widthAnchor.constraint(equalToConstant: 40),
            chevronButton.heightAnchor.constraint(equalTo: chevronButton.widthAnchor),
            chevronButton.trailingAnchor.constraint(equalTo: recipientsStack.trailingAnchor),
        ])
    }

    private func updateCcAndBccVisibility() {
        let chevronImage: UIImage
        let areCcAndBccHidden: Bool
        switch visibilityState {
        case .ccAndBccCollapsed:
            chevronImage = UIImage(resource: DS.Icon.icChevronTinyDown)
            areCcAndBccHidden = true
        case .allExpandedByUser:
            chevronImage = UIImage(resource: DS.Icon.icChevronTinyUp)
            areCcAndBccHidden = false
        case .allExpandedByContent:
            chevronImage = UIImage(resource: DS.Icon.icChevronTinyUp)
            areCcAndBccHidden = false
        }
        chevronButton.isHidden = visibilityState == .allExpandedByContent
        chevronButton.setImage(chevronImage, for: .normal)
        ccAndBccViews.forEach { $0.isHidden = areCcAndBccHidden }
    }

    @objc
    private func onChevronTap() {
        visibilityState = visibilityState == .ccAndBccCollapsed 
        ? .allExpandedByUser
        : .ccAndBccCollapsed
    }

    func updateRecipientFieldStates(to: RecipientFieldState, cc: RecipientFieldState, bcc: RecipientFieldState) {
        toField.state = to
        ccField.state = cc
        bccField.state = bcc

        let areThereRecipientsInCcOrBcc = !ccField.state.recipients.isEmpty || !bccField.state.recipients.isEmpty
        let isCcOrBccFocused = ccField.state.controllerState != .idle || bccField.state.controllerState != .idle

        visibilityState = areThereRecipientsInCcOrBcc || isCcOrBccFocused
        ? .allExpandedByContent
        : .ccAndBccCollapsed
    }
}

extension RecipientsViewController {

    private enum SubviewFactory {

        static var recipientsStack: UIStackView {
            let view = UIStackView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.axis = .vertical
            view.alignment = .fill
            view.distribution = .fill
            view.spacing = 0
            return view
        }

        static var toStack: UIStackView {
            let view = UIStackView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.alignment = .leading
            view.spacing = DS.Spacing.standard
            return view
        }

        static var chevronButton: UIButton {
            ComposerSubviewFactory.chevronButton
        }
    }
}
