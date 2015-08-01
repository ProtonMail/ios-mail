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

class EmailView: UIView , EmailHeaderViewProtocol, UIWebViewDelegate, UIScrollViewDelegate{
    
    /// Message info
    var message: Message
    
    // Message header view
    var emailHeader : EmailHeaderView!
    
    // Message content
    var contentWebView: UIWebView!
    
    // Message attachment view
    var attachmentView : EmailAttachmentView?
    
    // Message bottom actions view
    var bottomActionView : MessageDetailBottomView!
    
    private let kButtonsViewHeight: CGFloat = 68.0
    
    
    // MARK : config layout
    func initLayouts () {
        self.emailHeader.makeConstraints()
        self.contentWebView.mas_makeConstraints { (make) -> Void in
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
    func updateHeaderData (title : String) {
        
        //emailHeader.
        
    }
    
    
    
    required init(message: Message) {
        self.message = message
        super.init(frame: CGRectZero)
        self.backgroundColor = UIColor.whiteColor()
        
        // init views
        self.setupBottomView()
        self.setupContentView()
        self.setupHeaderView()
        // self.setupAttachmentView()
        
        //self.generateData()
        //self.addSubviews()
        //self.makeConstraints()
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
        self.emailHeader.delegate = self
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

        
        let font = UIFont.robotoLight(size: UIFont.Size.h6)
        let cssColorString = UIColor.ProtonMail.Gray_383A3B.cssString
        
        let w = UIScreen.mainScreen().applicationFrame.width;
        
        var error: NSError?
        var bodyText = self.message.decryptBodyIfNeeded(&error) ?? NSLocalizedString("Unable to decrypt message.")
        
        let bundle = NSBundle.mainBundle()
        let path = bundle.pathForResource("editor", ofType: "css")
        
        
//        let css : String  = "article,aside,details,figcaption,figure,footer,header,hgroup,nav,section,summary{display:block}audio,canvas,video{display:inline-block}audio:not([controls]){display:none;height:0}[hidden]{display:none}html{font-size:80%;-webkit-text-size-adjust:80%;-ms-text-size-adjust:80%}button,html,input,select,textarea{font-family:sans-serif}body{font:15px/1.4rem normal \"Helvetica Neue\",Arial,Helvetica,sans-serif;font-weight:400;margin:0;width:100%;box-sizing:border-box;padding:1rem;word-break:break-word}a:focus{outline:dotted thin}a:active,a:hover{outline:0}h1{font-size:2em;margin:.67em 0}h2{font-size:1.5em;margin:.83em 0}h3{font-size:1.17em;margin:1em 0}h4{font-size:1em;margin:1.33em 0}h5{font-size:.83em;margin:1.67em 0}h6{font-size:.75em;margin:2.33em 0}abbr[title]{border-bottom:1px dotted}b,strong{font-weight:700}blockquote{padding:0 0 0 2rem;margin:1rem 0}blockquote blockquote{padding:0 0 0 1rem}dfn{font-style:italic}mark{background:#ff0;color:#000}p,pre{margin:1em 0}code,kbd,pre,samp{font-family:monospace,serif;font-size:1em}pre{white-space:pre;white-space:pre-wrap;word-wrap:break-word}q{quotes:none}q:after,q:before{content:\"\";content:none}small{font-size:80%}sub,sup{font-size:75%;line-height:0;position:relative;vertical-align:baseline}sup{top:-.5em}sub{bottom:-.25em}dl,menu,ol,ul{margin:1em 0}dd{margin:0 0 0 40px}menu,ol,ul{padding:0 0 0 40px}nav ol,nav ul{list-style:none}img{border:0;-ms-interpolation-mode:bicubic;max-width:100%}table img{max-width:none}svg:not(:root){overflow:hidden}figure,form{margin:0}fieldset{border:1px solid silver;margin:0 2px;padding:.35em .625em .75em}legend{border:0;padding:0;white-space:normal}button,input,select,textarea{font-size:100%;margin:0;vertical-align:baseline}button,input{line-height:normal}button,html input[type=button],input[type=reset],input[type=submit]{-webkit-appearance:button;cursor:pointer}button[disabled],input[disabled]{cursor:default}input[type=checkbox],input[type=radio]{box-sizing:border-box;padding:0}input[type=search]{-webkit-appearance:textfield;-moz-box-sizing:content-box;-webkit-box-sizing:content-box;box-sizing:content-box}input[type=search]::-webkit-search-cancel-button,input[type=search]::-webkit-search-decoration{-webkit-appearance:none}button::-moz-focus-inner,input::-moz-focus-inner{border:0;padding:0}textarea{overflow:auto;vertical-align:top}table{border-collapse:collapse;border-spacing:0}"
        
        let css = String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)!
        let htmlString = "<style>\(css)</style><div class='inbox-body'>\(bodyText)</div>"
        self.contentWebView.loadHTMLString(htmlString, baseURL: nil)
        
        // UIView.animateWithDuration(0, delay:0, options: nil, animations: { }, completion: nil)
    }
    
    func updateSize() {
        self.updateContentLayout(false)
    }
    
    private var attY : CGFloat = 0;
    private func updateContentLayout(animation: Bool) {
        UIView.animateWithDuration(animation ? 0.3 : 0, animations: { () -> Void in
            for subview in self.contentWebView.scrollView.subviews {
                let sub = subview as! UIView
                if sub == self.emailHeader {
                    //sub.backgroundColor = UIColor.yellowColor()
                    continue
                } else if subview is UIImageView {
                    //sub.hidden = true
                    continue
                } else if sub == self.attachmentView {
                    let y = self.attY
                    sub.frame = CGRect(x: sub.frame.origin.x, y:y , width: sub.frame.width, height: 100);
                    var size = self.contentWebView.scrollView.contentSize;
                    size.height = self.attY + 100;
                    self.contentWebView.scrollView.contentSize = size
                } else {
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
        let cH = webView.scrollView.contentSize.height;
        self.attachmentView?.hidden = false
        self.updateContentLayout(false)
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        self.updateContentLayout(false)
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView!, atScale scale: CGFloat) {
        self.updateContentLayout(false)
    }
}
