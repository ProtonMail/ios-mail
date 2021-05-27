import ProtonCore_UIFoundations

class ConversationViewHeaderView: UIView {

    let titleLabel = SubviewsFactory.titleLabel
    let separator = SubviewsFactory.separator

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColorManager.BackgroundNorm
        addSubviews()
        setUpLayout()
    }

    private func addSubviews() {
        addSubview(titleLabel)
        addSubview(separator)
    }

    private func setUpLayout() {
        [
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ].activate()

        [
            separator.heightAnchor.constraint(equalToConstant: 1),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor)
        ].activate()
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private enum SubviewsFactory {

    static var titleLabel: UILabel {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        return label
    }

    static var separator: UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColorManager.Shade20
        return view
    }

}
