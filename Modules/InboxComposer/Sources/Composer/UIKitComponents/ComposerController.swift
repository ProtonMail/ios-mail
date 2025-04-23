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

final class ComposerController: UIViewController {

    enum Event {
        case viewDidDisappear
        case recipientFieldEvent(RecipientsFieldController.Event, RecipientGroupType)
        case contactPickerEvent(ContactPickerController.Event, RecipientGroupType)
        case fromFieldEvent(FromFieldView.Event)
        case subjectFieldEvent(SubjectFieldView.Event)
        case attachmentEvent(DraftAttachmentsSectionViewController.Event)
        case bodyEvent(BodyEvent)
        case actionBarEvent(DraftActionBarViewController.Event)
    }

    private let scrollView = SubviewFactory.scrollView
    private let composerStack = SubviewFactory.composerStack
    private let contactPicker = ContactPickerController()
    private let recipientsController: RecipientsViewController
    private let fromField = FromFieldView()
    private let subjectField = SubjectFieldView()
    private let attachmentsController = DraftAttachmentsSectionViewController()
    private let bodyEditor: BodyEditorController
    private let draftActionBarController = DraftActionBarViewController()
    private let onEvent: (Event) -> Void

    var state: ComposerState {
        didSet {
            updateStatesOfSubviews(with: state)
        }
    }

    init(
        state: ComposerState,
        embeddedImageProvider: EmbeddedImageProvider,
        invalidAddressAlertStore: InvalidAddressAlertStateStore,
        onEvent: @escaping (Event) -> Void
    ) {
        self.state = state
        self.bodyEditor = BodyEditorController(embeddedImageProvider: embeddedImageProvider)
        self.recipientsController = RecipientsViewController(invalidAddressAlertStore: invalidAddressAlertStore)

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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onEvent(.viewDidDisappear)
    }

    private func setUpUI() {
        view.backgroundColor = DS.Color.Background.norm.toDynamicUIColor

        addViewController(recipientsController, using: composerStack.addArrangedSubview)
        composerStack.addArrangedSubview(ComposerSeparator())
        composerStack.addArrangedSubview(fromField)
        composerStack.addArrangedSubview(ComposerSeparator())
        composerStack.addArrangedSubview(subjectField)
        composerStack.addArrangedSubview(ComposerSeparator())
        addViewController(attachmentsController, using: composerStack.addArrangedSubview)
        addViewController(bodyEditor, using: composerStack.addArrangedSubview)

        scrollView.addSubview(composerStack)
        view.addSubview(scrollView)
        addViewController(draftActionBarController, using: view.addSubview(_:))

        contactPicker.view.isHidden = true
        view.addSubview(contactPicker.view)

        recipientsController.onEvent = {[weak self] event, group in self?.onEvent(.recipientFieldEvent(event, group)) }
        contactPicker.onEvent = { [weak self] event in
            guard let group = self?.state.editingRecipientsGroup else { return }
            self?.onEvent(.contactPickerEvent(event, group))
        }
        fromField.onEvent = { [weak self] in self?.onEvent(.fromFieldEvent($0)) }
        subjectField.onEvent = { [weak self] in self?.onEvent(.subjectFieldEvent($0)) }
        attachmentsController.onEvent = { [weak self] in self?.onEvent(.attachmentEvent($0)) }
        bodyEditor.onEvent = { [weak self] event in
            guard let self else { return }
            switch event {
            case .onStartEditing, .onBodyChange:
                guard let bodyEvent = event.toBodyEvent else { return }
                self.onEvent(.bodyEvent(bodyEvent))
            case .onCursorPositionChange(let position):
                self.scrollToY(position.y)
            }
        }
        draftActionBarController.onEvent = { [weak self] in self?.onEvent(.actionBarEvent($0)) }
    }

    private func setupConstraints() {
        let closeKeyboardSeparation = 6.0
        contactPicker.view.anchorTo(view: view)
        composerStack.anchorTo(view: scrollView)

        NSLayoutConstraint.activate([
            composerStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: draftActionBarController.view.topAnchor),

            draftActionBarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            draftActionBarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            draftActionBarController.view.bottomAnchor.constraint(
                equalTo: view.keyboardLayoutGuide.topAnchor,
                constant: closeKeyboardSeparation
            )
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
        attachmentsController.uiModels = state.attachments
        if state.isInitialFocusInBody {
            bodyEditor.setBodyInitialFocus()
        }
    }

    private func scrollToY(_ yPosition: CGFloat) {
        guard let bodyEditorFrame = bodyEditor.view.superview?.convert(bodyEditor.view.frame, to: scrollView) else {
            return
        }
        let scrollViewVisibleArea = CGRect(origin: scrollView.contentOffset, size: scrollView.bounds.size)
        let verticalPaddingForBetterVivibility: CGFloat = 50
        let yPositionInScrollView = bodyEditorFrame.minY + yPosition
        let minVisibleY = scrollViewVisibleArea.minY
        let maxVisibleY = scrollViewVisibleArea.maxY - verticalPaddingForBetterVivibility

        let isCursorOutsideVisibleArea = yPositionInScrollView < minVisibleY || yPositionInScrollView > maxVisibleY
        guard isCursorOutsideVisibleArea else { return }

        let newOffsetY: CGFloat
        if yPositionInScrollView > maxVisibleY { // Cursor is below the visible area
            newOffsetY = yPositionInScrollView - scrollView.bounds.height + verticalPaddingForBetterVivibility
        } else { // Cursor is above the visible area
            newOffsetY = yPositionInScrollView - verticalPaddingForBetterVivibility
        }

        let adjustedOffset = CGPoint(x: scrollView.contentOffset.x, y: max(0, newOffsetY))
        scrollView.setContentOffset(adjustedOffset, animated: true)
    }

    func handleBodyAction(action: ComposerBodyAction) {
        bodyEditor.handleBodyAction(action: action)
    }
}


enum BodyEvent {
    case onStartEditing
    case onBodyChange(body: String)
}

private extension BodyEditorController.Event {

    var toBodyEvent: BodyEvent? {
        switch self {
        case .onStartEditing:
            .onStartEditing
        case .onBodyChange(let body):
            .onBodyChange(body: body)
        case .onCursorPositionChange:
            nil
        }
    }
}

private extension ComposerController {

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
