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

import InboxCoreUI
import UIKit

enum RecipientsFieldEditingEvent {
    case onInputChange(text: String)
    case onRecipientSelected(index: Int)
    case onReturnKeyPressed
    case onDeleteKeyPressedInsideEmptyInputField
    case onDeleteKeyPressedOutsideInputField
}

final class RecipientsFieldEditingController: UIViewController {
    private let invalidAddressAlertStore: InvalidAddressAlertStateStore
    private let collectionView = SubviewFactory.collectionView

    private var contentSizeObservation: NSKeyValueObservation?
    private var heightConstraint: NSLayoutConstraint!

    private var cellUIModels: [RecipientCellUIModel] = [.cursor] {
        didSet {
            reloadCollectionItems()
        }
    }

    var state: RecipientFieldState {
        didSet {
            if oldValue.recipients != state.recipients {
                cellUIModels = state.recipients.map { RecipientCellUIModel.recipient($0) } + [.cursor]
            } else if oldValue.controllerState == .contactPicker && state.controllerState == .editing {
                reloadCollectionItems()
            }
        }
    }

    var onEvent: ((RecipientsFieldEditingEvent) -> Void)?

    init(state: RecipientFieldState, invalidAddressAlertStore: InvalidAddressAlertStateStore) {
        self.state = state
        self.invalidAddressAlertStore = invalidAddressAlertStore
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setUpConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        heightConstraint.constant = RecipientsFieldExpandedLayout.minCellHeight
        self.becomeFirstResponder()
        view.layoutIfNeeded()
    }

    private func setUpUI() {
        view.translatesAutoresizingMaskIntoConstraints = false

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(cellType: RecipientCell.self)
        collectionView.register(cellType: RecipientCursorCell.self)

        [collectionView].forEach(view.addSubview)

        contentSizeObservation = collectionView.observe(\.contentSize, options: .new) { [weak self] (collection, _) in
            self?.onContentSizeChage(collectionView: collection)
        }
    }

    private func setUpConstraints() {
        heightConstraint = collectionView.heightAnchor.constraint(equalToConstant: .zero)
        heightConstraint.isActive = true

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func setFocus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.scrollToLast(animated: false)
            self.setFocusOnCursor()
        }
    }

    func scrollToLast() {
        scrollToLast(animated: false)
    }

    func clearCursor() {
        visibleCursorCells().forEach { $0.clearText() }
    }
}

// MARK: Private functions

extension RecipientsFieldEditingController {

    private func onContentSizeChage(collectionView: UICollectionView) {
        let contentHeight = collectionView.collectionViewLayout.collectionViewContentSize.height
        heightConstraint.constant = max(contentHeight, RecipientsFieldExpandedLayout.minCellHeight)
    }

    private func reloadCollectionItems() {
        DispatchQueue.main.async { [unowned self] in
            UIView.performWithoutAnimation {
                // To avoid "AttributeGraph: cycle detected" we resign responder from UITextfield before the collection update.
                removeFocusFromCursor()
                collectionView
                    .performBatchUpdates({ collectionView.reloadSections(IndexSet(integer: 0)) }) { [weak self] _ in
                        self?.manageFocusAfterReload()
                    }
                if cellUIModels.count > 1 { scrollToLast(animated: false) }
            }

            view.layoutIfNeeded()
        }
    }

    private func manageFocusAfterReload() {
        if state.recipients.noneIsSelected { setFocusOnCursor() }
    }

    private func visibleCursorCells() -> [RecipientCursorCell] {
        collectionView.visibleCells.compactMap { $0 as? RecipientCursorCell }
    }

    private func removeFocusFromCursor() {
        visibleCursorCells().forEach { $0.removeFocus() }
    }

    private func setFocusOnCursor() {
        collectionView.layoutIfNeeded()
        visibleCursorCells().forEach { $0.setFocus() }
    }

    private func scrollToLast(animated: Bool) {
        collectionView.scrollToItem(
            at: IndexPath(item: cellUIModels.count - 1, section: 0),
            at: .bottom,
            animated: animated
        )
    }
}

// MARK: UICollectionViewDataSource

extension RecipientsFieldEditingController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cellUIModels.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: UICollectionViewCell
        switch cellUIModels[indexPath.item] {
        case .cursor:
            cell = cursorCell(for: collectionView, at: indexPath)
        case .recipient(let recipient):
            cell = recipientCell(for: collectionView, at: indexPath, recipient: recipient)
        }
        return cell
    }

    private func collectionContentWidth() -> CGFloat {
        collectionView.frame.width
    }

    private func cursorCell(for collectionView: UICollectionView, at indexPath: IndexPath) -> RecipientCursorCell {
        let cursorCell: RecipientCursorCell = collectionView.dequeueReusableCell(for: indexPath)
        cursorCell.shouldEndEditing = { [weak self] in
            guard let self else { return true }
            invalidAddressAlertStore.validateAndShowAlertIfNeeded()
            return invalidAddressAlertStore.recipientAddressValidator.canResignFocus()
        }
        cursorCell.onEvent = { [weak self] event in
            guard let self else { return }
            switch event {
            case .onTextChanged(let text):
                onEvent?(.onInputChange(text: text))
            case .onDeleteKeyPressedOnEmptyTextField:
                if !cellUIModels.filter(\.isRecipient).isEmpty { removeFocusFromCursor() }
                onEvent?(.onDeleteKeyPressedInsideEmptyInputField)
            case .onReturnKeyPressed:
                onEvent?(.onReturnKeyPressed)
            }
        }
        cursorCell.configure(maxWidth: collectionContentWidth(), input: state.input, state: state.controllerState)
        return cursorCell
    }

    private func recipientCell(
        for collectionView: UICollectionView,
        at indexPath: IndexPath,
        recipient: RecipientUIModel
    ) -> RecipientCell {
        let recipientCell: RecipientCell = collectionView.dequeueReusableCell(for: indexPath)
        recipientCell.configure(with: recipient, maxWidth: collectionContentWidth())
        return recipientCell
    }
}

// MARK: UICollectionViewDelegate

extension RecipientsFieldEditingController: UICollectionViewDelegate { 

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cellModel = cellUIModels[indexPath.row]
        switch cellModel {
        case .cursor:
            guard let cursorCell = collectionView.cellForItem(at: indexPath) as? RecipientCursorCell else { return }
            cursorCell.setFocus()
        case .recipient:
            onEvent?(.onRecipientSelected(index: indexPath.row))
        }
    }
}

// MARK: UIKeyInput

/*
 The logic in this extension allows this class to become first responder and show the keyboard without
 the use of a text field.
 */
extension RecipientsFieldEditingController: UIKeyInput {

    override var canBecomeFirstResponder: Bool {
        return true
    }

    var hasText: Bool { false }

    func insertText(_ text: String) { }

    func deleteBackward() { 
        onEvent?(.onDeleteKeyPressedOutsideInputField)
    }
}

extension RecipientsFieldEditingController {

    private enum SubviewFactory {

        static var collectionView: UICollectionView {
            let view = UICollectionView(frame: .zero, collectionViewLayout: .allRecipientsLayout)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = .clear
            view.isScrollEnabled = false
            return view
        }
    }
}
