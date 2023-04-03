import ProtonCore_UIFoundations
import UIKit

class ConversationMessageView: BaseMessageView {

    var tapAction: (() -> Void)?

    let cellControl: UIControl = {
        let control = UIControl(frame: .zero)
        control.clipsToBounds = true
        return control
    }()

    let container = SubviewsFactory.container

    let contentStackView = UIStackView.stackView(axis: .horizontal, alignment: .center, spacing: 4)
    let initialsContainer = SubviewsFactory.initialsContainer
    let initialsLabel = UILabel.initialsLabel
    let senderImageView = SubviewsFactory.senderImageView
    let initialsIcon = SubviewsFactory.draftImageView
    let initialsView = UIView()
    let scheduledIcon = SubviewsFactory.scheduledIconImageView


    let sentImageView = SubviewsFactory.sentImageView
    let originImageView = SubviewsFactory.originImageView

    let spacer = UIView()

    let expirationView = SubviewsFactory.expirationView

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
        setUpActions()
    }

    private func addSubviews() {
        addSubview(cellControl)
        cellControl.addSubview(container)
        container.addSubview(contentStackView)

        initialsView.addSubview(initialsContainer)
        initialsView.addSubview(initialsIcon)
        initialsView.addSubview(scheduledIcon)
        initialsContainer.addSubview(initialsLabel)
        initialsContainer.addSubview(senderImageView)

        contentStackView.addArrangedSubview(initialsView)
        contentStackView.addArrangedSubview(replyImageView)
        contentStackView.addArrangedSubview(replyAllImageView)
        contentStackView.addArrangedSubview(forwardImageView)
        contentStackView.addArrangedSubview(sendersStackView)
        contentStackView.addArrangedSubview(expirationView)
        contentStackView.addArrangedSubview(tagsView)
        contentStackView.addArrangedSubview(spacer)
        contentStackView.addArrangedSubview(attachmentImageView)
        contentStackView.addArrangedSubview(starImageView)
        contentStackView.addArrangedSubview(sentImageView)
        contentStackView.addArrangedSubview(originImageView)
        contentStackView.addArrangedSubview(timeLabel)
    }

    private func setUpLayout() {
        [
            originImageView.widthAnchor.constraint(equalToConstant: 16),
            originImageView.heightAnchor.constraint(equalToConstant: 16),
            sentImageView.widthAnchor.constraint(equalToConstant: 16),
            sentImageView.heightAnchor.constraint(equalToConstant: 16),
            replyAllImageView.widthAnchor.constraint(equalToConstant: 16),
            replyAllImageView.heightAnchor.constraint(equalToConstant: 16),
            replyImageView.widthAnchor.constraint(equalToConstant: 16),
            replyImageView.heightAnchor.constraint(equalToConstant: 16),
            forwardImageView.widthAnchor.constraint(equalToConstant: 16),
            forwardImageView.heightAnchor.constraint(equalToConstant: 16),
            starImageView.widthAnchor.constraint(equalToConstant: 16),
            starImageView.heightAnchor.constraint(equalToConstant: 16),
            attachmentImageView.widthAnchor.constraint(equalToConstant: 16),
            attachmentImageView.heightAnchor.constraint(equalToConstant: 16)
        ].activate()

        [
            cellControl.topAnchor.constraint(equalTo: topAnchor),
            cellControl.leadingAnchor.constraint(equalTo: leadingAnchor),
            cellControl.trailingAnchor.constraint(equalTo: trailingAnchor),
            cellControl.bottomAnchor.constraint(equalTo: bottomAnchor)
        ].activate()

        [
            container.topAnchor.constraint(equalTo: cellControl.topAnchor, constant: 4).setPriority(as: .defaultHigh),
            container.leadingAnchor.constraint(equalTo: cellControl.leadingAnchor, constant: 8),
            container.trailingAnchor.constraint(equalTo: cellControl.trailingAnchor, constant: -8),
            container.bottomAnchor.constraint(equalTo: cellControl.bottomAnchor, constant: -4)
        ].activate()

        [
            contentStackView.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            contentStackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            contentStackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            contentStackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ].activate()

        [
            initialsContainer.centerXAnchor.constraint(equalTo: initialsView.centerXAnchor),
            initialsContainer.centerYAnchor.constraint(equalTo: initialsView.centerYAnchor),
            initialsContainer.heightAnchor.constraint(equalToConstant: 28).setPriority(as: .defaultHigh),
            initialsContainer.widthAnchor.constraint(equalToConstant: 28)
        ].activate()

        [
            initialsLabel.centerYAnchor.constraint(equalTo: initialsContainer.centerYAnchor),
            initialsLabel.leadingAnchor.constraint(equalTo: initialsContainer.leadingAnchor, constant: 2),
            initialsLabel.trailingAnchor.constraint(equalTo: initialsContainer.trailingAnchor, constant: -2)
        ].activate()
        senderImageView.fillSuperview()

        [
            initialsIcon.centerXAnchor.constraint(equalTo: initialsView.centerXAnchor),
            initialsIcon.centerYAnchor.constraint(equalTo: initialsView.centerYAnchor),
            initialsIcon.widthAnchor.constraint(equalToConstant: 16),
            initialsIcon.heightAnchor.constraint(equalToConstant: 16)
        ].activate()

        [
            scheduledIcon.centerXAnchor.constraint(equalTo: initialsView.centerXAnchor),
            scheduledIcon.centerYAnchor.constraint(equalTo: initialsView.centerYAnchor),
            scheduledIcon.widthAnchor.constraint(equalToConstant: 16),
            scheduledIcon.heightAnchor.constraint(equalToConstant: 16)
        ].activate()

        [
            initialsView.heightAnchor.constraint(equalToConstant: 28).setPriority(as: .defaultHigh),
            initialsView.widthAnchor.constraint(equalToConstant: 28)
        ].activate()

        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        [
            tagsView.widthAnchor.constraint(greaterThanOrEqualTo: tagsView.heightAnchor)
        ].activate()
        tagsView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        [
            originImageView.widthAnchor.constraint(equalToConstant: 16),
            originImageView.heightAnchor.constraint(equalToConstant: 16)
        ].activate()
    }

    private func setUpActions() {
        cellControl.addTarget(self, action: #selector(cellTapped), for: .touchUpInside)
    }

    @objc private func cellTapped() {
        tapAction?()
    }

    required init?(coder: NSCoder) {
        nil
    }
}

