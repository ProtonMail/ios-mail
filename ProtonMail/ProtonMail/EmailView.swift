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
    
    //
    private let kMoreOptionsViewHeight: CGFloat = 123.0
    
    // Message header view
    var emailHeader : EmailHeaderView!
    
    // Message content
    var contentWebView: UIWebView!
    
    // Message attachment view
    var attachmentView : EmailAttachmentView?
    
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

    // MARK : config values 
    func updateHeaderData (title : String, sender : String, to:String, cc : String, bcc: String, isStarred:Bool, time : NSDate?) {
        emailHeader.updateHeaderData(title, sender:sender, to: to, cc: cc, bcc: bcc, isStarred: isStarred, time: time)
    }
    
    func updateEmailBody (body : String, meta : String) {
        let bundle = NSBundle.mainBundle()
        let path = bundle.pathForResource("editor", ofType: "css")
        
        let css = String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)!
        let htmlString = "<style>\(css)</style>\(meta)<div id='pm-body' class='inbox-body'>\(body)</div>"
        self.contentWebView.loadHTMLString(htmlString, baseURL: nil)
        
    }
    
    func updateEmailAttachment (atts : [Attachment]?) {
        self.emailHeader.updateAttachmentData(atts)
    }
    
    required init() {
        super.init(frame: CGRectZero)
        self.backgroundColor = UIColor.whiteColor()
        
        // init views
        self.setupBottomView()
        self.setupContentView()
        self.setupHeaderView()
        
        //self.setupAttachmentView()
        //updateAttachments()
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
    
    private func setupAttachmentView() {
        
        self.attachmentView = EmailAttachmentView()
        self.attachmentView!.backgroundColor = UIColor.redColor()
        //self.attachmentView.delegate = self
        self.contentWebView.scrollView.addSubview(self.attachmentView!)
        self.attachmentView!.hidden = true;
        let w = UIScreen.mainScreen().applicationFrame.width;
        self.attachmentView!.frame = CGRect(x: 0, y: 0, width: w, height: 100)
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
        self.contentWebView.frame = CGRect(x: 0, y: 0, width: w, height: 100);
        // UIView.animateWithDuration(0, delay:0, options: nil, animations: { }, completion: nil)
    }
    
    private var attY : CGFloat = 0;
    private func updateContentLayout(animation: Bool) {
        if !emailLoaded {
            return
        }
        println("\(self.contentWebView.frame)")
        UIView.animateWithDuration(animation ? 0.3 : 0, animations: { () -> Void in
            for subview in self.contentWebView.scrollView.subviews {
                let sub = subview as! UIView
                if sub == self.emailHeader {
//                    //sub.backgroundColor = UIColor.yellowColor()
                    continue
                } else if subview is UIImageView {
                    //sub.hidden = true
                    continue
                } else if sub == self.attachmentView {
                    let y = self.attY
                    sub.frame = CGRect(x: sub.frame.origin.x, y:y, width: sub.frame.width, height: 100);
                    var size = self.contentWebView.scrollView.contentSize;
                    size.height = self.attY + 100;
                    self.contentWebView.scrollView.contentSize = size
                } else {
                    
                    self.subWebview = sub
                    let h = self.emailHeader.getHeight()
                    sub.frame = CGRect(x: sub.frame.origin.x, y: h, width: sub.frame.width, height: sub.frame.height);
//                    var result = self.contentWebView.stringByEvaluatingJavaScriptFromString("document.getElementById(\"pm-body\").offsetHeight;");
//                    var height = result?.toInt()
//                   // self.attY = height != nil ? sub.frame.origin.y + CGFloat(height! / 2) : sub.frame.origin.y + sub.frame.height;
//                    
//                    if height != nil {
//                        println("\(height)")
//                    }
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
        
        self.updateContentLayout(false)
        var size = webView.sizeThatFits(CGSizeZero)
        println ("\(size)")
//        self.contentWebView.mas_updateConstraints { (make) -> Void in
//            make.removeExisting = true
//            make.top.equalTo()(self)
//            make.left.equalTo()(self)
//            make.right.equalTo()(self)
//            make.height.equalTo()(webView.scrollView.contentSize.height)
//        }
        
//        self.contentWebView.scrollView.contentSize = CGSize(width: size.width, height: size.height - 102) ;
//        self.contentWebView?.frame = CGRect(x: self.subWebview!.frame.origin.x, y: 0, width: webView.frame.width, height: CGFloat (size.height));
//        self.subWebview?.frame = CGRect(x: self.subWebview!.frame.origin.x, y: self.subWebview!.frame.origin.y, width: webView.frame.width, height: CGFloat (size.height - 102));
//        
        
       // webView.frame = CGRect(x: webView.frame.origin.x, y: webView.frame.origin.y, width: webView.frame.width, height: CGFloat (size.height + 102));

        //println("\(self.contentWebView.frame)")

//        var result = self.contentWebView.stringByEvaluatingJavaScriptFromString("document.getElementById(\"pm-body\").offsetHeight;");
//        result = self.contentWebView.stringByEvaluatingJavaScriptFromString("document.getElementById(\"pm-body\").scrollHeight;");
//        var result = self.contentWebView.stringByEvaluatingJavaScriptFromString("document.getElementById(\"pm-body\").clientHeight;");
//        var height = result!.toInt()! / 2
//        
//        if CGFloat(height + 100) <= self.frame.height {
//            webView.userInteractionEnabled = false
//        }
//        
//        
//        webView.frame = CGRect(x: webView.frame.origin.x, y: 100, width: webView.frame.width, height: CGFloat (height));
//
//        var mWebViewTextSize = webView.sizeThatFits(CGSize(width: 1.0, height: 1.0))
//        //        var mWebViewFrame = webView.frame;
//        //        mWebViewFrame.size.height = mWebViewTextSize.height;
//        //        webView.frame = mWebViewFrame;
//        //
//        //        //Disable bouncing in webview
//        //        for subview in self.contentWebView.scrollView.subviews {
//        //            if (subview is UIScrollView) {
//        //                //subview.bounces = false
//        //            }
//        //        }
//
        //let cH = webView.scrollView.contentSize.height;
        self.attachmentView?.hidden = false
        //self.updateContentLayout(false)
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        println("\(scrollView.contentSize)")
        
        self.updateContentLayout(false)
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView!, atScale scale: CGFloat) {
        println("\(scrollView.contentSize)")
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

