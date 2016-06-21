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
    
    var kDefautWebViewScale : CGFloat = 0.9
    
    //
    private let kMoreOptionsViewHeight: CGFloat = 123.0
    
    // Message header view
    var emailHeader : EmailHeaderView!
    
    // Message content
    var contentWebView: UIWebView!
    
    // Message bottom actions view
    var bottomActionView : MessageDetailBottomView!
    
    var topMessageView : TopMessageView!
    
    private let kDefaultSpaceHide : CGFloat = -34.0
    private let kDefaultSpaceShow : CGFloat = 4.0
    private let kDefaultTopMessageHeight : CGFloat = 34
    
    private let kLeftOffset : CGFloat = 4.0
    private let kRightOffset : CGFloat = -4.0
    
    private let kAnimationDuration : NSTimeInterval = 0.25
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
            make.removeExisting = true
            make.bottom.equalTo()(self)
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self.kButtonsViewHeight)
        }
        
        topMessageView.mas_makeConstraints { (make) in
            make.removeExisting = true
            make.top.equalTo()(self).offset()(self.kDefaultSpaceHide)
            make.left.equalTo()(self).offset()(self.kLeftOffset)
            make.right.equalTo()(self).offset()(self.kRightOffset)
            make.height.equalTo()(self.kDefaultTopMessageHeight)
        }
    }
    
    func rotate() {
        let w = UIScreen.mainScreen().applicationFrame.width;
        self.emailHeader.frame = CGRect(x: 0, y: 0, width: w, height: self.emailHeader.getHeight())
        self.emailHeader.makeConstraints()
        self.emailHeader.updateHeaderLayout()
    }

    // MARK : config values 
    func updateHeaderData (title : String, sender : ContactVO, to:[ContactVO]?, cc : [ContactVO]?, bcc: [ContactVO]?, isStarred:Bool, time : NSDate?, encType: EncryptTypes, labels : [Label]?, showShowImages: Bool, expiration : NSDate?) {
        self.emailHeader.updateHeaderData(title, sender:sender, to: to, cc: cc, bcc: bcc, isStarred: isStarred, time: time, encType: encType, labels : labels, showShowImages: showShowImages, expiration : expiration)
        self.emailHeader.updateHeaderLayout()
    }
    
    func updateEmailBody (body : String, meta : String) {
        let bundle = NSBundle.mainBundle()
        let path = bundle.pathForResource("editor", ofType: "css")
        let css = try! String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)
        let htmlString = "<style>\(css)</style>\(meta)<div id='pm-body' class='inbox-body'>\(body)</div>"
        self.contentWebView.loadHTMLString(htmlString, baseURL: nil)
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
        self.setTopMessageView();
        
        self.updateContentLayout(false)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setTopMessageView() {
        self.topMessageView = TopMessageView()
        self.topMessageView.backgroundColor = UIColor.whiteColor()
        self.addSubview(topMessageView);
        let w = UIScreen.mainScreen().applicationFrame.width;
        self.topMessageView.frame = CGRect(x: 0, y: 0, width: w, height:34);
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
        self.contentWebView = PMWebView()
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
        UIView.animateWithDuration(animation ? self.kAnimationDuration : 0, animations: { () -> Void in
            for subview in self.contentWebView.scrollView.subviews {
                let sub = subview 
                if sub == self.emailHeader {
                    continue
                } else if subview is UIImageView {
                    continue
                } else {
                    self.subWebview = sub
                    let h = self.emailHeader.getHeight()
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
        
        //contentWebView.scrollView.subviews.first?.becomeFirstResponder()
        contentWebView.becomeFirstResponder()
        
        let contentSize = webView.scrollView.contentSize
        let viewSize = webView.bounds.size
        var zoom = viewSize.width / contentSize.width
        if zoom < 1 {
            zoom = zoom * self.kDefautWebViewScale - 0.05
            self.kDefautWebViewScale = zoom
            PMLog.D("\(zoom)")
            let js = "var t=document.createElement('meta'); t.name=\"viewport\"; t.content=\"target-densitydpi=device-dpi, width=device-width, initial-scale=\(self.kDefautWebViewScale), maximum-scale=3.0\"; document.getElementsByTagName('head')[0].appendChild(t);";
            webView.stringByEvaluatingJavaScriptFromString(js);
        }
        self.emailLoaded = true
        self.updateContentLayout(false)
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        self.updateContentLayout(false)
    }

    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        self.updateContentLayout(false)
    }
}

extension EmailView {
    
    internal func showTimeOutErrorMessage() {
        topMessageView.mas_updateConstraints { (make) in
            make.top.equalTo()(self).offset()(self.self.kDefaultSpaceShow)
        }
        self.topMessageView.updateMessage(timeOut: "The request timed out.")
        UIView.animateWithDuration(self.kAnimationDuration, animations: { () -> Void in
            self.layoutIfNeeded()
        })
    }
    
    func showNoInternetErrorMessage() {
        topMessageView.mas_updateConstraints { (make) in
            make.top.equalTo()(self).offset()(self.self.kDefaultSpaceShow)
        }
        self.topMessageView.updateMessage(noInternet : "No connectivity detected...")
        UIView.animateWithDuration(self.kAnimationDuration, animations: { () -> Void in
            self.layoutIfNeeded()
        })
    }
    
    func showErrorMessage(errorMsg : String) {
        topMessageView.mas_updateConstraints { (make) in
            make.top.equalTo()(self).offset()(self.self.kDefaultSpaceShow)
        }
        self.topMessageView.updateMessage(errorMsg : errorMsg)
        UIView.animateWithDuration(self.kAnimationDuration, animations: { () -> Void in
            self.layoutIfNeeded()
        })
    }
    
    internal func reachabilityChanged(note : NSNotification) {
        if let curReach = note.object as? Reachability {
            self.updateInterfaceWithReachability(curReach)
        }
    }
    
    internal func updateInterfaceWithReachability(reachability : Reachability) {
        let netStatus = reachability.currentReachabilityStatus()
        let connectionRequired = reachability.connectionRequired()
        PMLog.D("connectionRequired : \(connectionRequired)")
        switch (netStatus)
        {
        case NotReachable:
            PMLog.D("Access Not Available")
            topMessageView.mas_updateConstraints { (make) in
                make.top.equalTo()(self).offset()(self.self.kDefaultSpaceShow)
            }
            self.topMessageView.updateMessage(noInternet: "No connectivity detected...")
        case ReachableViaWWAN:
            PMLog.D("Reachable WWAN")
            topMessageView.mas_updateConstraints { (make) in
                make.top.equalTo()(self).offset()(self.kDefaultSpaceHide)
            }
        case ReachableViaWiFi:
            PMLog.D("Reachable WiFi")
            topMessageView.mas_updateConstraints { (make) in
                make.top.equalTo()(self).offset()(self.kDefaultSpaceHide)
            }
        default:
            PMLog.D("Reachable default unknow")
        }
        
        UIView.animateWithDuration(self.kAnimationDuration, animations: { () -> Void in
            self.layoutIfNeeded()
        })
    }
    
    internal func hideTopMessage() {
        topMessageView.mas_updateConstraints { (make) in
            make.top.equalTo()(self).offset()(self.kDefaultSpaceHide)
        }
        UIView.animateWithDuration(self.kAnimationDuration, animations: { () -> Void in
           self.layoutIfNeeded()
        })
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
