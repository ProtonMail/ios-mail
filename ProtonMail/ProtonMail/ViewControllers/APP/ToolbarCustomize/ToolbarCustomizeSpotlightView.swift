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

final class ToolbarCustomizeSpotlightView: TouchPassingThroughTargetView {
    private var dismissGesture: UITapGestureRecognizer?
    private let shadowView = SubviewsFactory.shadowView
    private let infoView = SubviewsFactory.infoView
    private let circleRadius: CGFloat = 25.0

    private let titleLabel = SubviewsFactory.titleLabel
    private let contentLabel = SubviewsFactory.contentLabel
    private let iconImageView = SubviewsFactory.iconImageView
    private let closeImageView = SubviewsFactory.closeImageView

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

        infoView.addSubview(titleLabel)
        infoView.addSubview(contentLabel)
        infoView.addSubview(iconImageView)
        infoView.addSubview(closeImageView)
    }

    private func setupLayout() {
        shadowView.fillSuperview()

        [
            iconImageView.widthAnchor.constraint(equalToConstant: 48),
            iconImageView.heightAnchor.constraint(equalToConstant: 48),
            iconImageView.centerYAnchor.constraint(equalTo: infoView.centerYAnchor),
            iconImageView.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16)
        ].activate()

        [
            closeImageView.centerYAnchor.constraint(equalTo: infoView.centerYAnchor),
            closeImageView.heightAnchor.constraint(equalToConstant: 24),
            closeImageView.widthAnchor.constraint(equalToConstant: 24),
            closeImageView.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -16)
        ].activate()

        [
            titleLabel.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: closeImageView.leadingAnchor, constant: -9),
            contentLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            contentLabel.bottomAnchor.constraint(equalTo: infoView.bottomAnchor, constant: -16)
        ].activate()
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
    }

    private func setupGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        addGestureRecognizer(gesture)
        self.dismissGesture = gesture
    }

    @objc
    private func dismiss() {
        removeFromSuperview()
    }

    func presentOn(view: UIView, targetFrame: CGRect) {
        self.passThroughFrame = targetFrame
        view.addSubview(self)
        self.frame = view.bounds
        let infoViewWidth = min(frame.width - 32.0, 360)
        let infoViewHeight = calculateInfoViewHeight(width: infoViewWidth)

        let path = UIBezierPath(rect: self.bounds)
        let circlePath = makeCirclePath(targetFrame: targetFrame)
        path.append(circlePath)

        let infoViewRect = makeInfoViewRect(targetFrame: targetFrame, infoViewHeight: infoViewHeight)
        let infoViewPath = makeInfoViewPath(targetFrame: targetFrame, rect: infoViewRect)
        path.append(infoViewPath)

        let mask = CAShapeLayer()
        mask.path = path.cgPath
        mask.fillRule = .evenOdd

        let shadowLayer = makeCircleShadowLayer(circlePath: circlePath.cgPath)
        shadowView.layer.addSublayer(shadowLayer)

        infoView.frame = infoViewRect
        infoView.layer.cornerRadius = 16
        infoView.layer.masksToBounds = true

        self.shadowView.layer.mask = mask
    }

    private func calculateInfoViewHeight(width: CGFloat) -> CGFloat {
        let iconWidth: CGFloat = 48.0
        let closeIconWidth: CGFloat = 24.0
        let padding: CGFloat = 16.0
        let verticalPadding: CGFloat = 16.0
        let spacingBetweenIcon: CGFloat = 12.0
        let spacingBetweenCloseIcon: CGFloat = 9.0

        let labelWidth = width - iconWidth - closeIconWidth - padding * 2 -
            spacingBetweenIcon - spacingBetweenCloseIcon

        let titleLabelHeight = titleLabel
            .textRect(forBounds: CGRect(x: 0, y: 0, width: labelWidth, height: CGFloat.greatestFiniteMagnitude),
                      limitedToNumberOfLines: 0).height
        let contentLabelHeight = contentLabel
            .textRect(forBounds: CGRect(x: 0, y: 0, width: labelWidth, height: CGFloat.greatestFiniteMagnitude),
                      limitedToNumberOfLines: 0).height
        return titleLabelHeight + contentLabelHeight + verticalPadding * 2
    }

    private func makeCirclePath(targetFrame: CGRect) -> UIBezierPath {
        let center = CGPoint(x: targetFrame.midX,
                             y: targetFrame.midY)
        return UIBezierPath(arcCenter: center,
                            radius: circleRadius,
                            startAngle: 0,
                            endAngle: CGFloat.pi * 2.0,
                            clockwise: true)
    }

    private func makeInfoViewRect(targetFrame: CGRect, infoViewHeight: CGFloat) -> CGRect {
        let infoViewWidth = min(frame.width - 32.0, 360)
        let center = CGPoint(x: targetFrame.midX, y: targetFrame.midY)
        let verticalSpacing: CGFloat = 19.0
        let trailingSpacing: CGFloat = 16.0
        let y = center.y - circleRadius - verticalSpacing
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
        let y = center.y - circleRadius - verticalSpacing
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

    private func makeCircleShadowLayer(circlePath: CGPath) -> CALayer {
        let shadowLayer = CALayer()
        shadowLayer.shadowPath = circlePath
        shadowLayer.shadowColor = UIColor.white.cgColor
        shadowLayer.shadowOpacity = 1
        shadowLayer.shadowRadius = 34
        shadowLayer.shadowOffset = CGSize(width: 0, height: 4)
        shadowLayer.masksToBounds = false
        return shadowLayer
    }
}

private enum SubviewsFactory {
    static var shadowView: UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.BlenderNorm
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

    static var closeImageView: UIImageView {
        let imageView = UIImageView(image: IconProvider.cross)
        imageView.tintColor = ColorProvider.IconNorm
        return imageView
    }
}
