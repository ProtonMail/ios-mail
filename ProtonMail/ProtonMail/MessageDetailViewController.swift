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
        var rightButtons: [UIBarButtonItem] = []
        
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "arrow_down"), style: UIBarButtonItemStyle.Plain, target: self, action: "moreButtonTapped"))

        if message.location != .spam {
            rightButtons.append(UIBarButtonItem(image: UIImage(named: "spam_selected"), style: UIBarButtonItemStyle.Plain, target: self, action: "spamButtonTapped"))
        }

        rightButtons.append(UIBarButtonItem(image: UIImage(named: "trash_selected"), style: UIBarButtonItemStyle.Plain, target: self, action: "removeButtonTapped"))
        
        self.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
    }
    
    func removeButtonTapped() {
        switch(message.location) {
        case .trash, .spam:
            message.location = .deleted
        default:
            message.location = .trash
        }

        if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
        }

        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func spamButtonTapped() {
        message.location = .spam
        
        if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
        }
        
        self.navigationController?.popViewControllerAnimated(true)
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
    
    func messageDetailView(messageDetailView: MessageDetailView, didTapMarkAsUnreadForMessage message: Message) {
        message.isRead = false
        
        if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
        }
        
        navigationController?.popViewControllerAnimated(true)
    }
    
    func messageDetailView(messageDetailView: MessageDetailView, didTapMoveToForMessage message: Message) {
        let alertController = UIAlertController(title: NSLocalizedString("Move to..."), message: nil, preferredStyle: .ActionSheet)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .Cancel, handler: nil))
        
        if message.location != .inbox {
            alertController.addAction(UIAlertAction(title: MessageLocation.inbox.description, style: .Default, handler: { (action) -> Void in
                message.location = .inbox
                
                if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
                
                self.navigationController?.popViewControllerAnimated(true)
            }))
        }
        
        if message.location != .spam {
            alertController.addAction(UIAlertAction(title: MessageLocation.spam.description, style: .Default, handler: { (action) -> Void in
                message.location = .spam
                
                if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
                
                self.navigationController?.popViewControllerAnimated(true)
            }))
        }
        
        if message.location != .trash {
            alertController.addAction(UIAlertAction(title: MessageLocation.trash.description, style: .Destructive, handler: { (action) -> Void in
                message.location = .trash
                
                if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
                
                self.navigationController?.popViewControllerAnimated(true)
            }))
        }

        presentViewController(alertController, animated: true, completion: nil)
    }
    
    
    
    func messageDetailViewDidTapReplyMessage(messageView: MessageDetailView, message: Message) {
        actionTapped = ComposeView.ComposeMessageAction.Reply
        self.performSegueWithIdentifier("toCompose", sender: self)
    }
    
    func messageDetailViewDidTapReplyAllMessage(messageView: MessageDetailView, message: Message) {
        actionTapped = ComposeView.ComposeMessageAction.ReplyAll
        self.performSegueWithIdentifier("toCompose", sender: self)
    }
    
    func messageDetailViewDidTapForwardMessage(messageView: MessageDetailView, message: Message) {
        actionTapped = ComposeView.ComposeMessageAction.Forward
        self.performSegueWithIdentifier("toCompose", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "toCompose") {
            let composeViewController = segue.destinationViewController.viewControllers!.first as! ComposeViewController
            composeViewController.message = message
            composeViewController.action = self.actionTapped
        }
    }
}