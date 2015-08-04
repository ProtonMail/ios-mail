//
//  HtmlEditorViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/21/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

protocol HtmlEditorViewControllerDelegate {
    func editorSizeChanged(size: CGSize)
    func editorCaretPosition ( position : Int)
}

class HtmlEditorViewController: ZSSRichTextEditor {
    var delegate: HtmlEditorViewControllerDelegate?
    var emailHeader : UIView!
    var webView : UIWebView!
    private var composeView : ComposeViewN!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.baseURL = NSURL( fileURLWithPath: "https://protonmail.ch")
        
        self.webView = self.getWebView()
        self.emailHeader = UIView()
        self.emailHeader.backgroundColor = UIColor.yellowColor()
        self.webView.scrollView.addSubview(self.emailHeader)
        let w = UIScreen.mainScreen().applicationFrame.width;
        self.emailHeader.frame = CGRect(x: 0, y: 0, width: w, height: 100)
        updateContentLayout(false)
        
        webView.scrollView.scrollsToTop = true;

        configureNavigationBar()
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "statusBarHit:", name: "touchStatusBarClick", object:nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "touchStatusBarClick", object:nil)
    }
    
    internal func statusBarHit (notify: NSNotification) {
        webView.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func configureNavigationBar() {
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.barTintColor = UIColor.ProtonMail.Blue_475F77
        self.navigationController?.navigationBar.translucent = false
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        let navigationBarTitleFont = UIFont.robotoLight(size: UIFont.Size.h2)
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSFontAttributeName: navigationBarTitleFont
        ]
    }
    
    func setBody (body : String ) {
        self.setHTML(body)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func editorDidScrollWithPosition(position: Int) {
        super.editorDidScrollWithPosition(position)
        
        //let new_position = self.getCaretPosition().toInt() ?? 0
        
        //self.delegate?.editorSizeChanged(self.getContentSize())
        
        //self.delegate?.editorCaretPosition(new_position)
    }
    
    private func updateContentLayout(animation: Bool) {
        UIView.animateWithDuration(animation ? 0.3 : 0, animations: { () -> Void in
            for subview in self.webView.scrollView.subviews {
                let sub = subview as! UIView
                if sub == self.emailHeader {
                    continue
                } else if subview is UIImageView {
                    continue
                } else {

                    let h : CGFloat = 100
                    sub.frame = CGRect(x: sub.frame.origin.x, y: h, width: sub.frame.width, height: sub.frame.height);
                }
            }
        })
    }

    
    @IBAction func send_clicked(sender: AnyObject) {
        
    }
    
    @IBAction func cancel_clicked(sender: AnyObject) {
        
        let dismiss: (() -> Void) = {
           // if self.viewModel.messageAction == ComposeMessageAction.OpenDraft {
                self.navigationController?.popViewControllerAnimated(true)
           // } else {
                self.dismissViewControllerAnimated(true, completion: nil)
           // }
        }
        
//        if self.viewModel.hasDraft || composeView.hasContent || ((attachments?.count ?? 0) > 0) {
//            let alertController = UIAlertController(title: NSLocalizedString("Confirmation"), message: nil, preferredStyle: .ActionSheet)
//            alertController.addAction(UIAlertAction(title: NSLocalizedString("Save draft"), style: .Default, handler: { (action) -> Void in
//                self.stopAutoSave()
//                self.collectDraft()
//                self.viewModel.updateDraft()
//                dismiss()
//            }))
//            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .Cancel, handler: nil))
//            alertController.addAction(UIAlertAction(title: NSLocalizedString("Discard draft"), style: .Destructive, handler: { (action) -> Void in
//                self.stopAutoSave()
//                self.viewModel.deleteDraft()
//                dismiss()
//            }))
//            
//            presentViewController(alertController, animated: true, completion: nil)
//        } else {
            dismiss()
//        }

    }
}
