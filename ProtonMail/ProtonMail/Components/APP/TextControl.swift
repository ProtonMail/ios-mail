import ProtonCore_UIFoundations
import UIKit

final class TextControl: UIControl {

    var tap: (() -> Void)?

    let label = SubviewsFactory.textLabel

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
        label.setContentCompressionResistancePriority(.required, for: .vertical)
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

private enum SubviewsFactory {
    static var textLabel: UILabel {
        let label = UILabel(frame: .zero)
        label.textAlignment = .right
        label.set(text: nil,
                  preferredFont: .footnote,
                  textColor: ColorProvider.InteractionNorm)
        return label
    }
}
