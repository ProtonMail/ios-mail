import ProtonCore_UIFoundations

class ConversationExpandedMessageCell: UITableViewCell {

    var prepareForReuseBlock: (() -> Void)?
    var messageId: String?
    let container = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        addSubviews()
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        messageId = nil
        prepareForReuseBlock?()
    }

    private func addSubviews() {
        contentView.addSubview(container)
    }

    private func setUpLayout() {
        [
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ].activate()
    }

}
