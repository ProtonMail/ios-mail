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

enum ComposerControllerEvent {
    case recipientFieldEvent(RecipientsFieldEvent, RecipientGroupType)
}

final class ComposerController: UIViewController {
    private let composerStack = SubviewFactory.composerStack
    private let toField = RecipientsFieldController(title: "To:".notLocalized, recipients: [])
    private let fakeBodyView = SubviewFactory.textView
    private let onEvent: (ComposerControllerEvent) -> Void

    var state: ComposerState {
        didSet {
            toField.recipients = state.recipients
        }
    }

    init(state: ComposerState, onEvent: @escaping (ComposerControllerEvent) -> Void) {
        self.state = state
        self.onEvent = onEvent
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setupConstraints()
    }

    func setUpUI() {
        composerStack.addArrangedSubview(toField.view)
        composerStack.addArrangedSubview(ComposerSeparator())
        composerStack.addArrangedSubview(fakeBodyView)
        view.addSubview(composerStack)

        toField.onEvent = { [weak self] in self?.onEvent(.recipientFieldEvent($0, .to)) }
        fakeBodyView.delegate = self
    }

    func setupConstraints() {
        toField.view.setContentHuggingPriority(.required, for: .horizontal)
        toField.view.setContentCompressionResistancePriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            composerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            composerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            composerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            composerStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
}

extension ComposerController: UITextViewDelegate {

    // FIXME: This is a momentary hack to manage focus for those views that are not just one single textfield component
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        toField.setIdleState()
        return true
    }
}

extension ComposerController {

    private enum SubviewFactory {

        static var composerStack: UIStackView {
            let view = UIStackView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.axis = .vertical
            view.alignment = .fill
            view.distribution = .fill
            return view
        }

        static var textView: UITextView {
            let view = UITextView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.text = "I'll be there!\n\nYours sincerely"
            return view
        }
    }
}
