class TextControl: UIControl {

    var tap: (() -> Void)?

    let label = UILabel(frame: .zero)

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
        setUpAction()
    }

    private func addSubviews() {
        addSubview(label)
    }

    private func setUpLayout() {
        [
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ].activate()
    }

    private func setUpAction() {
        self.addTarget(self, action: #selector(tapAction), for: .touchUpInside)
    }

    @objc
    private func tapAction() {
        tap?()
    }

    required init?(coder: NSCoder) {
        nil
    }

}
