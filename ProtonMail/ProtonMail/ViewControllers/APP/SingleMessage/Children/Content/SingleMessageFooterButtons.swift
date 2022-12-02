import ProtonCore_Foundations
import ProtonCore_UIFoundations

class SingleMessageFooterButtons: UIView, AccessibleView {

    let stackView = SubviewsFactory.stackView
    let replyButton = SubviewsFactory.replyButton
    let replyAllButton = SubviewsFactory.replyAllButton
    let forwardButton = SubviewsFactory.forwardButton

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
        self.generateAccessibilityIdentifiers()
    }

    private func addSubviews() {
        addSubview(stackView)
        stackView.addArrangedSubview(replyButton)
        stackView.addArrangedSubview(replyAllButton)
        stackView.addArrangedSubview(forwardButton)
    }

    private func setUpLayout() {
        [
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12.0),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12.0),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12.0)
        ].activate()
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private enum SubviewsFactory {

    static var stackView: UIStackView {
        let view = UIStackView()
        view.distribution = .fillProportionally
        view.axis = .horizontal
        view.spacing = 8
        return view
    }

    static var replyButton: MailButton {
        let button = MailButton()
        button.icon = IconProvider.reply
        button.title = LocalString._general_reply_button
        return button
    }

    static var replyAllButton: MailButton {
        let button = MailButton()
        button.icon = IconProvider.replyAll
        button.title = LocalString._general_replyall_button
        return button
    }

    static var forwardButton: MailButton {
        let button = MailButton()
        button.icon = IconProvider.forward
        button.title = LocalString._general_forward_button
        return button
    }
}
