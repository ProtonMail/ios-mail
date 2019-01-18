//
//  ActivityIndicatorHelper.swift
//  ProtonMail
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
