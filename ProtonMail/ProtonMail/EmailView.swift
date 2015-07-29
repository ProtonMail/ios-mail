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

class EmailView: UIView {
    
    /// Message info
    var message: Message
    
    // Message header view
    var emailHeader : EmailHeaderView!
    
    // Message content
    var contentWebView: UIWebView!
    
    // Message bottom view
    var bottomActionView : MessageDetailBottomView!
    
    
    private let kButtonsViewHeight: CGFloat = 68.0
    
    
    required init(message: Message) {
        self.message = message
        
        super.init(frame: CGRectZero)
        self.backgroundColor = UIColor.whiteColor()
        
        // init views
        self.setupBottomView()
        self.setupContentView()
        
        //        self.generateData()
        //        self.addSubviews()
        //        self.makeConstraints()
        //updateAttachments()
    }
    

    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        //message.removeObserver(self, forKeyPath: Message.Attributes.isDetailDownloaded, context: &kKVOContext)
    }
    
    private func setupBottomView() {
        self.bottomActionView = NSBundle.mainBundle().loadNibNamed("MessageDetailBottomView", owner: 0, options: nil)[0] as? MessageDetailBottomView
        self.bottomActionView.backgroundColor = UIColor.ProtonMail.Gray_E8EBED
        self.addSubview(bottomActionView)
        
        bottomActionView.mas_makeConstraints { (make) -> Void in
            make.bottom.equalTo()(self)
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self.kButtonsViewHeight)
        }
    }
    
    private func setupHeaderView () {
        
    }
    
    private func setupContentView() {
        contentWebView = UIWebView()
        contentWebView.userInteractionEnabled = true
        contentWebView.scalesPageToFit = true;
        self.addSubview(contentWebView)

        contentWebView.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self)
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.bottom.equalTo()(self.bottomActionView.mas_top)
        }


        let font = UIFont.robotoLight(size: UIFont.Size.h6)
        let cssColorString = UIColor.ProtonMail.Gray_383A3B.cssString
        
        let w = UIScreen.mainScreen().applicationFrame.width;
        
        var error: NSError?
        var bodyText = self.message.decryptBodyIfNeeded(&error) ?? NSLocalizedString("Unable to decrypt message.")
        
        let bundle = NSBundle.mainBundle()
        let path = bundle.pathForResource("editor", ofType: "css")
        let css = String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)!
        let htmlString = "<style>\(css)</style><div class='inbox-body'>\(bodyText)</div>"
        
        self.contentWebView.loadHTMLString(htmlString, baseURL: nil)
        
        var myButton = UIView(frame: CGRect(x: 0, y: 0, width: w, height: 100))
        myButton.backgroundColor = UIColor.redColor()
        self.contentWebView.scrollView.addSubview(myButton )
        
        for subview in self.contentWebView.scrollView.subviews {
            let sub = subview as! UIView
            if sub == myButton {
                continue
            } else if subview is UIImageView {
                sub.hidden = true
            } else {
                sub.frame = CGRect(x: sub.frame.origin.x, y: sub.frame.origin.y + myButton.frame.height, width: sub.frame.width, height: sub.frame.height);
            }
        }
        
        
    }
    
    
    
}
//
//
//// MARK: - MoreOptionsViewDelegate
//
//extension MessageDetailView: MoreOptionsViewDelegate {
//    func moreOptionsViewDidMarkAsUnread(moreOptionsView: MoreOptionsView) {
//        delegate?.messageDetailView(self, didTapMarkAsUnreadForMessage: message)
//
//        animateMoreViewOptions()
//    }
//
//    func moreOptionsViewDidSelectMoveTo(moreOptionsView: MoreOptionsView) {
//        delegate?.messageDetailView(self, didTapMoveToForMessage: message)
//
//        animateMoreViewOptions()
//    }
//}
//
//
//// MARK: - UITableViewDataSource
//
//extension MessageDetailView: UITableViewDataSource {
//
//    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let attachment = attachmentForIndexPath(indexPath)
//        let cell = tableView.dequeueReusableCellWithIdentifier(AttachmentTableViewCell.Constant.identifier, forIndexPath: indexPath) as! AttachmentTableViewCell
//        cell.setFilename(attachment.fileName, fileSize: Int(attachment.fileSize))
//        return cell
//    }
//
//    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return attachments.count
//    }
//}
//
//
//// MARK: - UITableViewDelegate
//
//extension MessageDetailView: UITableViewDelegate {
//
//    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        tableView.deselectRowAtIndexPath(indexPath, animated: true)
//        let attachment = attachmentForIndexPath(indexPath)
//        if !attachment.isDownloaded {
//            downloadAttachment(attachment, forIndexPath: indexPath)
//        } else if let localURL = attachment.localURL {
//            if NSFileManager.defaultManager().fileExistsAtPath(attachment.localURL!.path!, isDirectory: nil) {
//                let cell = tableView.cellForRowAtIndexPath(indexPath)
//                let data: NSData = NSData(base64EncodedString: attachment.keyPacket!, options: NSDataBase64DecodingOptions(rawValue: 0))!
//                openLocalURL(localURL, keyPackage: data, fileName: attachment.fileName, forCell: cell!)
//            } else {
//                attachment.localURL = nil
//                let error = attachment.managedObjectContext?.saveUpstreamIfNeeded()
//                if error != nil  {
//                    NSLog("\(__FUNCTION__) error: \(error)")
//                }
//
//                downloadAttachment(attachment, forIndexPath: indexPath)
//            }
//        }
//    }
//
//    // MARK: Private methods
//
//    private func downloadAttachment(attachment: Attachment, forIndexPath indexPath: NSIndexPath) {
//        sharedMessageDataService.fetchAttachmentForAttachment(attachment, downloadTask: { (task) -> Void in
//            if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? AttachmentTableViewCell {
//                cell.progressView.alpha = 1.0
//                cell.progressView.setProgressWithDownloadProgressOfTask(task, animated: true)
//            }
//            }, completion: { (_, url, error) -> Void in
//                if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? AttachmentTableViewCell {
//                    UIView.animateWithDuration(self.kAnimationDuration, animations: { () -> Void in
//                        cell.progressView.hidden = true
//                        if let localURL = attachment.localURL {
//                            if NSFileManager.defaultManager().fileExistsAtPath(attachment.localURL!.path!, isDirectory: nil) {
//                                let cell = self.tableView.cellForRowAtIndexPath(indexPath)
//                                let data: NSData = NSData(base64EncodedString: attachment.keyPacket!, options: NSDataBase64DecodingOptions(rawValue: 0))!
//                                self.openLocalURL(localURL, keyPackage: data, fileName: attachment.fileName, forCell: cell!)
//                            }
//                        }
//                    })
//                }
//        })
//    }
//
//    private func openLocalURL(localURL: NSURL, keyPackage:NSData, fileName:String, forCell cell: UITableViewCell) {
//
//        if let data : NSData = NSData(contentsOfURL: localURL) {
//            tempFileUri = NSFileManager.defaultManager().attachmentDirectory.URLByAppendingPathComponent(fileName);
//            let decryptData = data.decryptAttachment(keyPackage, passphrase: sharedUserDataService.mailboxPassword!, publicKey: sharedUserDataService.userInfo!.publicKey, privateKey: sharedUserDataService.userInfo!.privateKey, error: nil)
//
//            decryptData!.writeToURL(tempFileUri!, atomically: true)
//
//            let previewQL = QLPreviewController()
//            previewQL.dataSource = self
//            if let viewController = delegate as? MessageDetailViewController {
//                viewController.presentViewController(previewQL, animated: true, completion: nil)
//            }
//        }
//        else{
//
//        }
//    }
//}
//
//
//// MARK: - UIDocumentInteractionControllerDelegate
//
//extension MessageDetailView: UIDocumentInteractionControllerDelegate {
//}
//
//
//extension MessageDetailView : QLPreviewControllerDataSource {
//    func numberOfPreviewItemsInPreviewController(controller: QLPreviewController!) -> Int {
//        return 1
//    }
//
//    func previewController(controller: QLPreviewController!, previewItemAtIndex index: Int) -> QLPreviewItem! {
//        let fileURL : NSURL
//        //        if let filePath = urlList[index].lastPathComponent {
//        //            fileURL = NSBundle.mainBundle().URLForResource(filePath, withExtension:nil)
//        //        }
//        return tempFileUri // 6
//    }
//}
//
//// MARK: - UIWebViewDelegate
//
//extension MessageDetailView: UIWebViewDelegate {
//
//    func webViewDidFinishLoad(webView: UIWebView) {
//        // triggers scrollView.contentSize update
//        //let jsForTextSize = "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '\(100)%'";
//        //webView.stringByEvaluatingJavaScriptFromString(jsForTextSize)
//
//        var frame = webView.frame
//        frame.size.height = 1;
//        webView.frame = frame
//
//        if (self.message.hasAttachments) {
//            self.attachments = self.message.attachments.allObjects as! [Attachment]
//        }
//
//        var webframe = self.emailBodyWebView.scrollView.frame;
//        webframe.size = CGSize(width: webframe.width,  height: self.emailBodyWebView.scrollView.contentSize.height)
//        self.emailBodyWebView.scrollView.frame = webframe;
//
//        var frameB = self.emailBodyWebView.frame
//        frameB.size.height = self.emailBodyWebView.scrollView.contentSize.height
//        self.emailBodyWebView.frame = frameB
//
//        UIView.animateWithDuration(kAnimationDuration, animations: { () -> Void in
//            self.emailBodyWebView.alpha = 1.0
//            }, completion: { finished in
//
//                self.emailBodyWebView.updateConstraints();
//                self.emailBodyWebView.layoutIfNeeded();
//                self.layoutIfNeeded();
//                self.updateConstraints();
//                self.tableView.reloadData()
//                self.tableView.tableHeaderView = self.contentView
//        })
//    }
//
//    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
//        if navigationType == .LinkClicked {
//            UIApplication.sharedApplication().openURL(request.URL!)
//            return false
//        }
//
//        return true
//    }
//}