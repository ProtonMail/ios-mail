import ProtonCore_UIFoundations

class ConversationView: UIView {

    let tableView = SubviewsFactory.tableView
    let separator = SubviewsFactory.separator
    let toolBar = SubviewsFactory.toolBar

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColorManager.BackgroundSecondary
        addSubviews()
        setUpLayout()
    }

    private func addSubviews() {
        addSubview(tableView)
        addSubview(separator)
        addSubview(toolBar)
    }

    private func setUpLayout() {
        let bottomPadding = UIDevice.safeGuide.bottom
        let height = 56.0 + bottomPadding

        [
            toolBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            toolBar.heightAnchor.constraint(equalToConstant: height)
        ].activate()

        [
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: toolBar.topAnchor)
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
        messageId: String,
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
        tableView.backgroundColor = UIColorManager.BackgroundSecondary
        return tableView
    }

    static var separator: UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColorManager.Shade20
        return view
    }

    static var toolBar: PMToolBarView {
        let toolbar = PMToolBarView()
        return toolbar
    }
}
