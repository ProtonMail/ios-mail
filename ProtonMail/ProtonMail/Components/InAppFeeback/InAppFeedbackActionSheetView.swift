// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_UIFoundations
import UIKit

final class InAppFeedbackActionSheetView: UIView {
    private let ratings: [Rating]
    private let container = UIView()
    private let header = UIView()
    private let closeButton = SubviewsFactory.closeButton
    private let separator = SubviewsFactory.separator
    private let titleLabel = SubviewsFactory.titleLabel
    private let promptLabel = SubviewsFactory.promptLabel
    private lazy var ratingScaleView = RatingScaleView(ratings: ratings) { [weak self] rating in
        self?.onRatingSelection(rating)
    }
    lazy var feedbackCommentView = FeedbackCommentView { [weak self] comment in
        self?.didSubmit(comment: comment)
    }
    private let onRatingSelection: ((Rating) -> Void)
    private let onDismiss: (() -> Void?)
    private let onSubmit: ((String?) -> Void?)

    private var hideConstraint: NSLayoutConstraint!
    private var isExpanded = false

    init(ratings: [Rating],
         onRatingSelection: @escaping ((Rating) -> Void),
         onDismiss: @escaping (() -> Void?),
         onSubmit: @escaping ((String?) -> Void?)) {
        self.ratings = ratings
        self.onRatingSelection = onRatingSelection
        self.onDismiss = onDismiss
        self.onSubmit = onSubmit
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = ColorProvider.BackgroundNorm
        closeButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        addSubview(container)
        container.addSubview(header)
        container.addSubview(separator)
        container.addSubview(promptLabel)
        container.addSubview(ratingScaleView)
        container.addSubview(feedbackCommentView)
        header.addSubview(titleLabel)
        header.addSubview(closeButton)

        configureLayout()

        hideConstraint = feedbackCommentView.topAnchor.constraint(equalTo: bottomAnchor)
        feedbackCommentView.alpha = 0.0
        addConstraint(hideConstraint)

        layer.cornerRadius = 6.0
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }

    private func configureLayout() {
        [
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            header.topAnchor.constraint(equalTo: container.topAnchor),
            header.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 64),
            titleLabel.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: header.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
            closeButton.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 20),
            closeButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            promptLabel.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 16),
            promptLabel.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 24),
            promptLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -24),
            promptLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            ratingScaleView.topAnchor.constraint(equalTo: promptLabel.bottomAnchor),
            ratingScaleView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            feedbackCommentView.topAnchor.constraint(equalTo: ratingScaleView.bottomAnchor),
            feedbackCommentView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            feedbackCommentView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            feedbackCommentView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ].activate()
    }

    func expandIfNeeded() {
        guard !isExpanded else { return }
        UIView.animate(withDuration: 0.25,
                       animations: {
                        self.feedbackCommentView.alpha = 1.0
                        if self.constraints.contains(self.hideConstraint) {
                            self.removeConstraint(self.hideConstraint)
                        }
                        self.layoutIfNeeded()
                       }, completion: { _ in
                        self.isExpanded = true
                       })
    }

    @objc
    private func dismiss() {
        onDismiss()
    }

    private func didSubmit(comment: String?) {
        onSubmit(comment)
    }

    private enum SubviewsFactory {
        static var promptLabel: UILabel {
            let label = UILabel()
            label.numberOfLines = 0
            label.attributedText = LocalString._feedback_prompt.apply(style: .Default)
            return label
        }

        static var titleLabel: UILabel {
            let label = UILabel()
            label.attributedText = LocalString._your_feedback.apply(style: .DefaultStrong)
            return label
        }

        static var separator: UIView {
            let view = UIView()
            view.backgroundColor = ColorProvider.SeparatorNorm
            return view
        }

        static var closeButton: UIButton {
            let button = UIButton()
            button.setImage(Asset.actionSheetClose.image.sd_tintedImage(with: ColorProvider.IconNorm), for: .normal)
            return button
        }
    }
}

final class RatingScaleView: UIStackView {
    private let ratings: [Rating]
    private var onRatingSelection: ((Rating) -> Void)?

    init(ratings: [Rating], onRatingSelection: @escaping ((Rating) -> Void)) {
        self.ratings = ratings
        super.init(frame: .zero)
        self.onRatingSelection = { [weak self] rating in
            guard let self = self else {
                onRatingSelection(rating)
                return
            }
            for view in self.arrangedSubviews {
                if let rateView = view as? RateView {
                    rateView.rateButton.isSelected = false
                }
            }
            onRatingSelection(rating)
        }
        setup()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        axis = .horizontal
        spacing = 12
        for rating in ratings {
            guard let onRatingSelection = onRatingSelection else { continue }
            addArrangedSubview(RateView(rating: rating, onRatingSelection: onRatingSelection))
        }
    }
}

