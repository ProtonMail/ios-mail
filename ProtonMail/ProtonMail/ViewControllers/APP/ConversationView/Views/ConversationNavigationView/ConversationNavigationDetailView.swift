import UIKit

class ConversationNavigationDetailView: UIView {

    let stackView = UIStackView.stackView(axis: .vertical, alignment: .center, spacing: 0)
    let topLabel = UILabel(frame: .zero)
    let bottomLabel = UILabel(frame: .zero)

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(rotate(notification:)),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    private func addSubviews() {
        addSubview(stackView)
        stackView.addArrangedSubview(topLabel)
        stackView.addArrangedSubview(bottomLabel)
        updateTopLabelVisibility()
    }

    private func setUpLayout() {
        [
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ].activate()
    }

    required init?(coder: NSCoder) {
        nil
    }

    @objc
    func rotate(notification: Notification) {
        updateTopLabelVisibility()
    }

    private func updateTopLabelVisibility() {
        topLabel.isHidden = UIDevice.current.orientation.isLandscape
    }
}
