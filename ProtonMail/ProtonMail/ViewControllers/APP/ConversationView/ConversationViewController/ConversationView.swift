import ProtonCore_UIFoundations

class ConversationView: UIView {

    let tableView = SubviewsFactory.tableView
    let separator = SubviewsFactory.separator
    let toolBar = SubviewsFactory.toolBar

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        return stackView
    }()

    // needed to cover the space between the toolBar and the edge of the screen
    private let spacer: UIView = {
        let spacer = UIView()
        spacer.backgroundColor = ColorProvider.BackgroundNorm
        return spacer
    }()

    init() {
        super.init(frame: .zero)
        backgroundColor = ColorProvider.BackgroundSecondary
        addSubviews()
        setUpLayout()
        accessibilityElements = [tableView, toolBar]
    }

    private func addSubviews() {
        addSubview(separator)
        stackView.addArrangedSubview(tableView)
        stackView.addArrangedSubview(toolBar)
        stackView.addArrangedSubview(spacer)
        addSubview(stackView)
    }

    private func setUpLayout() {
        let bottomPadding = UIDevice.safeGuide.bottom

        [
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ].activate()

        [
            spacer.heightAnchor.constraint(equalToConstant: bottomPadding)
        ].activate()

        [
            separator.heightAnchor.constraint(equalToConstant: 1),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.topAnchor.constraint(equalTo: topAnchor)
        ].activate()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func showNewMessageFloatyView(
        messageId: MessageID,
        didHide: @escaping () -> Void
    ) -> ConversationNewMessageFloatyView {
        let safeBottom = superview?.safeGuide.bottom ?? 0.0
        // make sure bottom always on the top of safeArea
        let bottom = safeBottom + 64.0

        let view = ConversationNewMessageFloatyView(didHide: didHide)
        addSubview(view)
        [
            view.heightAnchor.constraint(equalToConstant: 48.0),
            view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1 * bottom),
            view.centerXAnchor.constraint(equalTo: centerXAnchor)
        ].activate()
        return view
    }
}

private enum SubviewsFactory {

    static var tableView: UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = ColorProvider.BackgroundSecondary
        return tableView
    }

    static var separator: UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = ColorProvider.Shade20
        return view
    }

    static var toolBar: PMToolBarView {
        let toolbar = PMToolBarView()
        return toolbar
    }
}
