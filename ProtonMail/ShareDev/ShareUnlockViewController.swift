//
//  ShareUnlockViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/13/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import UIKit

class ShareUnlockViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(ShareViewController.cancelButtonTapped(sender:)))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.save, target: self, action: #selector(ShareViewController.saveButtonTapped(sender:)))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func saveButtonTapped(sender: UIBarButtonItem) {
        
        self.navigationController?.pushViewController(ShareViewController(), animated:true)
        
        //        self.hideExtensionWithCompletionHandler(completion: { (Bool) -> Void in
//            self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
//        })
    }
    
    func cancelButtonTapped(sender: UIBarButtonItem) {
        let dismiss: (() -> Void) = {
            self.hideExtensionWithCompletionHandler(completion: { (Bool) -> Void in
                let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
                self.extensionContext!.cancelRequest(withError: cancelError)
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

    func hideExtensionWithCompletionHandler(completion:@escaping (Bool) -> Void) {
        UIView.animate(withDuration: 0.50, animations: { () -> Void in
            self.navigationController!.view.transform = CGAffineTransform(translationX: 0, y: self.navigationController!.view.frame.size.height)
        },
                       completion: completion)
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
