import ProtonCore_UIFoundations

class ConversationView: UIView {

    let tableView = SubviewsFactory.tableView
    let separator = SubviewsFactory.separator

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColorManager.BackgroundSecondary
        addSubviews()
        setUpLayout()
    }

    private func addSubviews() {
        addSubview(tableView)
        addSubview(separator)
    }

    private func setUpLayout() {
        [
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
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

}

private enum SubviewsFactory {

    static var tableView: UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        return tableView
    }

    static var separator: UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColorManager.Shade20
        return view
    }

}
