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
    case viewWillDisappear
    case recipientFieldEvent(RecipientsFieldEvent, RecipientGroupType)
    case contactPickerEvent(ContactPickerEvent, RecipientGroupType)
    case fromFieldEvent(FromFieldViewEvent)
    case subjectFieldEvent(SubjectFieldViewEvent)
    case bodyEvent(BodyEditorEvent)
}

final class ComposerController: UIViewController {
    private let scrollView = SubviewFactory.scrollView
    private let composerStack = SubviewFactory.composerStack
    private let contactPicker = ContactPickerController()
    private let recipientsController = RecipientsViewController()
    private let fromField = FromFieldView()
    private let subjectField = SubjectFieldView()
    private let bodyEditor = BodyEditorController()
    private let onEvent: (ComposerControllerEvent) -> Void

    var state: ComposerState {
        didSet {
            updateStatesOfSubviews(with: state)
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
        setInitialStates(with: state)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onEvent(.viewWillDisappear)
    }

    private func setUpUI() {
        view.backgroundColor = UIColor(DS.Color.Background.norm)

        addViewController(recipientsController, using: composerStack.addArrangedSubview)
        composerStack.addArrangedSubview(ComposerSeparator())
        composerStack.addArrangedSubview(fromField)
        composerStack.addArrangedSubview(ComposerSeparator())
        composerStack.addArrangedSubview(subjectField)
        composerStack.addArrangedSubview(ComposerSeparator())
        addViewController(bodyEditor, using: composerStack.addArrangedSubview)

        scrollView.addSubview(composerStack)
        view.addSubview(scrollView)

        contactPicker.view.isHidden = true
        view.addSubview(contactPicker.view)

        recipientsController.onEvent = {[weak self] event, group in self?.onEvent(.recipientFieldEvent(event, group)) }
        contactPicker.onEvent = { [weak self] event in
            guard let group = self?.state.editingRecipientsGroup else { return }
            self?.onEvent(.contactPickerEvent(event, group))
        }
        fromField.onEvent = { [weak self] in self?.onEvent(.fromFieldEvent($0)) }
        subjectField.onEvent = { [weak self] in self?.onEvent(.subjectFieldEvent($0)) }
        bodyEditor.onEvent = { [weak self] in self?.onEvent(.bodyEvent($0)) }
    }

    private func setupConstraints() {

        [contactPicker.view, scrollView].forEach {
            NSLayoutConstraint.activate([
                $0.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                $0.topAnchor.constraint(equalTo: view.topAnchor),
                $0.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }

        NSLayoutConstraint.activate([
            composerStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            composerStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            composerStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            composerStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            composerStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setInitialStates(with state: ComposerState) {
        // FIXME: have a precached webview strategy
        DispatchQueue.main.async { [weak self] in
            self?.bodyEditor.updateBody(html: state.initialBody)
        }
    }

    private func updateStatesOfSubviews(with state: ComposerState) {
        recipientsController.updateRecipientFieldStates(
            to: state.toRecipients,
            cc: state.ccRecipients,
            bcc: state.bccRecipients
        )
        contactPicker.recipientsFieldState = state.editingRecipientFieldState
        fromField.text = state.senderEmail
        subjectField.text = state.subject
    }
}

extension ComposerController {

    private enum SubviewFactory {

        static var scrollView: UIScrollView {
            let view = UIScrollView()
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }

        static var composerStack: UIStackView {
            let view = UIStackView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.axis = .vertical
            view.alignment = .fill
            view.distribution = .fill
            view.spacing = 0
            return view
        }
    }
}
