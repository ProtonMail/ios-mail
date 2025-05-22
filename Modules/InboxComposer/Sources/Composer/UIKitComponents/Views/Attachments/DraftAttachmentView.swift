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

final class DraftAttachmentView: TapHighlightView {

    enum Event {
        case onViewTap
        case onButtonTap
    }

    private let stack = SubviewFactory.stack
    private let icon = SubviewFactory.icon
    private let name = SubviewFactory.name
    private let size = SubviewFactory.size
    private let removeButton = SubviewFactory.removeButton
    private var uiModel: DraftAttachmentUIModel?
    var onEvent: ((Event, DraftAttachmentUIModel) -> Void)

    init(onEvent: @escaping ((Event, DraftAttachmentUIModel) -> Void)) {
        self.onEvent = onEvent
        super.init(frame: .zero)
        setUpView()
    }
    required init?(coder: NSCoder) { nil }

    override var intrinsicContentSize: CGSize {
        stack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }

    private func setUpView() {
        translatesAutoresizingMaskIntoConstraints = false
        let spacer = UIView()

        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(name)
        stack.addArrangedSubview(spacer)
        stack.addArrangedSubview(size)
        stack.addArrangedSubview(removeButton)
        addSubview(stack)

        backgroundColor = DS.Color.InteractionWeak.norm.toDynamicUIColor

        size.setContentCompressionResistancePriority(.required, for: .horizontal)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let padding: CGFloat = DS.Spacing.moderatelyLarge

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            icon.widthAnchor.constraint(equalToConstant: 20),
            icon.heightAnchor.constraint(equalTo: icon.widthAnchor),
            removeButton.widthAnchor.constraint(equalToConstant: 20),
            removeButton.heightAnchor.constraint(equalTo: removeButton.widthAnchor),
        ])

        applyCapsuleShape()
        removeButton.addTarget(self, action: #selector(removeButtonTapped), for: .touchUpInside)
        onHighlightViewTap = { [weak self] in
            guard let uiModel = self?.uiModel else { return }
            self?.onEvent(.onViewTap, uiModel)
        }
    }

    private func applyCapsuleShape() {
        layoutIfNeeded()
        layer.masksToBounds = true
        layer.cornerRadius = frame.height / 2.0
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let buttonFrameInParent = removeButton.convert(removeButton.bounds, to: self)
        let expandedTouchArea = buttonFrameInParent.insetBy(dx: -10, dy: -10)
        return expandedTouchArea.contains(point) ? removeButton : super.hitTest(point, with: event)
    }

    @objc private func removeButtonTapped(_: SpinnerButton) {
        guard let uiModel else { return }
        onEvent(.onButtonTap, uiModel)
    }

    func configure(uiModel: DraftAttachmentUIModel) {
        self.uiModel = uiModel
        icon.image = UIImage(resource: uiModel.attachment.mimeType.category.bigIcon)
        name.text = uiModel.attachment.name
        size.text = Formatter.bytesFormatter.string(fromByteCount: Int64(uiModel.attachment.size))

        let isError = uiModel.status.state.isError
        layer.borderColor = isError ? DS.Color.Notification.error.toDynamicUIColor.cgColor : UIColor.clear.cgColor
        layer.borderWidth = isError ? 1.0 : 0.0

        let isUploaded = uiModel.status.state == .uploaded
        removeButton.configure(isSpinning: !isUploaded && !isError)
        isTappable = isUploaded
    }
}

extension DraftAttachmentView {

    private enum SubviewFactory {

        static var stack: UIStackView {
            let view = UIStackView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.axis = .horizontal
            view.alignment = .center
            view.distribution = .fill
            view.spacing = DS.Spacing.medium
            return view
        }

        static var icon: UIImageView {
            let view = UIImageView()
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }

        static var name: UILabel {
            let view = UILabel()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.font = UIFont.preferredFont(forTextStyle: .subheadline)
            view.textColor = DS.Color.Text.weak.toDynamicUIColor
            return view
        }

        static var size: UILabel {
            let view = UILabel()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.font = UIFont.preferredFont(forTextStyle: .footnote)
            view.textColor = DS.Color.Text.hint.toDynamicUIColor
            return view
        }

        static var removeButton: SpinnerButton {
            let view = SpinnerButton()
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }
    }
}

// MARK: TapHighlightView

class TapHighlightView: UIView {
    var isTappable: Bool = true
    var onHighlightViewTap: (() -> Void)?

    private func animateAlpha(to value: CGFloat) {
        guard isTappable else { return }
        UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveLinear) {
            self.alpha = value
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        animateAlpha(to: 0.5)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        animateAlpha(to: 1.0)
        if isTappable { onHighlightViewTap?() }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        animateAlpha(to: 1.0)
    }
}
