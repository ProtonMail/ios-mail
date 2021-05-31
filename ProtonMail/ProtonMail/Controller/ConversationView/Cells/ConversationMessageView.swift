import ProtonCore_UIFoundations
import UIKit

class ConversationMessageView: UIView {

    let container = SubviewsFactory.container

    let contentStackView = UIStackView.stackView(axis: .horizontal, alignment: .center, spacing: 4)
    let initialsLabel = UILabel.initialsLabel
    let initialsIcon = SubviewsFactory.draftIconImageView
    let initialsView = UIView()

    let replyImageView = SubviewsFactory.replyImageView
    let replyAllImageView = SubviewsFactory.replyAllImageView
    let forwardImageView = SubviewsFactory.forwardImageView

    let senderLabel = UILabel()
    let attachmentImageView = SubviewsFactory.attachmentImageView
    let starImageView = SubviewsFactory.starImageView

    let originImageView = SubviewsFactory.originImageView

    let timeLabel = UILabel()

    let spacer = UIView()

    let expirationView = SubviewsFactory.expirationView
    let tagsView = ConversationMessageViewTags()

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
    }

    private func addSubviews() {
        addSubview(container)
        container.addSubview(contentStackView)

        initialsView.addSubview(initialsLabel)
        initialsView.addSubview(initialsIcon)

        contentStackView.addArrangedSubview(initialsView)
        contentStackView.addArrangedSubview(replyImageView)
        contentStackView.addArrangedSubview(replyAllImageView)
        contentStackView.addArrangedSubview(forwardImageView)
        contentStackView.addArrangedSubview(StackViewContainer(view: senderLabel, bottom: -3))
        contentStackView.addArrangedSubview(expirationView)
        contentStackView.addArrangedSubview(tagsView)
        contentStackView.addArrangedSubview(spacer)
        contentStackView.addArrangedSubview(attachmentImageView)
        contentStackView.addArrangedSubview(starImageView)
        contentStackView.addArrangedSubview(originImageView)
        contentStackView.addArrangedSubview(timeLabel)
    }

    private func setUpLayout() {
        [
            container.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2)
        ].activate()

        [
            contentStackView.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            contentStackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            contentStackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            contentStackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ].activate()

        [
            initialsLabel.topAnchor.constraint(greaterThanOrEqualTo: initialsView.topAnchor),
            initialsLabel.leadingAnchor.constraint(greaterThanOrEqualTo: initialsView.leadingAnchor),
            initialsLabel.trailingAnchor.constraint(lessThanOrEqualTo: initialsView.trailingAnchor),
            initialsLabel.bottomAnchor.constraint(lessThanOrEqualTo: initialsView.bottomAnchor),
            initialsLabel.heightAnchor.constraint(equalToConstant: 28),
            initialsLabel.widthAnchor.constraint(equalToConstant: 28)
        ].activate()

        [
            initialsIcon.centerXAnchor.constraint(equalTo: initialsView.centerXAnchor),
            initialsIcon.centerYAnchor.constraint(equalTo: initialsView.centerYAnchor)
        ].activate()

        [
            initialsView.heightAnchor.constraint(equalToConstant: 28),
            initialsView.widthAnchor.constraint(equalToConstant: 28)
        ].activate()

        contentStackView.setCustomSpacing(4, after: initialsView)

        senderLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        senderLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private enum SubviewsFactory {

    static var attachmentImageView: UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.image = Asset.mailAttachment.image
        imageView.tintColor = UIColorManager.IconWeak
        return imageView
    }

    static var starImageView: UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.image = Asset.mailStar.image
        return imageView
    }

    static var originImageView: UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }

    static var draftIconImageView: UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.image = Asset.mailDraftIcon.image
        imageView.tintColor = UIColorManager.IconNorm
        imageView.contentMode = .scaleAspectFit
        return imageView
    }

    static var container: UIView {
        let view = UIView()
        view.backgroundColor = UIColorManager.BackgroundNorm
        view.layer.cornerRadius = 6
        view.layer.apply(shadow: .custom(y: 1))
        return view
    }

    static var expirationView: TagView {
        let tagView = TagView()
        tagView.imageView.image = Asset.iconHourglass.image
        tagView.backgroundColor = UIColorManager.InteractionWeak
        return tagView
    }

    static var forwardImageView: UIImageView {
        imageView(Asset.mailForward.image)
    }

    static var replyImageView: UIImageView {
        imageView(Asset.mailReply.image)
    }

    static var replyAllImageView: UIImageView {
        imageView(Asset.mailReplyAll.image)
    }

    private static func imageView(_ image: UIImage) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        return imageView
    }

}
