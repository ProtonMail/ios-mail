import UIKit
import ProtonCore_UIFoundations

class SingleMessageFooterButtons: UIView {

    let moreButton = SubviewsFactory.moreButton
    let replyButton = SubviewsFactory.replyButton

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
    }

    private func addSubviews() {
        addSubview(moreButton)
        addSubview(replyButton)
    }

    private func setUpLayout() {
        [
            moreButton.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            moreButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            moreButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            moreButton.leadingAnchor.constraint(equalTo: replyButton.trailingAnchor, constant: 10),
            moreButton.heightAnchor.constraint(equalToConstant: 24),
            moreButton.widthAnchor.constraint(equalToConstant: 24)
        ].activate()

        [
            replyButton.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            replyButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            replyButton.heightAnchor.constraint(equalToConstant: 24),
            replyButton.widthAnchor.constraint(equalToConstant: 24)
        ].activate()
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private enum SubviewsFactory {

    static var moreButton: UIButton {
        let button = UIButton(image: Asset.dotsButtonIcon.image)
        button.tintColor = UIColorManager.InteractionNorm
        return button
    }

    static var replyButton: UIButton {
        let button = UIButton(image: Asset.replyButtonIcon.image)
        button.tintColor = UIColorManager.InteractionNorm
        return button
    }

}
