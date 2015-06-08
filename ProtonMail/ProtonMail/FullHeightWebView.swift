//
//  FullHeightWebView.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

class FullHeightWebView: UIWebView {
    
    private var kvoContext = 0
    private let scrollViewContentSizeKeyPath = "scrollView.contentSize"

//    override init() {
//        super.init()
//    }
//    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        scrollView.scrollEnabled = true
        scrollView.alwaysBounceVertical = true
        scrollView.userInteractionEnabled = true
        scrollView.delegate = self
        //self.scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = false;
        //self.scalesPageToFit = true;
        //addObserver(self, forKeyPath: scrollViewContentSizeKeyPath, options: .New, context: &kvoContext)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        //removeObserver(self, forKeyPath: scrollViewContentSizeKeyPath, context: &kvoContext)
    }
    
    override func updateConstraints() {
        mas_updateConstraints { (make) -> Void in
            println("height: \(self.scrollView.contentSize.height)")
            make.height.equalTo()(self.scrollView.contentSize.height)
            return
        }
        super.updateConstraints()
    }
    
    // MARK: - KVO
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if context != &kvoContext {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        } else if object as! FullHeightWebView == self && keyPath == scrollViewContentSizeKeyPath && frame.height != scrollView.contentSize.height {
            setNeedsUpdateConstraints()
            layoutIfNeeded()
        }
    }
}



extension FullHeightWebView : UIScrollViewDelegate
{
    override func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView!, atScale scale: CGFloat)
    {
        //        var frame = self.emailBodyWebView.frame
        //        frame.size.height = self.emailBodyWebView.scrollView.contentSize.height
        //        self.emailBodyWebView.frame = frame
        //
        //        self.emailBodyWebView.updateConstraints();
        //        self.emailBodyWebView.layoutIfNeeded();
        //        self.layoutIfNeeded();
        //        self.updateConstraints();
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if (scrollView.contentOffset.y != 0) {
            var offset = scrollView.contentOffset;
            offset.y = 0.0;
            scrollView.contentOffset = offset;
            
  

        }
        
    }
    
}

