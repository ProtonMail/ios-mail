import ProtonCore_UIFoundations
import UIKit

class ConversationViewHeaderView: UIView {

    let titleTextView = SubviewsFactory.titleTextView
    let separator = SubviewsFactory.separator
    let topView = SubviewsFactory.topView

    var topSpace: CGFloat = 0 {
        didSet { topConstraint?.constant = topSpace }
    }

    private var topConstraint: NSLayoutConstraint?

    init() {
        super.init(frame: .zero)
        backgroundColor = ColorProvider.BackgroundNorm
        addSubviews()
        setUpLayout()
    }

    private func addSubviews() {
        addSubview(titleTextView)
        addSubview(separator)
        addSubview(topView)
    }

    private func setUpLayout() {
        topConstraint = topView.topAnchor.constraint(equalTo: topAnchor)
        topConstraint?.isActive = true

        [
            topView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topView.trailingAnchor.constraint(equalTo: trailingAnchor),
            topView.bottomAnchor.constraint(equalTo: topAnchor)
        ].activate()

        [
            titleTextView.topAnchor.constraint(equalTo: topAnchor),
            titleTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            titleTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            titleTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
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

    static var titleTextView: UITextView {
        let view = UITextView(frame: .zero)
        view.isEditable = false
        view.isScrollEnabled = false
        view.backgroundColor = ColorProvider.BackgroundNorm
        return view
    }

    static var separator: UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = ColorProvider.Shade20
        return view
    }

    static var topView: UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.BackgroundNorm
        return view
    }

}
