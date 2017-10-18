//
//  ShareUnlockViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/13/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//
import UIKit
import LocalAuthentication

var sharedUserDataService : UserDataService!

class ShareUnlockViewController: UIViewController {
    @IBOutlet weak var pinUnlock: UIButton!
    @IBOutlet weak var touchID: UIButton!
    
    //
    fileprivate var inputSubject : String! = ""
    fileprivate var inputContent : String! = ""
    fileprivate var inputAttachments : String! = ""
    fileprivate var files: [FileData] = []
    fileprivate let kDefaultAttachmentFileSize : Int = 25 * 1000 * 1000
    fileprivate var currentAttachmentSize : Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sharedUserDataService = UserDataService()
        
        LanguageManager.setupCurrentLanguage()
        
        configureNavigationBar()
        
        pinUnlock.alpha = 0.0
        touchID.alpha = 0.0
        
        pinUnlock.isEnabled = false
        touchID.isEnabled = false
        
        touchID.layer.cornerRadius = 25
        
        // Do any additional setup after loading the view.
        self.navigationItem.title = ""
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(ComposerViewController.cancelButtonTapped(sender:)))
        
        ActivityIndicatorHelper.showActivityIndicatorAtView(view)
        
        var is_inputs_error : Bool = true
        //this part need move to a seperate function
        if let inputitems = self.extensionContext?.inputItems as? [NSExtensionItem] {
            PMLog.D("\(inputitems)")
            for item in inputitems {
                let plainText = item.attributedContentText?.string
                if let attachments = item.attachments {
                    for att in attachments {
                        if let itemProvider = att as? NSItemProvider {
                            
                            let propertylist_ket = kUTTypePropertyList as String
                            let url_key = kUTTypeURL as String
                            
                            let file_types : [String] = [kUTTypeImage as String,
                                                         kUTTypeMovie as String,
                                                         kUTTypeVideo as String,
                                                         kUTTypeFileURL as String]
                            
                            if  itemProvider.loadItem(types: file_types,  handler: { (fileData : FileData?, error : NSError?) in
                                ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
                                
                                if error != nil || fileData == nil {
                                    self.showErrorAndQuit(errorMsg: NSLocalizedString("Can't load share content!", comment: "Description"))
                                } else {
                                    let length = fileData!.data.count
                                    if length <= ( self.kDefaultAttachmentFileSize - self.currentAttachmentSize ) {
                                        self.files.append(fileData!)
                                        self.loginCheck()
                                    } else {
                                        self.showErrorAndQuit(errorMsg: NSLocalizedString("The total attachment size can't be bigger than 25MB", comment: "Description"))
                                    }
                                }
                                
                            }) {
                                is_inputs_error = false
                            } else if itemProvider.hasItemConformingToTypeIdentifier(propertylist_ket) {
                                //is_inputs_error = false
                                PMLog.D("1")
                                break
                                //                        [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypePropertyList
                                //                            options:nil
                                //                            completionHandler:^(NSDictionary *item, NSError *error) {
                                //                            // If it's a "webpage". This type seems to be mostly shared by Safari.
                                //                            // We can run custom JS if it's a webpage, so get more info that way
                                //                            // e.g. page title, currently selected text, etc.
                                //                            NSDictionary *results = [item objectForKey:NSExtensionJavaScriptPreprocessingResultsKey];
                                //                            // Probably don't need sharedPlainText here since we can get
                                //                            // lots of info from the page itself
                                //                            }];
                            } else if itemProvider.hasItemConformingToTypeIdentifier(url_key) {
                                is_inputs_error = false
                                itemProvider.loadItem(forTypeIdentifier: url_key, options: nil, completionHandler: { (url, error) -> Void in
                                    
                                    {
                                        ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
                                        if let shareURL = url as? NSURL {
                                            self.inputSubject = plainText ?? ""
                                            let url = shareURL.absoluteString ?? ""
                                            self.inputContent = "<a href=\"\(url)\">\(url)</a>"
                                            self.loginCheck()
                                            
                                        } else {
                                            self.showErrorAndQuit(errorMsg: NSLocalizedString("Can't load share content!", comment: "Description"))
                                        }
                                        
                                    } ~> .main
                                    
                                })
                            } else if let pt = plainText {
                                is_inputs_error = false
                                inputSubject = ""
                                inputContent = pt
                                
                                ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
                                self.loginCheck()
                                
                            } else {
                                PMLog.D("4")
                                break
                                // Or maybe there's nothing at all <flanders.gif>
                                // Not sure why this would happen, might be a beta bug.
                                // I managed to get it when sharing the calendar event from apple.com/live :/
                            }
                        }
                    }
                    
                }
            }
        }
        
        if is_inputs_error {
            self.showErrorAndQuit(errorMsg: NSLocalizedString("Can't load share content!", comment: "Description"))
        }
    }
    
    private func loginCheck() {
        let signinFlow = getViewFlow()
        switch signinFlow {
        case .requirePin:
            sharedUserDataService.isSignedIn = false
            pinUnlock.alpha = 1.0
            pinUnlock.isEnabled = true
            if userCachedStatus.isTouchIDEnabled {
                touchID.alpha = 1.0
                touchID.isEnabled = true
            }
            break
        case .requireTouchID:
            sharedUserDataService.isSignedIn = false
            touchID.alpha = 1.0
            touchID.isEnabled = true
            DispatchQueue.main.async {
                self.authenticateUser()
            }
            break
        case .restore:
            self.signInIfRememberedCredentials()
            break
        }
    }
    
    private func tryTouchID() {
        let signinFlow = getViewFlow()
        switch signinFlow {
        case .requirePin:
            break
        case .requireTouchID:
            self.authenticateUser()
            break
        case .restore:
            break
        }
    }
    
    private func showErrorAndQuit(errorMsg : String) {
        self.touchID.alpha = 0.0
        self.pinUnlock.alpha = 0.0
        
        let alertController = UIAlertController(title: NSLocalizedString("Share Alert", comment: "Title"), message: errorMsg, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Close", comment: "Action"), style: .default, handler: { (action) -> Void in
            self.hideExtensionWithCompletionHandler(completion: { (Bool) -> Void in
                let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
                self.extensionContext!.cancelRequest(withError: cancelError)
            })
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
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
    
    func signInIfRememberedCredentials() {
        if sharedUserDataService.isUserCredentialStored {
            userCachedStatus.lockedApp = false
            sharedUserDataService.isSignedIn = true
            if let addresses = sharedUserDataService.userInfo?.userAddresses.toPMNAddresses() {
                sharedOpenPGP.setAddresses(addresses);
            }
            self.goto_composer()
        }
        else
        {
             self.showErrorAndQuit(errorMsg: NSLocalizedString("Please use ProtonMail App login first", comment: "Description"))
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func goto_composer() {
        let composer = ComposerViewController(nibName: "ComposerViewController", bundle: nil)
        //TODO:: here need to setup the composer with input items
        sharedVMService.newShareDraftViewModel(composer,
                                               subject: self.inputSubject,
                                               content: self.inputContent,
                                               files: self.files)
        let w = UIScreen.main.applicationFrame.width;
        composer.view.frame = CGRect(x: 0, y: 0, width: w, height: 186 + 60)
        self.navigationController?.pushViewController(composer, animated:true)
    }
    
    func goto_pin() {
        pinUnlock.isEnabled = false
        let pinVC = SharePinUnlockViewController(nibName: "SharePinUnlockViewController", bundle: nil)
        pinVC.viewModel = ShareUnlockPinCodeModelImpl()
        pinVC.delegate = self
        let w = UIScreen.main.applicationFrame.width;
        let h = UIScreen.main.applicationFrame.height;
        pinVC.view.frame = CGRect(x: 0, y: 0, width: w, height: h)
        self.present(pinVC, animated: true, completion: nil)
    }
    
    func cancelButtonTapped(sender: UIBarButtonItem) {
        self.hideExtensionWithCompletionHandler(completion: { (Bool) -> Void in
            let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
            self.extensionContext!.cancelRequest(withError: cancelError)
        })
    }
    
    @IBAction func touch_id_action(_ sender: Any) {
        self.authenticateUser()
    }
    
    @IBAction func pin_unlock_action(_ sender: Any) {
        self.goto_pin()
    }
    
    func authenticateUser() {
        let savedEmail = userCachedStatus.touchIDEmail
        // Get the local authentication context.
        let context = LAContext()
        // Declare a NSError variable.
        var error: NSError?
        context.localizedFallbackTitle = ""
        // Set the reason string that will appear on the authentication alert.
        let reasonString = "\(NSLocalizedString("Login", comment: "")): \(savedEmail)"
        
        // Check if the device can evaluate the policy.
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString, reply: { (success: Bool, evalPolicyError: Error?) in
                if success {
                    DispatchQueue.main.async {
                        self.signInIfRememberedCredentials()
                    }
                }
                else{
                    DispatchQueue.main.async {
                        PMLog.D("\(String(describing: evalPolicyError?.localizedDescription))")
                        switch evalPolicyError!._code {
                        case LAError.Code.systemCancel.rawValue:
                            PMLog.D("Authentication was cancelled by the system")
                            let alertController = NSLocalizedString("Authentication was cancelled by the system", comment: "Description").alertController()
                            alertController.addOKAction()
                            self.present(alertController, animated: true, completion: nil)
                        case LAError.Code.userCancel.rawValue:
                            PMLog.D("Authentication was cancelled by the user")
                            let alertController = NSLocalizedString("Authentication was cancelled by the user", comment: "Description").alertController()
                            alertController.addOKAction()
                            self.present(alertController, animated: true, completion: nil)
                        case LAError.Code.userFallback.rawValue:
                            PMLog.D("User selected to enter custom password")
                            let alertController = NSLocalizedString("Authentication failed", comment: "Description").alertController()
                            alertController.addOKAction()
                            self.present(alertController, animated: true, completion: nil)
                        default:
                            PMLog.D("Authentication failed")
                            let alertController = NSLocalizedString("Authentication failed", comment: "Description").alertController()
                            alertController.addOKAction()
                            self.present(alertController, animated: true, completion: nil)
                        }
                        
                    }
                }
            })
        }
        else{
            var alertString : String = "";
            // If the security policy cannot be evaluated then show a short message depending on the error.
            switch error!.code{
            case LAError.Code.touchIDNotEnrolled.rawValue:
                alertString = NSLocalizedString("TouchID is not enrolled, enable it in the system Settings", comment: "Description")
            case LAError.Code.passcodeNotSet.rawValue:
                alertString = NSLocalizedString("A passcode has not been set, enable it in the system Settings", comment: "Description")
            default:
                // The LAError.TouchIDNotAvailable case.
                alertString = NSLocalizedString("TouchID not available", comment: "Description")
            }
            PMLog.D(alertString)
            PMLog.D("\(String(describing: error?.localizedDescription))")
            let alertController = alertString.alertController()
            alertController.addOKAction()
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func hideExtensionWithCompletionHandler(completion:@escaping (Bool) -> Void) {
        UIView.animate(withDuration: 0.50, animations: { () -> Void in
            self.navigationController!.view.transform = CGAffineTransform(translationX: 0, y: self.navigationController!.view.frame.size.height)
        }, completion: completion)
    }
    
    func configureNavigationBar() {
        self.navigationController?.navigationBar.barStyle = UIBarStyle.black
        self.navigationController?.navigationBar.barTintColor = UIColor.ProtonMail.Nav_Bar_Background;
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        let navigationBarTitleFont = UIFont.systemFont(ofSize: UIFont.Size.h2)
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.font: navigationBarTitleFont
        ]
    }
}

extension ShareUnlockViewController : SharePinUnlockViewControllerDelegate {
    func Cancel() {
        pinUnlock.isEnabled = true
        //UserTempCachedStatus.backup()
    }
    
    func Next() {
        self.signInIfRememberedCredentials()
    }
    
    func Failed() {
        //clean and show error
    }
}

typealias LoadComplete = (_ attachment: FileData?, _ error: NSError?) -> Void

extension NSItemProvider {
    func loadItem(types : [String], handler : @escaping LoadComplete) -> Bool {
        for type in types {
            if self.hasItemConformingToTypeIdentifier(type) {
                PMLog.D(type)
                self.loadItem(forTypeIdentifier: type, options: nil) { data, error in
                    if error != nil {
                        handler(nil, NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil))
                        print("Unable to add as a URL")
                    } else if let url = data as? URL {
                        let coordinator : NSFileCoordinator = NSFileCoordinator(filePresenter: nil)
                        var error : NSError?
                        coordinator.coordinate(readingItemAt: url, options: NSFileCoordinator.ReadingOptions(), error: &error) { (new_url) -> Void in
                            if let data = try? Data(contentsOf: url) {
                                DispatchQueue.main.async {
                                    //if data.count <= ( self.kDefaultAttachmentFileSize - self.currentAttachmentSize ) {
                                    let ext = url.mimeType()
                                    let fileName = url.lastPathComponent
                                    let filedata = FileData(name: fileName, ext: ext, data: data)
                                    handler(filedata, nil)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    handler(nil, NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil))
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            handler(nil, NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil))
                            print("Unexpected data:", Swift.type(of: data))
                        }
                    }
                }
                return true
            }
        }
        return false
    }
}
