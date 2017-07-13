//
//  EmailView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/27/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import UIKit
import QuickLook

protocol EmailViewProtocol {
    func mailto(_ url: URL?)
}

class EmailView: UIView, UIWebViewDelegate, UIScrollViewDelegate{
    
    var kDefautWebViewScale : CGFloat = 0.9
    
    //
    fileprivate let kMoreOptionsViewHeight: CGFloat = 123.0
    
    // Message header view
    var emailHeader : EmailHeaderView!
    
    var viewDelegate: EmailViewProtocol?
    
    // Message content
    var contentWebView: UIWebView!
    
    // Message bottom actions view
    var bottomActionView : MessageDetailBottomView!
    
    var topMessageView : TopMessageView!
    
    fileprivate let kDefaultSpaceHide : CGFloat = -34.0
    fileprivate let kDefaultSpaceShow : CGFloat = 4.0
    fileprivate let kDefaultTopMessageHeight : CGFloat = 34
    
    fileprivate let kLeftOffset : CGFloat = 4.0
    fileprivate let kRightOffset : CGFloat = -4.0
    
    fileprivate let kAnimationDuration : TimeInterval = 0.25
    //
    var subWebview : UIView?
    
    fileprivate var isViewingMoreOptions: Bool = false

    fileprivate let kButtonsViewHeight: CGFloat = 68.0
    
    fileprivate var emailLoaded : Bool = false;
    
    // MARK : config layout
    func initLayouts () {
        self.emailHeader.makeConstraints()
        self.contentWebView.mas_updateConstraints { (make) -> Void in
            make?.removeExisting = true
            let _ = make?.top.equalTo()(self)
            let _ = make?.left.equalTo()(self)
            let _ = make?.right.equalTo()(self)
            let _ = make?.bottom.equalTo()(self.bottomActionView.mas_top)
        }
        
        bottomActionView.mas_makeConstraints { (make) -> Void in
            let _ = make?.removeExisting = true
            let _ = make?.bottom.equalTo()(self)
            let _ = make?.left.equalTo()(self)
            let _ = make?.right.equalTo()(self)
            let _ = make?.height.equalTo()(self.kButtonsViewHeight)
        }
        
        topMessageView.mas_makeConstraints { (make) in
            make?.removeExisting = true
            let _ = make?.top.equalTo()(self)?.offset()(self.kDefaultSpaceHide)
            let _ = make?.left.equalTo()(self)?.offset()(self.kLeftOffset)
            let _ = make?.right.equalTo()(self)?.offset()(self.kRightOffset)
            let _ = make?.height.equalTo()(self.kDefaultTopMessageHeight)
        }
    }
    
    func rotate() {
        let w = UIScreen.main.applicationFrame.width;
        self.emailHeader.frame = CGRect(x: 0, y: 0, width: w, height: self.emailHeader.getHeight())
        self.emailHeader.makeConstraints()
        self.emailHeader.updateHeaderLayout()
    }

    // MARK : config values 
    func updateHeaderData (_ title : String,
                           sender : ContactVO, to:[ContactVO]?, cc : [ContactVO]?, bcc: [ContactVO]?,
                           isStarred:Bool, time : Date?, encType: EncryptTypes, labels : [Label]?,
                           showShowImages: Bool, expiration : Date?,
                           score: MessageSpamScore) {
        
        self.emailHeader.updateHeaderData(title, sender:sender,
                                          to: to, cc: cc, bcc: bcc,
                                          isStarred: isStarred, time: time, encType: encType,
                                          labels : labels, showShowImages: showShowImages, expiration : expiration,
                                          score: score)
        self.emailHeader.updateHeaderLayout()
    }
    
    func updateEmailBody (_ body : String, meta : String) {
        let bundle = Bundle.main
        let path = bundle.path(forResource: "editor", ofType: "css")
        let css = try! String(contentsOfFile: path!, encoding: String.Encoding.utf8)
        let htmlString = "<style>\(css)</style>\(meta)<div id='pm-body' class='inbox-body'>\(body)</div>"
        self.contentWebView.loadHTMLString(htmlString, baseURL: nil)
    }
    
    func updateEmailAttachment (_ atts : [Attachment]?) {
        self.emailHeader.updateAttachmentData(atts)
    }
    