final class RateView: UIView {
    private let topLabel = UILabel()
    let rateButton = SubviewsFactory.rateButton
    private let bottomLabel = UILabel()
    private let rating: Rating
    private let onRatingSelection: ((Rating) -> Void)

    init(rating: Rating, onRatingSelection: @escaping ((Rating) -> Void)) {
        self.rating = rating
        self.onRatingSelection = onRatingSelection
        super.init(frame: .zero)
        topLabel.attributedText = rating.topText?.apply(style: .CaptionWeak)
        rateButton.setTitle(rating.associatedEmoji, for: .normal)
        bottomLabel.attributedText = rating.bottomText?.apply(style: .CaptionWeak)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("Please use init(frame:)")
    }

    private func setup() {
        addSubview(topLabel)
        addSubview(rateButton)
        addSubview(bottomLabel)
        rateButton.addTarget(self, action: #selector(didSelectRating), for: .touchUpInside)
        [
            topLabel.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            topLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            topLabel.heightAnchor.constraint(equalToConstant: 16),
            rateButton.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 8),
            rateButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            rateButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            rateButton.heightAnchor.constraint(equalToConstant: 56),
            rateButton.widthAnchor.constraint(equalToConstant: 56),
            bottomLabel.topAnchor.constraint(equalTo: rateButton.bottomAnchor, constant: 8),
            bottomLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            bottomLabel.heightAnchor.constraint(equalToConstant: 16),
            bottomLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -48)
        ].activate()
    }

    @objc
    private func didSelectRating() {
        onRatingSelection(rating)
        rateButton.isSelected = true
    }

    private enum SubviewsFactory {
        static var rateButton: UIButton {
            let button = UIButton()
            button.roundCorner(56 / 2)
            button.layer.borderWidth = 1
            button.layer.borderColor = ColorProvider.SeparatorNorm.cgColor
            button.setBackgroundImage(UIImage.color(ColorProvider.InteractionNorm), for: .highlighted)
            button.setBackgroundImage(UIImage.color(ColorProvider.InteractionNorm), for: .selected)
            return button
        }
    }
}

final class FeedbackCommentView: UIView, UITextViewDelegate {
    let commentTextView = SubviewsFactory.commentTextView
    private let submitButton = SubviewsFactory.submitButton
    private let placeholderText = LocalString._feedback_placeholder
    let onSubmit: ((String?) -> Void)

    init(onSubmit: @escaping ((String?) -> Void)) {
        self.onSubmit = onSubmit
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(commentTextView)
        addSubview(submitButton)
        [
            commentTextView.topAnchor.constraint(equalTo: topAnchor),
            commentTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            commentTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            commentTextView.heightAnchor.constraint(equalToConstant: 104),
            submitButton.topAnchor.constraint(equalTo: commentTextView.bottomAnchor, constant: 16),
            submitButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            submitButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            submitButton.heightAnchor.constraint(equalToConstant: 48),
            submitButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ].activate()
        addPlaceholder()
        commentTextView.delegate = self
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
    }

    @objc
    private func submitTapped() {
        var comment: String?
        if commentTextView.text != placeholderText {
            comment = commentTextView.text
        }
        onSubmit(comment)
    }

    private func addPlaceholder() {
        commentTextView.attributedText = placeholderText.apply(style: .DefaultHint)
    }

    private func removePlaceholder() {
        commentTextView.attributedText = .init()
        commentTextView.typingAttributes = .Default
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholderText {
            removePlaceholder()
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            addPlaceholder()
        }
    }

    private enum SubviewsFactory {
        static var commentTextView: UITextView {
            let textView = UITextView()
            textView.layer.borderWidth = 1
            textView.layer.borderColor = ColorProvider.InteractionNorm.cgColor
            textView.roundCorner(8)
            textView.backgroundColor = ColorProvider.BackgroundSecondary
            textView.typingAttributes = .Default
            return textView
        }

        static var submitButton: UIButton {
            let button = UIButton()
            button.setBackgroundImage(UIImage.color(ColorProvider.InteractionNorm), for: .normal)
            button.setAttributedTitle(LocalString._send_feedback.apply(style: .DefaultInverted), for: .normal)
            button.roundCorner(8)
            return button
        }
    }
}
