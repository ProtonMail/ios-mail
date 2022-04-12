import UIKit

class ConversationMessageViewTags: UIView {

    var tags: [UIColor] = [] {
        didSet {
            reloadSubviews()
        }
    }

    override var intrinsicContentSize: CGSize {
        .init(width: subviews.map { $0.frame.maxX }.max() ?? 0, height: subviews.map { $0.frame.maxY }.max() ?? 0)
    }

    init() {
        super.init(frame: .zero)
    }

    private func reloadSubviews() {
        subviews.forEach { $0.removeFromSuperview() }
        setUpSubviews()
        invalidateIntrinsicContentSize()
    }

    private func setUpSubviews() {
        tags.enumerated().prefix(3).map { index, tagColor -> UIView in
            let circle = makeCircle(.init(x: index * 9, y: 0, width: 16, height: 16))
            circle.backgroundColor = tagColor
            return circle
        }.forEach {
            addSubview($0)
        }

        guard tags.count > 3 else { return }
        addLabel()
    }

    private func addLabel() {
        let maxX = subviews.map { $0.frame.maxX }.max() ?? 0
        let label = UILabel(frame: .init(x: maxX, y: 0, width: 0, height: 0))
        label.attributedText = "+\(tags.count - 3)".apply(style: FontManager.OverlineRegularTextWeak)
        label.sizeToFit()
        let centerY = subviews.first?.center.y ?? 0
        label.center = .init(x: label.center.x, y: centerY)
        addSubview(label)
    }

    private func makeCircle(_ frame: CGRect) -> UIView {
        let view = UIView()
        view.frame = frame

        let maskLayer = CAShapeLayer()
        maskLayer.frame = view.bounds
        maskLayer.path = UIBezierPath(roundedRect: view.bounds, cornerRadius: view.frame.height / 2).cgPath

        view.layer.mask = maskLayer

        let borderLayer = CAShapeLayer()
        borderLayer.path = maskLayer.path
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.lineWidth = 5
        borderLayer.frame = view.bounds

        view.layer.addSublayer(borderLayer)

        return view
    }

    required init?(coder: NSCoder) {
        nil
    }

}
