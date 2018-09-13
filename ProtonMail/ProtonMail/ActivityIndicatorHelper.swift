//
// Copyright 2014 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

private let ACTIVITY_INDICATOR_TAG = 99
private let ACTIVITY_INDICATOR_SIZE: CGFloat = 75
private let ACTIVITY_INDICATOR_FADE_ANIMATION_DURATION = 0.25

class ActivityIndicatorHelper {
    
    class func showActivityIndicator(at view: UIView, style: UIActivityIndicatorView.Style) {
        view.isUserInteractionEnabled = false
        let block = { () -> Void in
            var activityIndicator: UIActivityIndicatorView?
            for subview in view.subviews {
                if (subview.tag == ACTIVITY_INDICATOR_TAG) {
                    activityIndicator = subview as? UIActivityIndicatorView
                }
            }
            
            if (activityIndicator == nil) {
                activityIndicator = ActivityIndicatorHelper.setupActivityIndicator(by: style)
                view.addSubview(activityIndicator!)
                activityIndicator!.mas_makeConstraints { (make) -> Void in
                    make?.center.equalTo()(view)
                    make?.width.equalTo()(ACTIVITY_INDICATOR_SIZE)
                    make?.height.equalTo()(ACTIVITY_INDICATOR_SIZE)
                }
            }
            
            view.isUserInteractionEnabled = false
            activityIndicator!.startAnimating()
            UIView.animate(withDuration: ACTIVITY_INDICATOR_FADE_ANIMATION_DURATION, animations: { () -> Void in
                activityIndicator!.alpha = 0.8
            })
        }
        
        if (Thread.current == Thread.main) {
            block()
        } else {
            DispatchQueue.main.async(execute: { () -> Void in
                block()
            })
        }
    }
    
    class func show(at view: UIView?) {
        guard let v = view else {
            return
        }
        showActivityIndicator(at: v, style: UIActivityIndicatorView.Style.whiteLarge)
    }
    
    class func showActivityIndicator(at view: UIView) {
        showActivityIndicator(at: view, style: UIActivityIndicatorView.Style.whiteLarge)
    }
    
    class func hide(at view: UIView?) {
        guard let v = view else {
            return
        }
        hideActivityIndicator(at: v)
    }
    
    class func hideActivityIndicator(at view: UIView) {
        DispatchQueue.main.async(execute: { () -> Void in
            view.isUserInteractionEnabled = true
            
            var activityIndicator: UIActivityIndicatorView?
            for subview in view.subviews {
                if (subview.tag == ACTIVITY_INDICATOR_TAG) {
                    activityIndicator = subview as? UIActivityIndicatorView
                }
            }
            
            if (activityIndicator != nil) {
                activityIndicator!.startAnimating()
                UIView.animate(withDuration: ACTIVITY_INDICATOR_FADE_ANIMATION_DURATION, animations: { () -> Void in
                    activityIndicator!.alpha = 0
                }, completion: { (finished) -> Void in
                    activityIndicator!.stopAnimating()
                    view.isUserInteractionEnabled = true
                })
            }
        })
    }
    
    fileprivate class func setupActivityIndicator(by style: UIActivityIndicatorView.Style?) -> UIActivityIndicatorView {
        var activityIndicator: UIActivityIndicatorView!
        
        if let indicatorStyle = style {
            activityIndicator = UIActivityIndicatorView(style: indicatorStyle)
        } else {
            activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)
        }
        
        activityIndicator.backgroundColor = UIColor.black
        activityIndicator.alpha = 0
        activityIndicator.layer.cornerRadius = 8
        activityIndicator.layer.masksToBounds = true
        activityIndicator.tag = ACTIVITY_INDICATOR_TAG
        
        return activityIndicator
    }
}
