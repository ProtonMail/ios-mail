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

enum DraftActionBarEvent {
    case onPickAttachmentSource
    case onDiscardDraft
}

final class DraftActionBarViewController: UIViewController {
    private let stack = SubviewFactory.stack
    private let attachmentButton = SubviewFactory.attachmentButton
    private let discardButton = SubviewFactory.discardButton
    private let spacer = UIView()
    private let buttonSize = 40.0
    var onEvent: ((DraftActionBarEvent) -> Void)?

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setUpConstraints()
    }

    private func setUpUI() {
        stack.addArrangedSubview(attachmentButton)
        stack.addArrangedSubview(spacer)
        stack.addArrangedSubview(discardButton)
        attachmentButton.addTarget(self, action: #selector(onAttachmentTap), for: .touchUpInside)
        discardButton.addTarget(self, action: #selector(onDiscardDraftTap), for: .touchUpInside)
        view.addSubview(stack)

        view.backgroundColor = DS.Color.Background.norm.toDynamicUIColor
        view.layer.masksToBounds = false
        view.layer.shadowOffset = .init(width: 0.0, height: -1.0)
        view.layer.shadowColor = DS.Color.Shade.shade10.toDynamicUIColor.cgColor
        view.layer.shadowOpacity = 1.0
    }

    private func setUpConstraints() {
        view.translatesAutoresizingMaskIntoConstraints = false
        spacer.translatesAutoresizingMaskIntoConstraints = false
        attachmentButton.setContentHuggingPriority(.required, for: .horizontal)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        discardButton.setContentHuggingPriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DS.Spacing.standard),
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.standard),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            attachmentButton.widthAnchor.constraint(equalToConstant: buttonSize),
            attachmentButton.heightAnchor.constraint(equalTo: attachmentButton.widthAnchor),
            discardButton.widthAnchor.constraint(equalToConstant: buttonSize),
            discardButton.heightAnchor.constraint(equalTo: attachmentButton.widthAnchor),
        ])
    }

    @objc
    private func onAttachmentTap() {
        onEvent?(.onPickAttachmentSource)
    }

    @objc
    private func onDiscardDraftTap() {
        onEvent?(.onDiscardDraft)
    }
}

extension DraftActionBarViewController {

    private enum SubviewFactory {

        static var stack: UIStackView {
            let view = UIStackView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.distribution = .fill
            view.alignment = .fill
            return view
        }

        static var attachmentButton: UIButton {
            UIButton().configWithImage(image: UIImage(resource: DS.Icon.icPaperClip))
        }

        static var discardButton: UIButton {
            UIButton().configWithImage(image: UIImage(resource: DS.Icon.icTrashCross))
        }
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
