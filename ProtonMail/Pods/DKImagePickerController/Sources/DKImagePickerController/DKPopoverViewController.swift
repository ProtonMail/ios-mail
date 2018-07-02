//
//  DKPopoverViewController.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 15/6/27.
//  Copyright (c) 2015年 ZhangAo. All rights reserved.
//

import UIKit

open class DKPopoverViewController: UIViewController {
    
    @objc open class func popoverViewController(_ viewController: UIViewController, fromView: UIView, arrowColor: UIColor = UIColor.white) {
        let window = UIApplication.shared.keyWindow!
        
        let popoverViewController = DKPopoverViewController()
        
        popoverViewController.arrowColor = arrowColor
        popoverViewController.contentViewController = viewController
        popoverViewController.fromView = fromView
        
        popoverViewController.showInView(window)
        window.rootViewController!.addChildViewController(popoverViewController)
    }
    
    @objc open class func dismissPopoverViewController() {
        let window = UIApplication.shared.keyWindow!

        for vc in window.rootViewController!.childViewControllers {
            if vc is DKPopoverViewController {
                (vc as! DKPopoverViewController).dismiss()
            }
        }
    }
    
    private class DKPopoverView: UIView {
        
        var contentView: UIView! {
            didSet {
                contentView.layer.cornerRadius = 5
				contentView.clipsToBounds = true
                contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                self.addSubview(contentView)
            }
        }
        
        let arrowWidth: CGFloat = 20
        let arrowHeight: CGFloat = 10
        var arrowColor = UIColor.white
        fileprivate let arrowImageView: UIImageView = UIImageView()
        
        public init(arrowColor: UIColor) {
            super.init(frame: CGRect.zero)
            
            self.arrowColor = arrowColor
            self.commonInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            
            self.commonInit()
        }
        
        func commonInit() {
            arrowImageView.image = self.arrowImage()
            self.addSubview(arrowImageView)
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.arrowImageView.frame = CGRect(x: (self.bounds.width - self.arrowWidth) / 2, y: 0, width: arrowWidth, height: arrowHeight)
            self.contentView.frame = CGRect(x: 0, y: self.arrowHeight, width: self.bounds.width, height: self.bounds.height - arrowHeight)
        }
        
        func arrowImage() -> UIImage {
            UIGraphicsBeginImageContextWithOptions(CGSize(width: arrowWidth, height: arrowHeight), false, UIScreen.main.scale)
            
            let context = UIGraphicsGetCurrentContext()
            UIColor.clear.setFill()
            context?.fill(CGRect(x: 0, y: 0, width: arrowWidth, height: arrowHeight))
            
            let arrowPath = CGMutablePath()
            
            arrowPath.move(to: CGPoint(x: arrowWidth / 2, y: 0))
            arrowPath.addLine(to: CGPoint(x: arrowWidth, y: arrowHeight))
            arrowPath.addLine(to: CGPoint(x: 0, y: arrowHeight))
            arrowPath.closeSubpath()

            context?.addPath(arrowPath)
            
            context?.setFillColor(self.arrowColor.cgColor)
            context?.drawPath(using: CGPathDrawingMode.fill)

            let arrowImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return arrowImage!
        }
    }
    
    @objc public var arrowColor = UIColor.white
    
    private var contentViewController: UIViewController!
    private var fromView: UIView!
    private var popoverView: DKPopoverView!
    
    override open func loadView() {
        super.loadView()
        
        let backgroundView = UIControl(frame: self.view.frame)
        backgroundView.backgroundColor = UIColor.clear
        backgroundView.addTarget(self, action: #selector(dismiss as () -> Void), for: .touchUpInside)
        backgroundView.autoresizingMask = self.view.autoresizingMask
        self.view = backgroundView
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.popoverView = DKPopoverView(arrowColor: self.arrowColor)
        self.view.addSubview(self.popoverView)
    }

	@available(iOS, deprecated: 8.0)
    override open func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
		super.didRotate(from: fromInterfaceOrientation)
		
        UIView.animate(withDuration: 0.2, animations: {
            self.popoverView.frame = self.calculatePopoverViewFrame()
        })
    }
    
    func showInView(_ view: UIView) {
		view.addSubview(self.view)
		
		self.popoverView.contentView = self.contentViewController.view
        self.popoverView.frame = self.calculatePopoverViewFrame()
        
        self.contentViewController!.addObserver(self,
                                                forKeyPath: "preferredContentSize",
                                                options: .new,
                                                context: nil)
		
        self.popoverView.transform = self.popoverView.transform.translatedBy(x: 0, y: -(self.popoverView.bounds.height / 2)).scaledBy(x: 0.1, y: 0.1)
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.3, options: .allowUserInteraction, animations: {
            self.popoverView.transform = CGAffineTransform.identity
            self.view.backgroundColor = UIColor(white: 0.4, alpha: 0.4)
        }, completion: nil)
    }
    
    @objc func dismiss() {
        self.contentViewController.removeObserver(self, forKeyPath: "preferredContentSize")
        
        UIView.animate(withDuration: 0.2, animations: {
            self.popoverView.transform = self.popoverView.transform.translatedBy(x: 0, y: -(self.popoverView.bounds.height / 2)).scaledBy(x: 0.01, y: 0.01)
            self.view.backgroundColor = UIColor.clear
        }, completion: { result in
            self.view.removeFromSuperview()
            self.removeFromParentViewController()
        }) 
    }
	
	func calculatePopoverViewFrame() -> CGRect {
		let popoverY = self.fromView.convert(self.fromView.frame.origin, to: self.view).y + self.fromView.bounds.height

        let preferredContentSize = self.contentViewController.preferredContentSize
		var popoverWidth = preferredContentSize.width
		if popoverWidth == UIViewNoIntrinsicMetric {
			if UI_USER_INTERFACE_IDIOM() == .pad {
				popoverWidth = self.view.bounds.width * 0.6
			} else {
				popoverWidth = self.view.bounds.width
			}
		}
		
		let popoverHeight = min(preferredContentSize.height + self.popoverView.arrowHeight, view.bounds.height - popoverY - 40)
		
		return CGRect(
			x: (self.view.bounds.width - popoverWidth) / 2,
			y: popoverY,
			width: popoverWidth,
			height: popoverHeight
		)
	}
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "preferredContentSize" {
            UIView.animate(withDuration: 0.2, animations: {
                self.popoverView.frame = self.calculatePopoverViewFrame()
            })
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
