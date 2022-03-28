import ProtonCore_UIFoundations

class ConversationExpandedMessageCell: UITableViewCell {

    var prepareForReuseBlock: (() -> Void)?
    var messageId: String?
    let container = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = ColorProvider.BackgroundSecondary
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
        // To remove contrast warning, set priority to 999
        [
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8).setPriority(as: .init(rawValue: 999)),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).setPriority(as: .init(rawValue: 999))
        ].activate()
    }

}