    required override init(frame : CGRect) {
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.white
        
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
    
    fileprivate func setTopMessageView() {
        self.topMessageView = TopMessageView()
        self.topMessageView.backgroundColor = UIColor.white
        self.addSubview(topMessageView);
        let w = UIScreen.main.applicationFrame.width;
        self.topMessageView.frame = CGRect(x: 0, y: 0, width: w, height:34);
    }
    
    fileprivate func setupBottomView() {
        //TODO:: need to handle the empty instead of !
        //TODO:: crash happens sometime only one or two here need handle it
        self.bottomActionView = Bundle.main.loadNibNamed("MessageDetailBottomView", owner: 0, options: nil)![0] as? MessageDetailBottomView
        self.bottomActionView.backgroundColor = UIColor.ProtonMail.Gray_E8EBED
        self.addSubview(bottomActionView)
    }
    
    fileprivate func setupHeaderView () {
        self.emailHeader = EmailHeaderView()
        self.emailHeader.backgroundColor = UIColor.white
        self.emailHeader.viewDelegate = self
        self.contentWebView.scrollView.addSubview(self.emailHeader)
        let w = UIScreen.main.applicationFrame.width;
        self.emailHeader.frame = CGRect(x: 0, y: 0, width: w, height: self.emailHeader.getHeight())
    }
    
    fileprivate func setupContentView() {
        self.contentWebView = PMWebView()
        self.contentWebView.scalesPageToFit = true;
        self.addSubview(contentWebView)
        self.contentWebView.backgroundColor = UIColor.white
        self.contentWebView.isUserInteractionEnabled = true
        self.contentWebView.scrollView.isScrollEnabled = true
        self.contentWebView.scrollView.alwaysBounceVertical = true
        self.contentWebView.scrollView.isUserInteractionEnabled = true
        self.contentWebView.scrollView.bounces = true;
        self.contentWebView.delegate = self
        self.contentWebView.scrollView.delegate = self
        let w = UIScreen.main.applicationFrame.width;
        self.contentWebView.frame = CGRect(x: 0, y: 0, width: w, height:100);
    }
    
    fileprivate var attY : CGFloat = 0;
    fileprivate func updateContentLayout(_ animation: Bool) {
        if !emailLoaded {
           return
        }
        UIView.animate(withDuration: animation ? self.kAnimationDuration : 0, animations: { () -> Void in
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
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        if navigationType == .linkClicked {
            if request.url?.scheme == "mailto" {
                viewDelegate?.mailto(request.url)
                return false
            } else {
                UIApplication.shared.openURL(request.url!)
                return false
            }
        }
        return true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        
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
            webView.stringByEvaluatingJavaScript(from: js);
        }
        self.emailLoaded = true
        self.updateContentLayout(false)
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.updateContentLayout(false)
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.updateContentLayout(false)
    }
}

extension EmailView {
    
    internal func showTimeOutErrorMessage() {
        topMessageView.mas_updateConstraints { (make) in
            let _ = make?.top.equalTo()(self)?.offset()(self.self.kDefaultSpaceShow)
        }
        let _ = self.topMessageView.updateMessage(timeOut: "The request timed out.")
        UIView.animate(withDuration: self.kAnimationDuration, animations: { () -> Void in
            self.layoutIfNeeded()
        })
    }
    
    func showNoInternetErrorMessage() {
        topMessageView.mas_updateConstraints { (make) in
            let _ = make?.top.equalTo()(self)?.offset()(self.self.kDefaultSpaceShow)
        }
        let _ = self.topMessageView.updateMessage(noInternet : "No connectivity detected...")
        UIView.animate(withDuration: self.kAnimationDuration, animations: { () -> Void in
            self.layoutIfNeeded()
        })
    }
    
    func showErrorMessage(_ errorMsg : String) {
        topMessageView.mas_updateConstraints { (make) in
            let _ = make?.top.equalTo()(self)?.offset()(self.self.kDefaultSpaceShow)
        }
        let _ = self.topMessageView.updateMessage(errorMsg : errorMsg)
        UIView.animate(withDuration: self.kAnimationDuration, animations: { () -> Void in
            self.layoutIfNeeded()
        })
    }
    
    internal func reachabilityChanged(_ note : Notification) {
        if let curReach = note.object as? Reachability {
            self.updateInterfaceWithReachability(curReach)
        }
    }
    
    internal func updateInterfaceWithReachability(_ reachability : Reachability) {
        let netStatus = reachability.currentReachabilityStatus()
        let connectionRequired = reachability.connectionRequired()
        PMLog.D("connectionRequired : \(connectionRequired)")
        switch (netStatus)
        {
        case NotReachable:
            PMLog.D("Access Not Available")
            topMessageView.mas_updateConstraints { (make) in
                let _ = make?.top.equalTo()(self)?.offset()(self.self.kDefaultSpaceShow)
            }
            let _ = self.topMessageView.updateMessage(noInternet: "No connectivity detected...")
        case ReachableViaWWAN:
            PMLog.D("Reachable WWAN")
            topMessageView.mas_updateConstraints { (make) in
                let _ = make?.top.equalTo()(self)?.offset()(self.kDefaultSpaceHide)
            }
        case ReachableViaWiFi:
            PMLog.D("Reachable WiFi")
            topMessageView.mas_updateConstraints { (make) in
                let _ = make?.top.equalTo()(self)?.offset()(self.kDefaultSpaceHide)
            }
        default:
            PMLog.D("Reachable default unknow")
        }
        
        UIView.animate(withDuration: self.kAnimationDuration, animations: { () -> Void in
            self.layoutIfNeeded()
        })
    }
    
    internal func hideTopMessage() {
        topMessageView.mas_updateConstraints { (make) in
            let _ = make?.top.equalTo()(self)?.offset()(self.kDefaultSpaceHide)
        }
        UIView.animate(withDuration: self.kAnimationDuration, animations: { () -> Void in
           self.layoutIfNeeded()
        })
    }

}

//
extension EmailView : EmailHeaderViewProtocol {
    func updateSize() {
        self.updateContentLayout(false)
    }
    
    func starredChanged(_ isStarred: Bool) {
        
    }
}
