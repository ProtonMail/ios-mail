// Copyright (c) 2025 Proton Technologies AG
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

final class PlainTextBodyEditorController: UIViewController, BodyEditor {
    private let textView = SubviewFactory.textView
    private var hasBodyInitialFocusBeenSet = false
    var onEvent: ((BodyEditorEvent) -> Void)?

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setUpConstraints()
    }

    private func setUpUI() {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        textView.delegate = self
        textView.imagePasteDelegate = self
    }

    private func setUpConstraints() {
        let margin = DS.Spacing.large
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            textView.topAnchor.constraint(equalTo: view.topAnchor, constant: margin),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -margin),
        ])
    }

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    func setBodyInitialFocus() {
        guard !hasBodyInitialFocusBeenSet else { return }
        hasBodyInitialFocusBeenSet = true
        textView.becomeFirstResponder()
        textView.selectedRange = NSRange(location: 0, length: 0)
    }

    func updateBody(_ body: String) {
        textView.text = body
    }

    func handleBodyAction(_ action: ComposerBodyAction) {
        switch action {
        case .insertText, .insertInlineImages, .removeInlineImage:
            break
        case .reloadBody(let body, _):
            updateBody(body)
        }
    }
}

extension PlainTextBodyEditorController: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        onEvent?(.onStartEditing)
    }

    func textViewDidChange(_ textView: UITextView) {
        onEvent?(.onBodyChange(body: textView.text))
    }
}

extension PlainTextBodyEditorController: ImagePasteDelegate {

    func didDetectImagePaste(image: UIImage) {
        onEvent?(.onImagePasted(image: image))
    }
}

extension PlainTextBodyEditorController {

    enum SubviewFactory {

        static var textView: PastingTextView {
            let view = PastingTextView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = DS.Color.Background.norm.toDynamicUIColor
            let baseFont = UIFont.monospacedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
            view.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: baseFont)
            view.textColor = DS.Color.Text.norm.toDynamicUIColor
            view.adjustsFontForContentSizeCategory = true
            view.isScrollEnabled = false
            view.textContainer.lineFragmentPadding = 0
            return view
        }
    }
}
