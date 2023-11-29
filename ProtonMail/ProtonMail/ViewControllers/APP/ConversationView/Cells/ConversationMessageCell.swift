import UIKit

class ConversationMessageCell: UITableViewCell {

    let customView = ConversationMessageView()
    var cellReuse: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        addSubviews()
        setUpLayout()
    }

    private func addSubviews() {
        contentView.addSubview(customView)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        customView.initialsLabel.isHidden = false
        customView.senderImageView.image = nil
        customView.attachmentImageView.isHidden = true
        cellReuse?()
    }

    private func setUpLayout() {
        [
            customView.topAnchor.constraint(equalTo: contentView.topAnchor),
            customView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            customView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ].activate()
    }

    required init?(coder: NSCoder) {
        nil
    }

}
