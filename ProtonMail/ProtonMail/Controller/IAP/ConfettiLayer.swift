//
//  ConfettiLayer.swift
//  ProtonMail - Created on 15/08/2019.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

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

