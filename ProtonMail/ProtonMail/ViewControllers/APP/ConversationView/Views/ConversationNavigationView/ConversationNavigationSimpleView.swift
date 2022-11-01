import UIKit

class ConversationNavigationSimpleView: UIView {

    let titleLabel = UILabel(frame: .zero)

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
    }

    private func addSubviews() {
        addSubview(titleLabel)
    }

    private func setUpLayout() {
        [
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ].activate()
    }

    required init?(coder: NSCoder) {
        nil
    }

}
