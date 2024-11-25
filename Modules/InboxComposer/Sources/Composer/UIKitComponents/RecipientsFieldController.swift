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

enum RecipientsFieldControllerState {
    case idle
    case editing
}

enum RecipientsFieldEvent {
    case onRecipientSelected(index: Int)
    case onReturnKeyPressed(text: String)
    case onDeleteKeyPressedInsideEmptyInputField
    case onDeleteKeyPressedOutsideInputField
    case onDidEndEditing
}

final class RecipientsFieldController: UIViewController {
    private let label = SubviewFactory.title
    private let stack = SubviewFactory.stack
    private let editingController = RecipientsFieldEditingController()
    private let idleController = RecipientsFieldIdleController()

    private var state: RecipientsFieldControllerState = .idle {
        didSet {
            if oldValue != state { updateView(for: state) }
        }
    }

    var recipients: [RecipientUIModel] {
        didSet {
            if oldValue != recipients {
                updateView(for: state)
            }
        }
    }

    var onEvent: ((RecipientsFieldEvent) -> Void)?

    init(title: String, recipients: [RecipientUIModel]) {
        self.recipients = recipients
        label.text = title
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
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DS.Spacing.large),
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: DS.Spacing.mediumLight),
            stack.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: DS.Spacing.small),
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.standard),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc
    private func onIdleControllerTap() {
        state = .editing
    }
    
    private func updateView(for state: RecipientsFieldControllerState) {
        updateView(for: state, noCellSelected: true)
    }

    private func updateView(for state: RecipientsFieldControllerState, noCellSelected: Bool) {
        idleController.view.isHidden = state == .editing
        editingController.view.isHidden = state == .idle
        switch state {
        case .idle:
            editingController.scrollToLast()
            idleController.configure(recipient: recipients.first, numExtra: recipients.count - 1)
            DispatchQueue.main.async {
                self.onEvent?(.onDidEndEditing)
            }
        case .editing:
            editingController.recipients = recipients
            if recipients.filter(\.isSelected).isEmpty {
                editingController.setFocus()
            }
        }
    }

    func setIdleState() {
        state = .idle
    }
}

extension RecipientsFieldController {
    private enum SubviewFactory {

        static var title: UILabel {
            let view = UILabel()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.font = UIFont.preferredFont(forTextStyle: .subheadline)
            view.textColor = UIColor(DS.Color.Text.hint)
            view.textAlignment = .center
            return view
        }

        static var stack: UIStackView {
            let view = UIStackView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.alignment = .center
            view.spacing = DS.Spacing.small
            view.directionalLayoutMargins = .init(top: 0, leading: DS.Spacing.mediumLight, bottom: 0, trailing: DS.Spacing.mediumLight)
            view.isLayoutMarginsRelativeArrangement = true
            return view
        }
    }
}
