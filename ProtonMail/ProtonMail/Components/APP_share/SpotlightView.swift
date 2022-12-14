// Copyright (c) 2022 Proton Technologies AG
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

class SpotlightView: UIView {
    private var dismissGesture: UITapGestureRecognizer?
    private let shadowView = UIView()
    private let infoView = UIView()
    private let iconImageView = SubViewFactory.iconImageView
    private let titleLabel = SubViewFactory.titleLabel
    private let msgLabel = SubViewFactory.messageLabel
    private let circleRadius: CGFloat = 25.0

    init(title: String, message: String, icon: ImageAsset) {
        super.init(frame: .zero)

        titleLabel.attributedText = title.apply(style: FontManager.DefaultStrong)
        msgLabel.attributedText = message.apply(style: FontManager.DefaultSmall.addTruncatingTail())
        iconImageView.image = icon.image

        setup()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(shadowView)
        shadowView.fillSuperview()
        shadowView.backgroundColor = ColorProvider.BlenderNorm.withAlphaComponent(0.46)
        infoView.backgroundColor = ColorProvider.BackgroundNorm

        addSubview(infoView)

        infoView.addSubview(iconImageView)
        infoView.addSubview(titleLabel)
        infoView.addSubview(msgLabel)

        setupGesture()
    }

    private func setupLayout() {
        [
            iconImageView.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            iconImageView.topAnchor.constraint(equalTo: titleLabel.topAnchor, constant: 4),
            iconImageView.widthAnchor.constraint(equalToConstant: 48),
            iconImageView.heightAnchor.constraint(equalToConstant: 48)
        ].activate()

        [
            titleLabel.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -16)
        ].activate()

        [
            msgLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            msgLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            msgLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            msgLabel.bottomAnchor.constraint(equalTo: infoView.bottomAnchor, constant: -14)
        ].activate()
    }

    private func setupGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.dismiss))
        addGestureRecognizer(gesture)
        self.dismissGesture = gesture
    }

    @objc
    private func dismiss() {
        removeFromSuperview()
    }

    func presentOn(view: UIView, targetFrame: CGRect) {
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
        let iconWidth: CGFloat = 64.0
        let padding: CGFloat = 16.0
        let verticalPadding: CGFloat = 14.0
        let labelWidth = width - iconWidth - padding * 2
        let msgLabelHeight = msgLabel
            .textRect(forBounds: CGRect(x: 0, y: 0, width: labelWidth, height: CGFloat.greatestFiniteMagnitude),
                      limitedToNumberOfLines: 0).height
        let titleLabelHeight = titleLabel
            .textRect(forBounds: CGRect(x: 0, y: 0, width: labelWidth, height: CGFloat.greatestFiniteMagnitude),
                      limitedToNumberOfLines: 0).height
        return msgLabelHeight + titleLabelHeight + 4 + verticalPadding * 2
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
        let y = center.y + circleRadius + verticalSpacing
        let x = frame.width - infoViewWidth - trailingSpacing
        return CGRect(x: x,
                      y: y,
                      width: infoViewWidth,
                      height: max(102, infoViewHeight))
    }

    private func makeInfoViewPath(targetFrame: CGRect, rect: CGRect) -> UIBezierPath {
        let center = CGPoint(x: targetFrame.midX, y: targetFrame.midY)
        let verticalSpacing: CGFloat = 19.0
        let y = center.y + circleRadius + verticalSpacing
        // draw the round rect of the infoView
        let infoViewPath = UIBezierPath(roundedRect: rect,
                                        cornerRadius: 16)
        // draw the upper arrow
        let arrowLeftPoint = CGPoint(x: center.x - 10, y: y)
        let arrowTopPoint = CGPoint(x: center.x, y: y - 9)
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

    private enum SubViewFactory {
        static var iconImageView: UIImageView {
            let view = UIImageView()
            view.contentMode = .scaleAspectFit
            return view
        }

        static var titleLabel: UILabel {
            let view = UILabel()
            view.numberOfLines = 0
            return view
        }

        static var messageLabel: UILabel {
            let view = UILabel()
            view.numberOfLines = 0
            return view
        }
    }
}
