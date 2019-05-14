//
//  TopMessageView.swift
//  ProtonMail - Created on 6/3/16.
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


import Foundation

class BannerView : PMView {
    private weak var superView: UIView!
    private var animator: UIDynamicAnimator!
    private var springBehavior: UIAttachmentBehavior!
    private var offset: CGFloat
    private var dismissDuration: TimeInterval
    private var timer: Timer?
    private var buttonConfig: ButtonConfiguration?
    
    @IBOutlet private weak var button: UIButton!
    @IBOutlet private var backgroundView: UIView!
    @IBOutlet private weak var messageLabel: UILabel!
    
    override func getNibName() -> String {
        return "\(BannerView.self)";
    }
    
    @IBAction func closeAction(_ sender: UIButton) {
        self.buttonConfig?.action?()
    }
    
    enum Appearance {
        case red // TODO: rename according to semantic, not appearance
        case purple
        case gray
        
        var backgroundColor: UIColor {
            switch self {
            case .red: return .red
            case .purple: return UIColor(RRGGBB: UInt(0x9199CB))
            case .gray: return .lightGray
            }
        }
        
        var textColor: UIColor {
            return .white
        }
        
        var backgroundAlpha: CGFloat {
            return 0.75
        }
    }

    enum Base {
        case top, bottom
    }
    
    struct ButtonConfiguration {
        let title: String
        let action: (()->Void)?
    }
    
    init(appearance: Appearance,
         message: String,
         buttons: ButtonConfiguration?,
         offset: CGFloat,
         dismissDuration: TimeInterval = 4)
    {
        self.offset = offset
        self.dismissDuration = dismissDuration
        
        super.init(frame: CGRect.zero)
        
        self.roundCorners()
        self.messageLabel.text = message
        self.messageLabel.textColor = appearance.textColor
        self.backgroundView.backgroundColor = appearance.backgroundColor
        self.backgroundView.alpha = appearance.backgroundAlpha
        self.buttonConfig = buttons
        
        if let config = buttons {
            self.button.isHidden = false
            self.button.setTitle(config.title, for: .normal)
        } else {
            self.button.isHidden = true
        }
        
        messageLabel.sizeToFit()
        self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPan(gesture:))))
    }
    
    required init(coder aDecoder: NSCoder) {
        self.offset = 0
        self.dismissDuration = 0
        super.init(coder: aDecoder)
    }
}

extension BannerView: UIGestureRecognizerDelegate {

    func drop(on baseView: UIView, from: Base) {
        self.superView = baseView
        
        // sizing
        let xPadding: CGFloat = 20.0
        let yPadding: CGFloat = 8.0
        let sizeOfText = self.messageLabel.textRect(forBounds: baseView.bounds.insetBy(dx: 3.0 * xPadding + self.button.bounds.width, dy: 0), limitedToNumberOfLines: 0).insetBy(dx: 0, dy: -1.0 * yPadding)
        let size = CGSize(width: baseView.bounds.insetBy(dx: xPadding, dy: 0).width, height: sizeOfText.height)
        self.frame = CGRect(origin: .zero, size: size)
        let initAnchor = CGPoint(x: (baseView.bounds.width / 2),
                                 y: from == .bottom ? (baseView.bounds.height - self.bounds.height / 2) - offset
                                                    : (self.bounds.height / 2) + offset)
        
        self.animator = UIDynamicAnimator(referenceView: baseView)
        
        // original location
        self.center = initAnchor.applying(CGAffineTransform(translationX: 0, y: from == .bottom ? (baseView.bounds.height - initAnchor.y)
                                                                                                : (-initAnchor.y)))
        
        let springBehavior = UIAttachmentBehavior(item: self, attachedToAnchor: initAnchor)
        springBehavior.length = 0
        springBehavior.damping = 0.9
        springBehavior.frequency = 2
        self.animator.addBehavior(springBehavior)
        self.springBehavior = springBehavior
        
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.1,
                       options: [.curveEaseIn],
                       animations: {
                self.center = initAnchor
        }) { _ in
            self.startTimer()
        }
    }
    
    @objc func remove(animated: Bool) {
        self.invalidateTimer()
        self.springBehavior = nil
        self.animator = nil
        
        guard let superView = self.superView else {
            self.removeFromSuperview()
            return
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut], animations: { [weak self] in
            guard let self = self else { return }
            self.alpha = 0
            if self.center.y < (superView.bounds.height / 2) {
                self.center = self.center.applying(CGAffineTransform(translationX: 0,
                                                                     y: -self.center.y - self.bounds.height))
            } else {
                self.center = self.center.applying(CGAffineTransform(translationX: 0,
                                                                     y: superView.bounds.height + self.bounds.height))
            }
        }, completion: { [weak self] _ in
            self?.removeFromSuperview()
        })
    }
    
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: self.dismissDuration, target: self, selector: #selector(remove(animated:)), userInfo: nil, repeats: false)
    }
    
    func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc func onPan(gesture: UIPanGestureRecognizer) {
        guard let referenceView = self.animator.referenceView else { return }
        
        switch gesture.state {
        case .began:
            self.invalidateTimer()
            self.animator.removeBehavior(self.springBehavior)

        case .changed:
            let anchor = self.springBehavior.anchorPoint
            let translation = gesture.translation(in: referenceView).y

            var y: CGFloat
            let left = (self.superView.bounds.height / 2) - self.center.y
            let right = (self.superView.bounds.height / 2) - self.center.y + translation
            if left < right  {
                let unboundedY = anchor.y + translation
                y = rubberBandDistance( offset: unboundedY - anchor.y, dimension: referenceView.bounds.height - anchor.y)
            } else {
                y = translation
            }
            self.center = CGPoint(x: anchor.x, y: y + anchor.y)
            
        case .ended, .cancelled, .failed:
            let velocity = gesture.velocity(in: referenceView).y
            let duration: TimeInterval = 0.3
            let finalY = velocity * CGFloat(duration) + self.center.y
            if finalY < 0 || finalY > referenceView.bounds.height {
                UIView.animate(withDuration: duration, animations: {
                    var center = self.center
                    center.y = finalY
                    self.center = center
                }) { _ in
                    self.removeFromSuperview()
                }
            } else {
                self.startTimer()
                self.animator.addBehavior(self.springBehavior)
            }
        default: break
        }
    }
    
    internal func rubberBandDistance(offset: CGFloat, dimension: CGFloat) -> CGFloat {
        let constant: CGFloat = 0.55
        let absOffset = abs(offset)
        let result = (constant * absOffset * dimension) / (dimension + constant * absOffset)
        return offset < 0 ? -result : result
    }
}
