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
        self.navigationItem.title = "This is a Unlock PIN View"
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(ComposerViewController.cancelButtonTapped(sender:)))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.save, target: self, action: #selector(ComposerViewController.saveButtonTapped(sender:)))
        
        ///

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                PMLog.D( NSLocalizedString("v", comment: "versions first character ") + version + "(\(build))" )
            } else {
                PMLog.D(  NSLocalizedString("v", comment: "versions first character ") + version )
            }
        } else {
             PMLog.D( "Can't find the version" )
        }

        
        let signinFlow = getViewFlow()
        switch signinFlow {
        case .requirePin:
            sharedUserDataService.isSignedIn = false
//            self.performSegue(withIdentifier: kSegueToPinCodeViewNoAnimation, sender: self)
            break
        case .requireTouchID:
            sharedUserDataService.isSignedIn = false
//            showTouchID(false)
//            authenticateUser()
            break
        case .restore:
//            signInIfRememberedCredentials()
//            setupView();
            break
        }
        
    }
    
    fileprivate func getViewFlow() -> SignInUIFlow {
        if sharedTouchID.showTouchIDOrPin() {
            if userCachedStatus.isPinCodeEnabled && !userCachedStatus.pinCode.isEmpty {
                self.view.backgroundColor = UIColor.red
                return SignInUIFlow.requirePin
            } else {
                //check touch id status
                if (!userCachedStatus.touchIDEmail.isEmpty && userCachedStatus.isTouchIDEnabled) {
                    return SignInUIFlow.requireTouchID
                } else {
                    return SignInUIFlow.restore
                }
            }
        } else {
            return SignInUIFlow.restore
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func saveButtonTapped(sender: UIBarButtonItem) {
        let composer = ComposerViewController(nibName: "ComposerViewController", bundle: nil)
        sharedVMService.newDraftViewModel(composer)
        let w = UIScreen.main.applicationFrame.width;
        composer.view.frame = CGRect(x: 0, y: 0, width: w, height: 186 + 60)
        
        self.navigationController?.pushViewController(composer, animated:true)
        
    }
    
    func cancelButtonTapped(sender: UIBarButtonItem) {
        self.hideExtensionWithCompletionHandler(completion: { (Bool) -> Void in
            let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
            self.extensionContext!.cancelRequest(withError: cancelError)
        })
    }

    func hideExtensionWithCompletionHandler(completion:@escaping (Bool) -> Void) {
        UIView.animate(withDuration: 0.50, animations: { () -> Void in
            self.navigationController!.view.transform = CGAffineTransform(translationX: 0, y: self.navigationController!.view.frame.size.height)
        }, completion: completion)
    }
}
