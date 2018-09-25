//
//  TopMessageView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/3/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation

@objc protocol TopMessageViewDelegate {
    @objc optional func retry()
    @objc optional func close()
}

class TopMessageView : PMView {
    private var dynamicAnimator: UIDynamicAnimator!
    private var attach: UIAttachmentBehavior!
    private var slide: UIAttachmentBehavior!
    private var gravity: UIGravityBehavior!
    private var push: UIPushBehavior!
    private weak var superView: UIView!
    private var didTouch: Bool = false

    private var lowerPoint: CGFloat = 0
    
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private var backgroundView: UIView!
    @IBOutlet private weak var messageLabel: UILabel!
    
    fileprivate var timerAutoDismiss : Timer?
    var delegate : TopMessageViewDelegate?
    
    override func getNibName() -> String {
        return "TopMessageView";
    }
    
    override func setup() {
        closeButton.setTitle(LocalString._retry, for: .normal)
    }
    
    @IBAction func closeAction(_ sender: UIButton) {
        delegate?.retry?()
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
            return 0.9
        }
    }
    enum Buttons {
        case close
    }
    
    init(appearance: Appearance,
         message: String,
         buttons: Set<Buttons>,
         lowerPoint: CGFloat = 0.0)
    {
        super.init(frame: CGRect.zero)
        self.lowerPoint = lowerPoint
        
        self.roundCorners()
        self.messageLabel.text = message
        self.messageLabel.textColor = appearance.textColor
        self.backgroundView.backgroundColor = appearance.backgroundColor
        self.backgroundView.alpha = appearance.backgroundAlpha
        
        self.closeButton.isHidden = !buttons.contains(.close)
        
        messageLabel.sizeToFit()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // TODO: For EmailView only, remove
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
}


extension TopMessageView: UIGestureRecognizerDelegate {

    func showAnimation(withSuperView view: UIView) {
        self.superView = view
        
        // sizing
        let xPadding: CGFloat = 20.0
        let yPadding: CGFloat = 8.0
        let sizeOfText = self.messageLabel.textRect(forBounds: view.bounds.insetBy(dx: 2.0 * xPadding, dy: 0), limitedToNumberOfLines: 0).insetBy(dx: 0, dy: -1.0 * yPadding)
        self.frame = CGRect(origin: CGPoint(x: view.frame.origin.x + xPadding, y: -1.0 * sizeOfText.height),
                            size: CGSize(width: view.bounds.insetBy(dx: xPadding, dy: 0).width, height: sizeOfText.height))

        // gesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(gesture:)))
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)
        
        
        //animator
        self.dynamicAnimator = UIDynamicAnimator(referenceView: view)
        
        //slider
        slide = UIAttachmentBehavior.slidingAttachment(with: self, attachmentAnchor: CGPoint(x: 0, y:0), axisOfTranslation: CGVector(dx: 0, dy: 1))
        slide.attachmentRange = UIFloatRange(minimum: -self.bounds.height - self.lowerPoint , maximum: 0)
        self.dynamicAnimator.addBehavior(slide)
        
        // push
        push = UIPushBehavior(items: [self], mode: .continuous)
        self.dynamicAnimator.addBehavior(push)
        
        // attach
        attach = UIAttachmentBehavior(item: self, attachedToAnchor: .zero)
        
        //gravity
        gravity = UIGravityBehavior(items: [self])
        gravity.gravityDirection = .init(dx: 0, dy: 1)
        self.dynamicAnimator.addBehavior(gravity)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) { [weak self] in
            guard let strongSelf = self, !strongSelf.didTouch else { return }
            strongSelf.remove(animated: true)
        }
    }
    
    func remove(animated: Bool) {
        if animated {
            self.gravity?.gravityDirection = .init(dx: 0.0, dy: -1.0)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
            self?.removeFromSuperview()
        }
    }
    
    // MARK: Gestures actions
    
    @objc func handleGesture(gesture: UIPanGestureRecognizer) {
        attach.anchorPoint = gesture.location(in: self.superView)
        
        switch gesture.state {
        case .began:
            didTouch = true
            dynamicAnimator.addBehavior(attach)
        case .ended:
            dynamicAnimator.removeBehavior(attach)
            
            push.pushDirection = CGVector(dx: 0, dy: gesture.translation(in: self).y)
            push.magnitude = abs(gesture.velocity(in: self).y)
            push.active = true
            
            if gesture.translation(in: self).y < 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    self.removeFromSuperview()
                }
            }
            
        case .cancelled:
            dynamicAnimator.removeBehavior(attach)
        default: break
        }
    }
    
    // MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        self.didTouch = true
        return true
    }
}
