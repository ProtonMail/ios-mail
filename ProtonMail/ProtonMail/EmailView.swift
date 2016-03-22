//
//  EmailView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/27/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation



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

import UIKit
import QuickLook



class EmailView: UIView, UIWebViewDelegate, UIScrollViewDelegate{
    
    static let kDefautWebViewScale : CGFloat = 0.70
    
    //
    private let kMoreOptionsViewHeight: CGFloat = 123.0
    
    // Message header view
    var emailHeader : EmailHeaderView!
    
    // Message content
    var contentWebView: UIWebView!
    
    // Message bottom actions view
    var bottomActionView : MessageDetailBottomView!
    
    //
    var subWebview : UIView?
    
    
    private var isViewingMoreOptions: Bool = false

    private let kButtonsViewHeight: CGFloat = 68.0
    
    private var emailLoaded : Bool = false;
    
    // MARK : config layout
    func initLayouts () {
        self.emailHeader.makeConstraints()
        self.contentWebView.mas_updateConstraints { (make) -> Void in
            make.removeExisting = true
            make.top.equalTo()(self)
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.bottom.equalTo()(self.bottomActionView.mas_top)
        }
        
        bottomActionView.mas_makeConstraints { (make) -> Void in
            make.bottom.equalTo()(self)
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self.kButtonsViewHeight)
        }
    }
    
    func rotate() {
        let w = UIScreen.mainScreen().applicationFrame.width;
        self.emailHeader.frame = CGRect(x: 0, y: 0, width: w, height: self.emailHeader.getHeight())
        self.emailHeader.makeConstraints()
        self.emailHeader.updateHeaderLayout()
    }

    // MARK : config values 
    func updateHeaderData (title : String, sender : ContactVO, to:[ContactVO]?, cc : [ContactVO]?, bcc: [ContactVO]?, isStarred:Bool, time : NSDate?, encType: EncryptTypes, labels : [Label]?) {
        emailHeader.updateHeaderData(title, sender:sender, to: to, cc: cc, bcc: bcc, isStarred: isStarred, time: time, encType: encType, labels : labels)
    }
    
    func updateEmailBody (body : String, meta : String) {
        let bundle = NSBundle.mainBundle()
        let path = bundle.pathForResource("editor", ofType: "css")
        
        let css = String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)!
        let htmlString = "<style>\(css)</style>\(meta)<div id='pm-body' class='inbox-body'>\(body)</div>"
        self.contentWebView.loadHTMLString(htmlString, baseURL: nil)

//        if let sub = subWebview {
//            sub.hidden = true;
//        }
    }
    
    func updateEmailAttachment (atts : [Attachment]?) {
        self.emailHeader.updateAttachmentData(atts)
    }
    
    required override init(frame : CGRect) {
        super.init(frame: CGRectZero)
        self.backgroundColor = UIColor.whiteColor()
        
        // init views
        self.setupBottomView()
        self.setupContentView()
        self.setupHeaderView()
        
        self.updateContentLayout(false)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBottomView() {
        self.bottomActionView = NSBundle.mainBundle().loadNibNamed("MessageDetailBottomView", owner: 0, options: nil)[0] as? MessageDetailBottomView
        self.bottomActionView.backgroundColor = UIColor.ProtonMail.Gray_E8EBED
        self.addSubview(bottomActionView)
    }
    
    private func setupHeaderView () {
        self.emailHeader = EmailHeaderView()
        self.emailHeader.backgroundColor = UIColor.whiteColor()
        self.emailHeader.viewDelegate = self
        self.contentWebView.scrollView.addSubview(self.emailHeader)
        let w = UIScreen.mainScreen().applicationFrame.width;
        self.emailHeader.frame = CGRect(x: 0, y: 0, width: w, height: self.emailHeader.getHeight())
    }
    
    private func setupContentView() {
        self.contentWebView = UIWebView()
        self.contentWebView.scalesPageToFit = true;
        self.addSubview(contentWebView)
        self.contentWebView.backgroundColor = UIColor.whiteColor()
        self.contentWebView.userInteractionEnabled = true
        self.contentWebView.scrollView.scrollEnabled = true
        self.contentWebView.scrollView.alwaysBounceVertical = true
        self.contentWebView.scrollView.userInteractionEnabled = true
        self.contentWebView.scrollView.bounces = true;
        self.contentWebView.delegate = self
        self.contentWebView.scrollView.delegate = self
        let w = UIScreen.mainScreen().applicationFrame.width;
        self.contentWebView.frame = CGRect(x: 0, y: 0, width: w, height:100);
    }
    
    private var attY : CGFloat = 0;
    private func updateContentLayout(animation: Bool) {
        if !emailLoaded {
           return
        }
        UIView.animateWithDuration(animation ? 0.3 : 0, animations: { () -> Void in
            for subview in self.contentWebView.scrollView.subviews {
                let sub = subview as! UIView
                if sub == self.emailHeader {
                    continue
                } else if subview is UIImageView {
                    continue
                } else {
                    self.subWebview = sub
                    // new
//                    if let subOk = self.subWebview {
//                        if !self.emailLoaded {
//                            subOk.hidden = true;
//                        }
//                    }
                    let h = self.emailHeader.getHeight()
//                    PMLog.D("\(sub.frame.height)")
//                    PMLog.D("\(self.contentWebView.frame)")
                    sub.frame = CGRect(x: sub.frame.origin.x, y: h, width: sub.frame.width, height: sub.frame.height);
                    self.attY = sub.frame.origin.y + sub.frame.height;
                }
            }
        })
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == .LinkClicked {
            UIApplication.sharedApplication().openURL(request.URL!)
            return false
        }
        return true
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        self.emailLoaded = true;
        var size = webView.sizeThatFits(CGSizeZero)
        let scroll = webView.scrollView
        var zoom = webView.bounds.size.width / scroll.contentSize.width;
        PMLog.D("\(zoom)")
        if zoom < 1 {
            zoom = zoom * EmailView.kDefautWebViewScale
            PMLog.D("\(zoom)")
            webView.stringByEvaluatingJavaScriptFromString("document.body.style.zoom = \(zoom);")
        }
        
        self.updateContentLayout(false)

//        UIView.animateWithDuration(0.3, animations: { () -> Void in
//            if let subOk = self.subWebview {
//                if self.emailLoaded {
//                    subOk.hidden = false;
//                }
//            }
//        })
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        //PMLog.D("\(scrollView.contentSize)")
        self.updateContentLayout(false)
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView!, atScale scale: CGFloat) {
        //PMLog.D("\(scrollView.contentSize)")
        self.updateContentLayout(false)
    }
}

//
extension EmailView : EmailHeaderViewProtocol {
    
    func updateSize() {
        self.updateContentLayout(false)
    }
    
    func starredChanged(isStarred: Bool) {
        
    }
}

