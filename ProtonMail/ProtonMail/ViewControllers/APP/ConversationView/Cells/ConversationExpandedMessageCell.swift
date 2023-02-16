import ProtonCore_UIFoundations

class ConversationExpandedMessageCell: UITableViewCell {

    var prepareForReuseBlock: (() -> Void)?
    var messageId: MessageID?
    let container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = ColorProvider.BackgroundDeep
        addSubviews()
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        container.subviews.forEach { $0.removeFromSuperview() }
        messageId = nil
        prepareForReuseBlock?()
    }

    private func addSubviews() {
        contentView.addSubview(container)
    }

    private func setUpLayout() {
        [
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8)
            // must be lower than `required`, calling `systemLayoutSizeFitting` sets `contentView.width` to 0 and it causes a constraint conflict
                .setPriority(as: .init(rawValue: 999)),
            container.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ].activate()
    }

}
