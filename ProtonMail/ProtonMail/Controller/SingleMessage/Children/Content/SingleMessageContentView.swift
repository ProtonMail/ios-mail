import ProtonCore_UIFoundations
import UIKit

class SingleMessageContentView: UIView {

    let bannerContainer = UIView()
    let messageBodyContainer = UIView()
    let messageHeaderContainer = HeaderContainerView()
    let attachmentContainer = UIView()
    let stackView = UIStackView.stackView(axis: .vertical)
    let separator = SubviewsFactory.smallSeparatorView
    let footerButtons = SingleMessageFooterButtons()

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
    }

    private func addSubviews() {
        addSubview(stackView)
        stackView.addArrangedSubview(messageHeaderContainer)
        stackView.addArrangedSubview(attachmentContainer)
        stackView.addArrangedSubview(bannerContainer)
        stackView.addArrangedSubview(messageBodyContainer)
        stackView.addArrangedSubview(footerButtons)

        footerButtons.setContentHuggingPriority(.defaultLow, for: .horizontal)

        messageHeaderContainer.addSubview(separator)
    }

    private func setUpLayout() {
        [
            stackView.topAnchor.constraint(equalTo: topAnchor),
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
        view.backgroundColor = UIColorManager.Shade20
        return view
    }

}
