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

final class RecipientsFieldController: UIViewController {

    enum Event {
        case onFieldTap
        case onInputChange(text: String)
        case onRecipientSelected(index: Int)
        case onReturnKeyPressed
        case onDeleteKeyPressedInsideEmptyInputField
        case onDeleteKeyPressedOutsideInputField
    }

    private let label = SubviewFactory.title
    private let stack = SubviewFactory.stack
    private let idleController = RecipientsFieldIdleController()
    private let expandedController: RecipientsFieldExpandedController
    private let editingController: RecipientsFieldEditingController

    var state: RecipientFieldState {
        didSet {
            if oldValue != state { updateView(for: state) }
        }
    }

    var onEvent: ((Event) -> Void)?

    init(group: RecipientGroupType, invalidAddressAlertStore: InvalidAddressAlertStateStore) {
        self.state = .initialState(group: group)
        self.expandedController = .init(state: self.state)
        self.editingController = .init(state: self.state, invalidAddressAlertStore: invalidAddressAlertStore)
        label.text = group.string
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setUpConstraints()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }

    private func setUpUI() {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        stack.addArrangedSubview(idleController.view)
        stack.addArrangedSubview(editingController.view)
        stack.addArrangedSubview(expandedController.view)
        expandedController.view.isHidden = state.controllerState != .expanded
        editingController.view.isHidden = state.controllerState != .editing && state.controllerState != .contactPicker
        view.addSubview(stack)

        editingController.onEvent = { [weak self] event in
            switch event {
            case .onInputChange(let text):
                self?.onEvent?(.onInputChange(text: text))
            case .onRecipientSelected(let index):
                self?.onEvent?(.onRecipientSelected(index: index))
            case .onReturnKeyPressed:
                self?.onEvent?(.onReturnKeyPressed)
            case .onDeleteKeyPressedInsideEmptyInputField:
                self?.onEvent?(.onDeleteKeyPressedInsideEmptyInputField)
            case .onDeleteKeyPressedOutsideInputField:
                self?.onEvent?(.onDeleteKeyPressedOutsideInputField)
            }
        }

        let idleViewTapGesture = UITapGestureRecognizer()
        idleViewTapGesture.addTarget(self, action: #selector(onIdleControllerTap))
        idleController.view.addGestureRecognizer(idleViewTapGesture)

        let expandedViewTapGesture = UITapGestureRecognizer()
        expandedViewTapGesture.addTarget(self, action: #selector(onIdleControllerTap))
        expandedController.view.addGestureRecognizer(expandedViewTapGesture)
    }

    private func setUpConstraints() {
        let verticalMargin = DS.Spacing.small
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DS.Spacing.large),
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: DS.Spacing.mediumLight + verticalMargin),
            stack.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: DS.Spacing.small),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: verticalMargin),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.standard),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -verticalMargin)
        ])
    }

    @objc
    private func onIdleControllerTap() {
        onEvent?(.onFieldTap)
    }

    private func updateView(for state: RecipientFieldState) {
        idleController.view.isHidden = state.controllerState != .collapsed
        expandedController.view.isHidden = state.controllerState != .expanded
        editingController.view.isHidden = state.controllerState == .collapsed || state.controllerState == .expanded
        switch state.controllerState {
        case .collapsed:
            editingController.scrollToLast()
            editingController.clearCursor()
            idleController.configure(recipient: state.recipients.first, numExtra: state.recipients.count - 1)
            updateStateInExpandedAndEditingViews(state)
        case .expanded:
            editingController.scrollToLast()
            editingController.clearCursor()
            updateStateInExpandedAndEditingViews(state)
        case .editing:
            updateStateInExpandedAndEditingViews(state)
            if state.recipients.filter(\.isSelected).isEmpty {
                editingController.setFocus()
            }
        case .contactPicker:
            editingController.state = state
        }

        view.layoutIfNeeded()
    }

    private func updateStateInExpandedAndEditingViews(_ state: RecipientFieldState) {
        expandedController.state = state
        editingController.state = state
    }
}

extension RecipientsFieldController {
    private enum SubviewFactory {

        static var title: UILabel {
            ComposerSubviewFactory.fieldTitle
        }

        static var stack: UIStackView {
            let view = UIStackView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.alignment = .center
            view.spacing = DS.Spacing.small
            view.directionalLayoutMargins = .init(top: 0, leading: DS.Spacing.small, bottom: 0, trailing: DS.Spacing.small)
            view.isLayoutMarginsRelativeArrangement = true
            return view
        }
    }
}
