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

class MessageDetailViewController: ProtonMailViewController {
    
    var message: Message! {
        didSet {
            message.fetchDetailIfNeeded() { _, _, error in
                if error != nil {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
            }
        }
    }
    
    private var actionTapped: String!
    
    @IBOutlet var messageDetailView: MessageDetailView!
    
    override func loadView() {
        messageDetailView = MessageDetailView(message: message, delegate: self)
        
        self.view = messageDetailView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupRightButtons()
    }
    
    override func shouldShowSideMenu() -> Bool {
        return false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        messageDetailView.updateEmailBodyWebView(false)
        messageDetailView.layoutIfNeeded()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        message.isRead = true
    }
    
    private func setupRightButtons() {
        var rightButtons: [UIBarButtonItem]
        
        let removeBarButtonItem = UIBarButtonItem(image: UIImage(named: "trash_selected"), style: UIBarButtonItemStyle.Plain, target: self, action: "removeButtonTapped")
        let spamBarButtonItem = UIBarButtonItem(image: UIImage(named: "spam_selected"), style: UIBarButtonItemStyle.Plain, target: self, action: "spamButtonTapped")
        let moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow_down"), style: UIBarButtonItemStyle.Plain, target: self, action: "moreButtonTapped")
        
        rightButtons = [moreBarButtonItem, spamBarButtonItem, removeBarButtonItem]
        self.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
    }
    
    func removeButtonTapped() {
        ActivityIndicatorHelper.showActivityIndicatorAtView(self.view)
        sharedAPIService.messageID(message.messageID, updateWithAction: MessageDataService.MessageAction.delete.rawValue) { (task: NSURLSessionDataTask!, response: Dictionary<String, AnyObject>?, error: NSError?) -> Void in
            ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
            
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    func spamButtonTapped() {
        ActivityIndicatorHelper.showActivityIndicatorAtView(self.view)
        
        delay(1.5) {
            ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
            self.navigationController?.popViewControllerAnimated(true)
        }
        
        /*
        sharedAPIService.messageID(message.messageID, updateWithAction: MessageDataService.MessageAction.spam.rawValue) { (task: NSURLSessionDataTask!, response: Dictionary<String, AnyObject>?, error: NSError?) -> Void in
            ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
        }
        */
    }
    
    func moreButtonTapped() {
        self.messageDetailView.animateMoreViewOptions()
    }
}

extension MessageDetailViewController: MessageDetailViewDelegate {
    
    func messageDetailView(messageDetailView: MessageDetailView, didFailDecodeWithError error: NSError) {
        NSLog("\(__FUNCTION__) \(error)")
        
        let alertController = error.alertController()
        alertController.addOKAction()
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func messageDetailViewDidTapForwardMessage(messageView: MessageDetailView, message: Message) {
        actionTapped = ComposeView.ComposeMessageAction.Forward
        self.performSegueWithIdentifier("toCompose", sender: self)
    }
    
    func messageDetailViewDidTapReplyAllMessage(messageView: MessageDetailView, message: Message) {
        actionTapped = ComposeView.ComposeMessageAction.ReplyAll
        self.performSegueWithIdentifier("toCompose", sender: self)
    }
    
    func messageDetailViewDidTapReplyMessage(messageView: MessageDetailView, message: Message) {
        actionTapped = ComposeView.ComposeMessageAction.Reply
        self.performSegueWithIdentifier("toCompose", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "toCompose") {
            let composeViewController = segue.destinationViewController.viewControllers!.first as ComposeViewController
            composeViewController.message = message
            composeViewController.action = self.actionTapped
        }
    }
}