private extension ConversationMessageView {
    class SubviewsFactory: BaseMessageView.SubviewsFactory {
        static var originImageView: UIImageView {
            let imageView = UIImageView(frame: .zero)
            imageView.contentMode = .scaleAspectFit
            imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
            return imageView
        }

        static var container: UIView {
            let view = UIView()
            view.backgroundColor = ColorProvider.BackgroundNorm
            view.layer.cornerRadius = 6
            view.isUserInteractionEnabled = false
            return view
        }

        static var initialsContainer: UIView {
            let view = UIView()
            view.backgroundColor = ColorProvider.InteractionWeak
            view.layer.cornerRadius = 8
            view.isUserInteractionEnabled = false
            return view
        }

        static var expirationView: TagIconView {
            let tagView = TagIconView()
            tagView.imageView.image = IconProvider.hourglass
            tagView.imageView.tintColor = ColorProvider.IconNorm
            tagView.backgroundColor = ColorProvider.InteractionWeak
            return tagView
        }

        static var sentImageView: UIImageView {
            .make(icon: \.paperPlane, tintColor: \.IconWeak)
        }

        static var scheduledIconImageView: UIImageView {
            .make(icon: \.clock, tintColor: \.IconNorm)
        }

        static var senderImageView: UIImageView {
            let view = UIImageView(image: nil)
            view.contentMode = .scaleAspectFit
            view.layer.cornerRadius = 8
            view.layer.masksToBounds = true
            return view
        }
    }
}
