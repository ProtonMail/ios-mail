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

        cellReuse?()
    }

    private func setUpLayout() {
        [
            // `defaultLow` is used so that the bottom of the cell is visible when the cell is constrained to limited height as a result of `MessageCellVisibility.partial`
            customView.topAnchor.constraint(equalTo: contentView.topAnchor).setPriority(as: .defaultLow),
            customView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            customView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ].activate()
    }

    required init?(coder: NSCoder) {
        nil
    }

}
