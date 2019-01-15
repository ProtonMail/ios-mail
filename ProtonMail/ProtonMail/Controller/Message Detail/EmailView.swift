//
//  EmailView.swift
//  ProtonMail - Created on 7/27/15.
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


import Foundation
import UIKit
import QuickLook
import WebKit

@available(iOS 10.0, *) extension WKDataDetectorTypes {
    public static var pm_email: WKDataDetectorTypes = [.phoneNumber, .link]
}

protocol EmailViewActionsProtocol {
    func mailto(_ url: URL?)
}

/// this veiw is all subviews container
class EmailView: UIView, UIScrollViewDelegate{
    
    static let kDefautWebViewScale : CGFloat = 0.9
    //
    fileprivate let kMoreOptionsViewHeight: CGFloat = 123.0
    
    // Message header view
    var emailHeader : EmailHeaderView!
    
    weak var delegate: (EmailViewActionsProtocol&TopMessageViewDelegate)?
    
    // Message content
    var contentWebView: PMWebView!
    private lazy var loader: WebContentsSecureLoader = {
        if #available(iOS 11.0, *) {
            return HTTPRequestSecureLoader()
        } else {
            return HTMLStringSecureLoader()
        }
    }()
    
    // Message bottom actions view
    var bottomActionView : MessageDetailBottomView!
    
    private weak var topMessageView : TopMessageView?
    
    fileprivate let kAnimationDuration : TimeInterval = 0.25
    //
    
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
        
        self.bottomActionView.mas_makeConstraints { (make) in
            make?.removeExisting = true
            make?.left.mas_equalTo()(self)
            make?.right.mas_equalTo()(self)
            make?.height.mas_equalTo()(self.kButtonsViewHeight)
            make?.bottom.mas_equalTo()(self.mas_bottomMargin)
        }
    }
    
    func rotate() {
        let w = UIScreen.main.bounds.width
        self.emailHeader.frame = CGRect(x: 0, y: 0, width: w, height: self.emailHeader.getHeight())
        self.emailHeader.makeConstraints()
        self.emailHeader.updateHeaderLayout()
    }

    // MARK : config values 
    func updateHeaderData (_ title : String,
                           sender : ContactVO, to:[ContactVO]?, cc : [ContactVO]?, bcc: [ContactVO]?,
                           isStarred:Bool, time : Date?, encType: EncryptTypes, labels : [Label]?,
                           showShowImages: Bool, expiration : Date?,
                           score: Message.SpamScore, isSent: Bool) {
        
        self.emailHeader.updateHeaderData(title, sender:sender,
                                          to: to, cc: cc, bcc: bcc,
                                          isStarred: isStarred, time: time, encType: encType,
                                          labels : labels, showShowImages: showShowImages, expiration : expiration,
                                          score: score, isSent: isSent)
        self.emailHeader.updateHeaderLayout()
    }
    
    func updateEmailContent(_ contents: WebContents) {
        if #available(iOS 11.0, *) {
            self.loader.load(contents: contents, in: self.contentWebView)
        }
    }
    
    func updateEmail(attachments atts : [Attachment]?, inline: [AttachmentInfo]?) {
        var attachments = [AttachmentInfo]()
        
        if let atts = atts {
            for att in atts {
                attachments.append(AttachmentNormal(att: att))
            }
        }
        
        if let inline = inline {
            attachments.append(contentsOf: inline)
        }
        
        self.emailHeader.update(attachments: attachments)
    }
    
    required override init(frame : CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    private func setup() {
        self.backgroundColor = UIColor.white
        
        // init views
        self.setupBottomView()
        self.setupContentView()
        self.setupHeaderView()
        
        self.updateContentLayout(false)
    }
    
    fileprivate func setupBottomView() {
        var frame = self.frame
        frame.size.height = self.kButtonsViewHeight
        self.bottomActionView = MessageDetailBottomView(frame: frame)
        self.addSubview(bottomActionView)
    }
    
    fileprivate func setupHeaderView () {
        var frame = self.frame
        frame.size.height = 100
        self.emailHeader = EmailHeaderView(frame : frame)
        self.emailHeader.backgroundColor = UIColor.white
        self.emailHeader.viewDelegate = self
        self.contentWebView.scrollView.addSubview(self.emailHeader)
        let w = UIScreen.main.bounds.width
        self.emailHeader.frame = CGRect(x: 0, y: 0, width: w, height: self.emailHeader.getHeight())
    }
    
    func showDetails(show : Bool ) {
        self.emailHeader.isShowingDetail = show
    }
    
    fileprivate func setupContentView() {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = false
        preferences.javaScriptCanOpenWindowsAutomatically = false
        
        let config = WKWebViewConfiguration()
        config.preferences = preferences
        if #available(iOS 11.0, *) {
            self.loader.inject(into: config)
        }
        if #available(iOS 10.0, *) {
            config.dataDetectorTypes = .pm_email
            config.ignoresViewportScaleLimits = true
        }
        
        self.contentWebView = PMWebView(frame: .zero, configuration: config)
        self.addSubview(contentWebView)
        
        self.contentWebView.backgroundColor = UIColor.white
        self.contentWebView.isUserInteractionEnabled = true
        self.contentWebView.scrollView.isScrollEnabled = true
        self.contentWebView.scrollView.alwaysBounceVertical = true
        self.contentWebView.scrollView.isUserInteractionEnabled = true
        self.contentWebView.scrollView.bounces = true;
        self.contentWebView.navigationDelegate = self
        self.contentWebView.uiDelegate = self
        self.contentWebView.scrollView.delegate = self
        let w = UIScreen.main.bounds.width
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
                    // FIXME: this should be done for highlight overlay subview also
                    
                    let h = self.emailHeader.getHeight()
                    sub.frame = CGRect(x: sub.frame.origin.x, y: h, width: sub.frame.width, height: sub.frame.height);
                    self.contentWebView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: h, right: 0)
                }
            }
        })
    }
}

