// Copyright (c) 2024 Proton Technologies AG
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

import InboxDesignSystem
import UIKit

final class SpinnerButton: UIButton {
    private struct Appearance {
        static let lineWidth: CGFloat = 3.0
        static let outlinePadding: CGFloat = 3.0
        static let spinnerColor = DS.Color.Brand.minus10.toDynamicUIColor
    }

    private lazy var progressLayer: CAShapeLayer = {
         let layer = CAShapeLayer()
         layer.isHidden = true
         layer.lineWidth = Appearance.lineWidth
         layer.lineCap = .round
         layer.strokeStart = 0
         layer.strokeEnd = 1
         layer.fillColor = UIColor.clear.cgColor
         layer.strokeColor = Appearance.spinnerColor.cgColor
         return layer
     }()

    required init?(coder: NSCoder) { nil }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear
        setImage(UIImage(resource: DS.Icon.icCross), for: .normal)
        tintColor = DS.Color.Icon.weak.toDynamicUIColor
        layer.addSublayer(progressLayer)
        startSpinning()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let circlePath = UIBezierPath(
            arcCenter: .zero,
            radius: (bounds.width - Appearance.lineWidth) / 2 + Appearance.outlinePadding,
            startAngle: 0,
            endAngle: CGFloat.pi * 3 / 2,
            clockwise: true
        ).cgPath

        progressLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        progressLayer.path = circlePath
    }

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = DS.Color.InteractionWeak.pressed.toDynamicUIColor
            } else {
                UIView.animate(withDuration: 0.2) {
                    self.backgroundColor = .clear
                }
            }
        }
    }

    func configure(isSpinning: Bool) {
        progressLayer.isHidden = !isSpinning
    }

    private func startSpinning() {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.toValue = CGFloat.pi * 2
        rotationAnimation.duration = 1
        rotationAnimation.repeatCount = .infinity
        progressLayer.add(rotationAnimation, forKey: "rotation")
    }
}
