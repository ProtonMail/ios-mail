import UIKit

class ConversationViewHeaderCell: UITableViewCell {

    let customView = ConversationViewHeaderView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setUpSubviews()
        setUpLayout()
    }

    func setUpSubviews() {
        contentView.addSubview(customView)
    }

    func setUpLayout() {
        [
            customView.topAnchor.constraint(equalTo: contentView.topAnchor),
            customView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            customView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2)
        ].activate()
    }

    required init?(coder: NSCoder) {
        nil
    }

}