extension EmailView: WKNavigationDelegate, WKUIDelegate {
    @available(iOS 10.0, *)
    func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        return false
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .linkActivated where navigationAction.request.url?.scheme == "mailto":
            self.delegate?.mailto(navigationAction.request.url)
            decisionHandler(.cancel)
            
        case .linkActivated where navigationAction.request.url != nil:
            UIApplication.shared.openURL(navigationAction.request.url!)
            decisionHandler(.cancel)
            
        default:
            decisionHandler(.allow)
        }
    }

    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        contentWebView.becomeFirstResponder()
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
    
    private func showBanner(_ message: String,
                            appearance: TopMessageView.Appearance,
                            buttons: Set<TopMessageView.Buttons> = [])
    {
        if let oldMessageView = self.topMessageView {
            oldMessageView.remove(animated: true)
        }

        let newMessageView = TopMessageView(appearance: appearance,
                                            message: message,
                                            buttons: buttons,
                                            lowerPoint: 8.0)
        newMessageView.delegate = self.delegate
        
            self.topMessageView = newMessageView
        self.addSubview(newMessageView)
        self.addSubview(newMessageView)
        newMessageView.showAnimation(withSuperView: self)
    }
    
    internal func showTimeOutErrorMessage() {
        showBanner(LocalString._general_request_timed_out, appearance: .red, buttons: [.close])
    }
    
    func showNoInternetErrorMessage() {
        showBanner(LocalString._general_no_connectivity_detected, appearance: .red, buttons: [.close])
    }
    
    func showErrorMessage(_ errorMsg : String) {
        showBanner(errorMsg, appearance: .red)
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
        case .NotReachable:
            PMLog.D("Access Not Available")
            self.showNoInternetErrorMessage()
            
        case .ReachableViaWWAN:
            self.hideTopMessage()
            
        case .ReachableViaWiFi:
            self.hideTopMessage()
            
        default:
            PMLog.D("Reachable default unknow")
        }
    }
    
    internal func hideTopMessage() {
        self.topMessageView?.remove(animated: true)
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
