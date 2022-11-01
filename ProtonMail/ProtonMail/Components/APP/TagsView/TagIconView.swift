import UIKit

class TagIconView: UIView {

    let imageView = UIImageView()
    let tagLabel = UILabel()

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
        setUpViews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        setCornerRadius(radius: frame.height / 2)
    }

    private func addSubviews() {
        addSubview(imageView)
        addSubview(tagLabel)
    }

    private func setUpLayout() {
        [
            imageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 3),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -3),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            imageView.trailingAnchor.constraint(equalTo: tagLabel.leadingAnchor, constant: -2),
            imageView.widthAnchor.constraint(equalToConstant: 12),
            imageView.heightAnchor.constraint(equalToConstant: 12)
        ].activate()

        [
            tagLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 2),
            tagLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -2),
            tagLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4)
        ].activate()
    }

    private func setUpViews() {
        imageView.contentMode = .scaleAspectFit
    }

    required init?(coder: NSCoder) {
        nil
    }

}
