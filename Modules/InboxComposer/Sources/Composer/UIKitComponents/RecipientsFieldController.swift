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

enum RecipientsFieldEvent {
    case onFieldTap
    case onInputChange(text: String)
    case onRecipientSelected(index: Int)
    case onReturnKeyPressed(text: String)
    case onDeleteKeyPressedInsideEmptyInputField
    case onDeleteKeyPressedOutsideInputField
}

final class RecipientsFieldController: UIViewController {
    private let label = SubviewFactory.title
    private let stack = SubviewFactory.stack
    private let editingController: RecipientsFieldEditingController
    private let idleController = RecipientsFieldIdleController()

    var state: RecipientFieldState {
        didSet {
            if oldValue != state { updateView(for: state) }
        }
    }

    var onEvent: ((RecipientsFieldEvent) -> Void)?

    init(group: RecipientGroupType) {
        self.state = .initialState(group: group)
        self.editingController = .init(state: self.state)
        label.text = group.string
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setUpConstraints()
    }

    private func setUpUI() {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        stack.addArrangedSubview(idleController.view)
        stack.addArrangedSubview(editingController.view)
        editingController.view.isHidden = true
        view.addSubview(stack)

        editingController.onEvent = {[weak self] event in
            switch event {
            case .onInputChange(let text):
                self?.onEvent?(.onInputChange(text: text))
            case .onRecipientSelected(let index):
                self?.onEvent?(.onRecipientSelected(index: index))
            case .onReturnKeyPressed(let text):
                self?.onEvent?(.onReturnKeyPressed(text: text))
            case .onDeleteKeyPressedInsideEmptyInputField:
                self?.onEvent?(.onDeleteKeyPressedInsideEmptyInputField)
            case .onDeleteKeyPressedOutsideInputField:
                self?.onEvent?(.onDeleteKeyPressedOutsideInputField)
            }
        }

        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(onIdleControllerTap))
        idleController.view.addGestureRecognizer(tapGesture)
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
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -verticalMargin),
        ])
    }

    @objc
    private func onIdleControllerTap() {
        onEvent?(.onFieldTap)
    }
    
    private func updateView(for state: RecipientFieldState) {
        updateView(for: state, noCellSelected: true)
    }

    private func updateView(for state: RecipientFieldState, noCellSelected: Bool) {
        idleController.view.isHidden = state.controllerState == .editing
        editingController.view.isHidden = state.controllerState == .idle
        switch state.controllerState {
        case .idle:
            editingController.scrollToLast()
            editingController.clearCursor()
            idleController.configure(recipient: state.recipients.first, numExtra: state.recipients.count - 1)
        case .editing:
            editingController.state = state
            if state.recipients.filter(\.isSelected).isEmpty {
                editingController.setFocus()
            }
        case .contactPicker:
            editingController.state = state
        }
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
