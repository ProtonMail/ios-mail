import ProtonCoreUIFoundations
import UIKit

class SingleMessageContentView: UIView {

    let replyState: HeaderContainerView.ReplyState
    let bannerContainer = UIView()
    let messageBodyContainer = UIView()
    let editScheduleSendBannerContainer = UIView()
    let showHideHistoryButtonContainer = SingleMessageContentViewHistoryButtonContainer()
    lazy var messageHeaderContainer = HeaderContainerView(replyState: replyState)
    let attachmentContainer = UIView()
    let stackView = UIStackView.stackView(axis: .vertical)
    let footerButtons = SingleMessageFooterButtons()

    init(replyState: HeaderContainerView.ReplyState) {
        self.replyState = replyState
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true
        addSubviews()
        setUpLayout()
        accessibilityElements = [
            messageHeaderContainer,
            editScheduleSendBannerContainer,
            attachmentContainer,
            bannerContainer,
            messageBodyContainer,
            footerButtons
        ]
    }

    private func addSubviews() {
        addSubview(stackView)
        stackView.addArrangedSubview(messageHeaderContainer)
        stackView.addArrangedSubview(editScheduleSendBannerContainer)
        stackView.addArrangedSubview(attachmentContainer)
        stackView.addArrangedSubview(bannerContainer)
        stackView.addArrangedSubview(messageBodyContainer)
        stackView.addArrangedSubview(showHideHistoryButtonContainer)
        stackView.addArrangedSubview(footerButtons)

        footerButtons.setContentHuggingPriority(.defaultLow, for: .horizontal)
        footerButtons.setContentHuggingPriority(.required, for: .vertical)
    }

    private func setUpLayout() {
        [
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor).setPriority(as: .defaultHigh)
        ].activate()

        [
            attachmentContainer.heightAnchor.constraint(equalToConstant: 0).setPriority(as: .defaultLow),
            bannerContainer.heightAnchor.constraint(equalToConstant: 0).setPriority(as: .defaultLow)
        ].activate()
    }

    func preferredContentSizeChanged() {
        footerButtons.replyButton.titleLabel.font = .adjustedFont(forTextStyle: .footnote)
        footerButtons.replyAllButton.titleLabel.font = .adjustedFont(forTextStyle: .footnote)
        footerButtons.forwardButton.titleLabel.font = .adjustedFont(forTextStyle: .footnote)
    }

    required init?(coder: NSCoder) {
        nil
    }

}
