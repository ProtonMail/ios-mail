import UIKit
import ProtonCore_UIFoundations

class ConversationExpandedMessageView: UIView {

    var topArrowTapAction: (() -> Void)?

    let contentContainer = SubviewsFactory.container
    let topArrowControl = SubviewsFactory.topArrowControl

    init() {
        super.init(frame: .zero)
        backgroundColor = ColorProvider.BackgroundDeep
        addSubviews()
        setUpLayout()
        setUpActions()
    }

    private func addSubviews() {
        addSubview(contentContainer)
        addSubview(topArrowControl)
    }

    private func setUpLayout() {
        [
            topArrowControl.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            topArrowControl.leadingAnchor.constraint(equalTo: leadingAnchor),
            topArrowControl.trailingAnchor.constraint(equalTo: trailingAnchor),
            topArrowControl.heightAnchor.constraint(equalToConstant: 18)
        ].activate()

        [
            contentContainer.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            contentContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ].activate()
    }

    private func setUpActions() {
        topArrowControl.isAccessibilityElement = true
        topArrowControl.accessibilityLabel = LocalString.collalse_message_title_in_converation_view
        topArrowControl.accessibilityTraits = .button
        topArrowControl.addTarget(self, action: #selector(topArrowTap), for: .touchUpInside)
    }

    @objc private func topArrowTap() {
        topArrowTapAction?()
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private enum SubviewsFactory {

    static var topArrowControl: UIControl {
        let control = UIControl(frame: .zero)
        control.backgroundColor = .clear
        return control
    }

    static var container: UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = ColorProvider.BackgroundNorm
        view.layer.cornerRadius = 12
        view.layer.apply(shadow: .custom(y: 2, blur: 8))
        return view
    }

}
