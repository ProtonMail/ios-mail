// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_UIFoundations
import UIKit

final class ToolbarCustomizeSpotlightView: UIView {
    private var dismissGesture: UITapGestureRecognizer?
    private let shadowView = SubviewsFactory.shadowView
    private let arrowView = SubviewsFactory.arrowView
    private let infoView = SubviewsFactory.infoView

    private let titleLabel = SubviewsFactory.titleLabel
    private let contentLabel = SubviewsFactory.contentLabel
    private let iconImageView = SubviewsFactory.iconImageView
    private let customizeButton = SubviewsFactory.customizeButton
    private let labelsStackView = SubviewsFactory.labelsStackView

    var navigateToToolbarCustomizeView: (() -> Void)?

    init() {
        super.init(frame: .zero)
        addSubviews()
        setupLayout()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addSubviews() {
        addSubview(shadowView)
        addSubview(infoView)
        addSubview(arrowView)

        labelsStackView.addArrangedSubview(titleLabel)
        labelsStackView.addArrangedSubview(contentLabel)
        infoView.addSubview(labelsStackView)
        infoView.addSubview(iconImageView)
        infoView.addSubview(customizeButton)
    }

    private func setupLayout() {
        shadowView.fillSuperview()

        [
            iconImageView.widthAnchor.constraint(equalToConstant: 48),
            iconImageView.heightAnchor.constraint(equalToConstant: 48),
            iconImageView.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: labelsStackView.centerYAnchor)
        ].activate()

        [
            labelsStackView.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 16),
            labelsStackView.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            labelsStackView.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -16),
            labelsStackView.bottomAnchor.constraint(equalTo: customizeButton.topAnchor, constant: -12)
        ].activate()

        [
            customizeButton.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            customizeButton.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -16),
            customizeButton.bottomAnchor.constraint(equalTo: infoView.bottomAnchor, constant: -16),
            customizeButton.heightAnchor.constraint(equalToConstant: 32)
        ].activate()
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
    }

    private func setupGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        addGestureRecognizer(gesture)
        self.dismissGesture = gesture

        customizeButton.addTarget(self, action: #selector(self.handleTap), for: .touchUpInside)
    }

    @objc
    private func dismiss() {
        removeFromSuperview()
    }

    @objc
    private func handleTap() {
        removeFromSuperview()
        navigateToToolbarCustomizeView?()
    }

    func presentOn(view: UIView, targetFrame: CGRect) {
        view.addSubview(self)

        self.frame = view.bounds
        let infoViewWidth = min(frame.width - 32.0, 360)

        let infoViewHeight = calculateInfoViewHeight(width: infoViewWidth)

        let path = UIBezierPath(rect: self.bounds)

        let rectanglePath = makeRectanglePath(targetFrame: targetFrame)
        path.append(rectanglePath)

        let infoViewRect = makeInfoViewRect(targetFrame: targetFrame, infoViewHeight: infoViewHeight)
        let infoViewPath = makeInfoViewPath(targetFrame: targetFrame, rect: infoViewRect)
        path.append(infoViewPath)

        let mask = CAShapeLayer()
        mask.path = path.cgPath
        mask.fillRule = .evenOdd

        infoView.frame = infoViewRect
        infoView.layer.cornerRadius = 16
        infoView.layer.masksToBounds = true

        self.shadowView.layer.mask = mask

        let arrowViewRect = makeArrowViewRect(targetFrame: targetFrame)
        let arrowViewPath = makeArrowPath()
        arrowView.frame = arrowViewRect

        let arrowMask = CAShapeLayer()
        arrowMask.path = arrowViewPath.cgPath

        arrowView.layer.mask = arrowMask
    }

    private func calculateInfoViewHeight(width: CGFloat) -> CGFloat {
        let iconWidth: CGFloat = 48.0
        let padding: CGFloat = 16.0
        let verticalPadding: CGFloat = 16.0
        let spacingBetweenIcon: CGFloat = 12.0
        let spacingBetweenCloseIcon: CGFloat = 9.0
        let buttonHeight: CGFloat = 32.0

        let labelWidth = width - iconWidth - padding * 2 -
            spacingBetweenIcon - spacingBetweenCloseIcon

        let titleLabelHeight = titleLabel
            .textRect(forBounds: CGRect(x: 0, y: 0, width: labelWidth, height: CGFloat.greatestFiniteMagnitude),
                      limitedToNumberOfLines: 0).height
        let contentLabelHeight = contentLabel
            .textRect(forBounds: CGRect(x: 0, y: 0, width: labelWidth, height: CGFloat.greatestFiniteMagnitude),
                      limitedToNumberOfLines: 0).height
        return titleLabelHeight + contentLabelHeight + verticalPadding * 3 + buttonHeight
    }

    private func makeRectanglePath(targetFrame: CGRect) -> UIBezierPath {
        return UIBezierPath(roundedRect: targetFrame, cornerRadius: 0)
    }

    private func makeArrowViewRect(targetFrame: CGRect) -> CGRect {
        let verticalSpacing: CGFloat = 19.0
        let x = targetFrame.midX - 10
        let y = targetFrame.minY - verticalSpacing
        let width = 24
        let height = 12
        return CGRect(x: Int(x), y: Int(y), width: width, height: height)
    }

    private func makeArrowPath() -> UIBezierPath {
        let path = UIBezierPath()
        let arrowLeftPoint = CGPoint(x: 0, y: 0)
        let arrowTopPoint = CGPoint(x: 12, y: 12)
        let arrowRightPoint = CGPoint(x: 24, y: 0)
        path.move(to: arrowLeftPoint)
        path.addLine(to: arrowTopPoint)
        path.addLine(to: arrowRightPoint)
        path.addLine(to: arrowLeftPoint)
        return path
    }

    private func makeInfoViewRect(targetFrame: CGRect, infoViewHeight: CGFloat) -> CGRect {
        let infoViewWidth = min(frame.width - 32.0, 360)
        let center = CGPoint(x: targetFrame.midX, y: targetFrame.midY)
        let verticalSpacing: CGFloat = 19.0
        let trailingSpacing: CGFloat = 16.0
        let y = center.y - (targetFrame.height / 2) - verticalSpacing
        let x = frame.width - infoViewWidth - trailingSpacing
        let height = max(102, infoViewHeight)
        return CGRect(x: x,
                      y: y - height,
                      width: infoViewWidth,
                      height: height)
    }

    private func makeInfoViewPath(targetFrame: CGRect, rect: CGRect) -> UIBezierPath {
        let center = CGPoint(x: targetFrame.midX, y: targetFrame.midY)
        let verticalSpacing: CGFloat = 19.0
        let y = center.y - (targetFrame.height / 2) - verticalSpacing
        // draw the round rect of the infoView
        let infoViewPath = UIBezierPath(roundedRect: rect,
                                        cornerRadius: 16)
        // draw the upper arrow
        let arrowLeftPoint = CGPoint(x: center.x - 10, y: y)
        let arrowTopPoint = CGPoint(x: center.x, y: y + 12)
        let arrowRightPoint = CGPoint(x: center.x + 10, y: y)
        infoViewPath.move(to: arrowLeftPoint)
        infoViewPath.addLine(to: arrowTopPoint)
        infoViewPath.addLine(to: arrowRightPoint)
        return infoViewPath
    }
}

private enum SubviewsFactory {
    static var shadowView: UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.BlenderNorm
        return view
    }

    static var arrowView: UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.BackgroundNorm
        return view
    }

    static var infoView: UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.BackgroundNorm
        return view
    }

    static var titleLabel: UILabel {
        let label = UILabel()
        label.text = LocalString._toolbar_customize_general_title
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = ColorProvider.TextNorm
        label.numberOfLines = 0
        return label
    }

    static var contentLabel: UILabel {
        let label = UILabel()
        label.text = LocalString._toolbar_spotlight_content
        label.font = .systemFont(ofSize: 14)
        label.textColor = ColorProvider.TextNorm
        label.numberOfLines = 0
        return label
    }

    static var iconImageView: UIImageView {
        let imageView = UIImageView(image: Asset.magicWand.image)
        return imageView
    }

    static var customizeButton: UIButton {
        let button = UIButton(frame: .zero)
        button.backgroundColor = ColorProvider.InteractionWeak
        button.setTitle(L11n.Toolbar.customizeSpotlight, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13)
        button.layer.cornerRadius = 8
        button.setTitleColor(ColorProvider.TextNorm, for: .normal)
        return button
    }

    static var labelsStackView: UIStackView {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 2
        return view
    }
}
