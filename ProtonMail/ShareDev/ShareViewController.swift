//
//  ShareViewController.swift
//  ShareDev
//
//  Created by Yanfeng Zhang on 6/28/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//
//
import UIKit

class ShareViewController : UIViewController {
    
//    fileprivate var doneButton: UIBarButtonItem!
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.view.backgroundColor = UIColor.white
//        
//        //configureNavigationBar()
//        
//        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: "cancelButtonTapped:")
//        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.save, target: self, action: "saveButtonTapped:")
//        
//        setNeedsStatusBarAppearanceUpdate()
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        self.navigationItem.title = "Share this"
        

        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(ShareViewController.cancelButtonTapped(sender:)))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.save, target: self, action: #selector(ShareViewController.saveButtonTapped(sender:)))
    }
    
    func saveButtonTapped(sender: UIBarButtonItem) {
        self.hideExtensionWithCompletionHandler(completion: { (Bool) -> Void in
            self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
        })
    }

    func cancelButtonTapped(sender: UIBarButtonItem) {
        let dismiss: (() -> Void) = {
            self.hideExtensionWithCompletionHandler(completion: { (Bool) -> Void in
                //self.extensionContext!.cancelRequest(withError: NSError())
            })
        }
        
        //if self.viewModel.hasDraft || composeView.hasContent || ((attachments?.count ?? 0) > 0) {
        let alertController = UIAlertController(title: "Confirmation", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Save draft", style: .default, handler: { (action) -> Void in
            //                self.stopAutoSave()
            //                self.collectDraft()
            //                self.viewModel.updateDraft()
            dismiss()
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Discard draft", style: .destructive, handler: { (action) -> Void in
            //                self.stopAutoSave()
            //                self.viewModel.deleteDraft()
            dismiss()
        }))
        
        alertController.popoverPresentationController?.barButtonItem = sender
        alertController.popoverPresentationController?.sourceRect = self.view.frame
        present(alertController, animated: true, completion: nil)
        
//        self.hideExtensionWithCompletionHandler(completion: { (Bool) -> Void in
//            //self.extensionContext?.cancelRequest(withError: )
//            //self.extensionContext!.cancelRequest(withError: NSError())
//        })
    }
    
//    @IBAction func cancelAction(_ sender: UIBarButtonItem) {

//
//    }
//    
//    @IBAction func sendAction(_ sender: UIBarButtonItem) {
//
//    }
//
//    @IBAction func test(_ sender: Any) {
//        
//        
//        
//    }
    
    func hideExtensionWithCompletionHandler(completion:@escaping (Bool) -> Void) {
        UIView.animate(withDuration: 0.50, animations: { () -> Void in
            self.navigationController!.view.transform = CGAffineTransform(translationX: 0, y: self.navigationController!.view.frame.size.height)
        },
                                   completion: completion)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // ******************
    
    func configureNavigationBar() {
        self.navigationController?.navigationBar.barStyle = UIBarStyle.black
       // self.navigationController?.navigationBar.barTintColor = UIColor.ProtonMail.Nav_Bar_Background;
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
       // let navigationBarTitleFont = UIFont.robotoLight(size: UIFont.Size.h2)
//        self.navigationController?.navigationBar.titleTextAttributes = [
//            NSForegroundColorAttributeName: UIColor.whiteColor(),
//            NSFontAttributeName: navigationBarTitleFont
//        ]
    }
    
}
