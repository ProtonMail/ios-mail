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
import CoreData


//NOTE:: Not in use
class MessageDetailViewController: ProtonMailViewController {
    
    var message: Message! {
        didSet {
            message.fetchDetailIfNeeded() { _, _, msg, error in
                PMLog.D(self.message.isDetailDownloaded)
                //println(self.message.body)
                PMLog.D(self.message.ccList)
                NSLog("\(__FUNCTION__) error: \(self.message)")
                if error != nil {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
                else
                {
                    self.messageDetailView?.updateHeaderView()
                    self.messageDetailView?.updateEmailBodyWebView(true)
                    self.messageDetailView?.layoutIfNeeded()
                }
            }
        }
    }
    
    private var actionTapped: ComposeMessageAction!
    private var fetchedMessageController: NSFetchedResultsController?
    
    @IBOutlet var messageDetailView: MessageDetailView!
    
    override func loadView() {
        messageDetailView = MessageDetailView(message: message, delegate: self)
        self.view = messageDetailView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupRightButtons()
        setupFetchedResultsController(message.messageID)
    }
    
    private func setupFetchedResultsController(msg_id:String) {
        
        PMLog.D(msg_id);
        self.fetchedMessageController = sharedMessageDataService.fetchedMessageControllerForID(msg_id)

        
        NSLog("\(__FUNCTION__) INFO: \(fetchedMessageController?.sections)")
        
        if let fetchedMessageController = fetchedMessageController {
           // var error: NSError?
            do {
               try fetchedMessageController.performFetch()
            } catch {
                
            }
            
//            if !fetchedMessageController.performFetch(&error) {
//                NSLog("\(__FUNCTION__) error: \(error)")
//            }
        }
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
        //TODO :: all the changes for message need check is the message deleted
        message.isRead = true
        message.needsUpdate = true
        if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
        }
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
        message.needsUpdate = true

        if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
        }

        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func spamButtonTapped() {
        message.location = .spam
        message.needsUpdate = true
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
        message.needsUpdate = true
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
                message.needsUpdate = true
                if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
                
                self.navigationController?.popViewControllerAnimated(true)
            }))
        }
        
        if message.location != .spam {
            alertController.addAction(UIAlertAction(title: MessageLocation.spam.description, style: .Default, handler: { (action) -> Void in
                message.location = .spam
                message.needsUpdate = true
                if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
                
                self.navigationController?.popViewControllerAnimated(true)
            }))
        }
        
        if message.location != .trash {
            alertController.addAction(UIAlertAction(title: MessageLocation.trash.description, style: .Destructive, handler: { (action) -> Void in
                message.location = .trash
                message.needsUpdate = true
                if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
                
                self.navigationController?.popViewControllerAnimated(true)
            }))
        }
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = self.view.frame
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func messageDetailViewDidTapReplyMessage(messageView: MessageDetailView, message: Message) {
        actionTapped = ComposeMessageAction.Reply
        self.performSegueWithIdentifier("test_details_segue", sender: self)
        //self.performSegueWithIdentifier("toCompose", sender: self)
    }
    
    func messageDetailViewDidTapReplyAllMessage(messageView: MessageDetailView, message: Message) {
        actionTapped = ComposeMessageAction.ReplyAll
        self.performSegueWithIdentifier("toCompose", sender: self)
    }
    
    func messageDetailViewDidTapForwardMessage(messageView: MessageDetailView, message: Message) {
        actionTapped = ComposeMessageAction.Forward
        self.performSegueWithIdentifier("toCompose", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "toCompose") {
            let composeViewController = segue.destinationViewController as! ComposeViewController
            composeViewController.viewModel = ComposeViewModelImpl(msg: message, action: self.actionTapped)
        } else if segue.identifier == "test_details_segue" {
            let messageDetailViewController: MessageViewController = segue.destinationViewController as! MessageViewController
            messageDetailViewController.message = message;
        }
    }
}