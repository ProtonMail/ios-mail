//
//  ConfettiLayer.swift
//  ProtonMail - Created on 15/08/2019.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.
    

import UIKit

final class ConfettiLayer: CAEmitterLayer {
    static func fire(on view: UIView,
                     duration: TimeInterval = 1.5,
                     delegate: CAAnimationDelegate? = nil)
    {
        let layer = ConfettiLayer()
        layer.configure()
        layer.frame = view.bounds
        layer.needsDisplayOnBoundsChange = true
        view.layer.addSublayer(layer)
        
        guard duration.isFinite else { return }
        
        let animation = CAKeyframeAnimation(keyPath: #keyPath(CAEmitterLayer.birthRate))
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        animation.values = [1, 0, 0]
        animation.keyTimes = [0, 0.5, 1]
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        layer.beginTime = CACurrentMediaTime()
        layer.birthRate = 1.0
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            let transition = CATransition()
            transition.delegate = delegate
            transition.type = .fade
            transition.duration = 1
            transition.timingFunction = CAMediaTimingFunction(name: .easeOut)
            transition.setValue(layer, forKey: String(describing: ConfettiLayer.self))
            transition.isRemovedOnCompletion = false
            
            layer.add(transition, forKey: nil)
            
            layer.opacity = 0
        }
        layer.add(animation, forKey: nil)
        CATransaction.commit()
    }
    
    func configure() {
        self.emitterCells = ["✨", "🍏", "🌈", "❄️", "🎉", "🎊"].map { symbol in
            let cell = CAEmitterCell()

            cell.birthRate = 50.0
            cell.lifetime = 10.0
            cell.velocity = CGFloat(cell.birthRate * cell.lifetime)
            cell.velocityRange = cell.velocity / 2
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spinRange = .pi * 6
            cell.scaleRange = 0.25
            cell.scale = 1.0 - cell.scaleRange
            cell.contents = { () -> UIImage in
                let string = NSString(string: symbol)
                let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 16.0)]
                let size = string.size(withAttributes: attributes)
                return UIGraphicsImageRenderer(size: size).image { _ in
                    string.draw(at: .zero, withAttributes: attributes)
                }
                }().cgImage

            return cell
        }
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()

        emitterShape = .line
        emitterSize = CGSize(width: frame.size.width, height: 1.0)
        emitterPosition = CGPoint(x: frame.size.width / 2.0, y: 0)
    }
}

