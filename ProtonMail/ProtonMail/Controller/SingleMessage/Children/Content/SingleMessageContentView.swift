import ProtonCore_UIFoundations
import UIKit

class SingleMessageContentView: UIView {

    let replyState: HeaderContainerView.ReplyState
    let bannerContainer = UIView()
    let messageBodyContainer = UIView()
    let showHideHistoryButtonContainer = SingleMessageContentViewHistoryButtonContainer()
    lazy var messageHeaderContainer = HeaderContainerView(replyState: replyState)
    let attachmentContainer = UIView()
    let stackView = UIStackView.stackView(axis: .vertical)
    let separator = SubviewsFactory.smallSeparatorView
    let footerButtons = SingleMessageFooterButtons()

    init(replyState: HeaderContainerView.ReplyState) {
        self.replyState = replyState
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
        accessibilityElements = [messageHeaderContainer, attachmentContainer, bannerContainer, messageBodyContainer, footerButtons]
    }

    private func addSubviews() {
        addSubview(stackView)
        stackView.addArrangedSubview(messageHeaderContainer)
        stackView.addArrangedSubview(attachmentContainer)
        stackView.addArrangedSubview(bannerContainer)
        stackView.addArrangedSubview(messageBodyContainer)
        stackView.addArrangedSubview(showHideHistoryButtonContainer)
        stackView.addArrangedSubview(footerButtons)

        footerButtons.setContentHuggingPriority(.defaultLow, for: .horizontal)

        messageHeaderContainer.addSubview(separator)
    }

    private func setUpLayout() {
        [
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ].activate()

        [
            separator.leadingAnchor.constraint(equalTo: messageHeaderContainer.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: messageHeaderContainer.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: messageHeaderContainer.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ].activate()
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private enum SubviewsFactory {

    static var smallSeparatorView: UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = ColorProvider.Shade20
        return view
    }

}
