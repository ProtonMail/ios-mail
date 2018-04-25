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
    
    
    // pre - defined
    private let file_types : [String]  = [kUTTypeImage as String,
                                          kUTTypeMovie as String,
                                          kUTTypeVideo as String,
                                          kUTTypeFileURL as String]
    private let propertylist_ket = kUTTypePropertyList as String
    private let url_key = kUTTypeURL as String
    
    private var localized_errors: [String] = []
    
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
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel,
                                                                target: self,
                                                                action: #selector(ShareUnlockViewController.cancelButtonTapped(sender:)))
        
        ActivityIndicatorHelper.showActivityIndicator(at: view)
        if let inputitems = self.extensionContext?.inputItems as? [NSExtensionItem] {
            let group = DispatchGroup()
            self.parse(items: inputitems, group: group)
            group.notify(queue: .main) {
                ActivityIndicatorHelper.hideActivityIndicator(at: self.view)
                DispatchQueue.main.async {
                    //go to composer
                    if self.localized_errors.isEmpty {
                        self.loginCheck()
                    } else {
                        if let e = self.localized_errors.first {
                            self.showErrorAndQuit(errorMsg: e)
                        } else {
                            self.showErrorAndQuit(errorMsg: NSLocalizedString("Can't load share content!", comment: "Description"))
                        }
                    }
                }
            }
        } else {
            self.showErrorAndQuit(errorMsg: NSLocalizedString("Can't load share content!", comment: "Description"))
        }
    }
    
    private func parse(items: [NSExtensionItem], group: DispatchGroup) {
        defer {
            group.leave()//#0
        }
        PMLog.D("\(items)")
        group.enter() //#0
        for item in items {
            let plainText = item.attributedContentText?.string
            if let attachments = item.attachments {
                for att in attachments {
                    if let itemProvider = att as? NSItemProvider {
                        if let type = itemProvider.hasItem(types: file_types) {
                            group.enter() //#1
                            itemProvider.loadItem(type: type, handler: { (fileData : FileData?, error : NSError?) in
                                defer {
                                     group.leave() //#1
                                }
                                
                                if let data = fileData {
                                    let length = fileData!.data.count
                                    if length <= ( self.kDefaultAttachmentFileSize - self.currentAttachmentSize ) {
                                        self.files.append(fileData!)
                                    } else {
                                        self.localized_errors.append(NSLocalizedString("The total attachment size can't be bigger than 25MB", comment: "Description"))
                                    }
                                } else if let err = error {
                                    self.localized_errors.append(NSLocalizedString("Can't load share content!", comment: "Description"))
                                }
                            })
                        } else if itemProvider.hasItemConformingToTypeIdentifier(propertylist_ket) {
                            PMLog.D("1")
                        } else if itemProvider.hasItemConformingToTypeIdentifier(url_key) {
                            group.enter()//#2
                            itemProvider.loadItem(forTypeIdentifier: url_key, options: nil, completionHandler: { (url, error) -> Void in
                                defer {
                                    group.leave()//#2
                                }
                                if let shareURL = url as? NSURL {
                                    self.inputSubject = plainText ?? ""
                                    let url = shareURL.absoluteString ?? ""
                                    self.inputContent = self.inputContent + "\n" + "<a href=\"\(url)\">\(url)</a>"
                                } else {
                                    self.localized_errors.append(NSLocalizedString("Can't load share content!", comment: "Description"))
                                }
                            })
                        } else if let pt = plainText {
                            self.inputSubject = ""
                            self.inputContent = self.inputContent + "\n"  + pt
                        } else {
                            PMLog.D("4")
                        }
                    }
                }
            }
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
        alertController.addAction(UIAlertAction(title: LocalString._general_close_action, style: .default, handler: { (action) -> Void in
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
        delay(0.3, closure: {
            self.tryTouchID()
        })
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
        
        sharedVMService.buildComposer(composer,
                                      subject: self.inputSubject,
                                      content: self.inputContent,
                                      files: self.files)
        
//        sharedVMService.newShareDraftViewModel(composer,
//                                               subject: self.inputSubject,
//                                               content: self.inputContent,
//                                               files: self.files)
        
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
    
    @objc func cancelButtonTapped(sender: UIBarButtonItem) {
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
        let savedEmail = userCachedStatus.codedEmail()
        // Get the local authentication context.
        let context = LAContext()
        // Declare a NSError variable.
        var error: NSError?
        context.localizedFallbackTitle = ""
        // Set the reason string that will appear on the authentication alert.
        let reasonString = "\(LocalString._general_login): \(savedEmail)"
        
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
                        switch evalPolicyError!._code {
                        case LAError.Code.systemCancel.rawValue:
                            let alertController = LocalString._authentication_was_cancelled_by_the_system.alertController()
                            alertController.addOKAction()
                            self.present(alertController, animated: true, completion: nil)
                        case LAError.Code.userCancel.rawValue:
                            PMLog.D("Authentication was cancelled by the user")
                        case LAError.Code.userFallback.rawValue:
                            PMLog.D("User selected to enter custom password")
                        default:
                            PMLog.D("Authentication failed")
                            let alertController = LocalString._authentication_failed.alertController()
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
                alertString = LocalString._general_touchid_not_enrolled
            case LAError.Code.passcodeNotSet.rawValue:
                alertString = LocalString._general_passcode_not_set
            default:
                // The LAError.TouchIDNotAvailable case.
                alertString = LocalString._general_touchid_not_available
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
        
        let navigationBarTitleFont = Fonts.h2.regular
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
    
    func hasItem(types: [String]) -> String? {
        for type in types {
            if self.hasItemConformingToTypeIdentifier(type) {
                return type
            }
        }
        return nil
    }
    
    
    func loadItem(type : String, handler : @escaping LoadComplete) {
        self.loadItem(forTypeIdentifier: type, options: nil) { data, error in
            if error != nil {
                handler(nil, NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil))
            } else if let url = data as? URL {
                let coordinator : NSFileCoordinator = NSFileCoordinator(filePresenter: nil)
                var error : NSError?
                coordinator.coordinate(readingItemAt: url, options: NSFileCoordinator.ReadingOptions(), error: &error) { (new_url) -> Void in
                    do {
                        let data = try Data(contentsOf: url)
                        DispatchQueue.main.async {
                            let ext = url.mimeType()
                            let fileName = url.lastPathComponent
                            let filedata = FileData(name: fileName, ext: ext, data: data)
                            handler(filedata, nil)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            handler(nil, NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil))
                        }
                    }
                }
            } else if let img = data as? UIImage {
                let fileName = "\(NSUUID().uuidString).PNG"
                let ext = "image/png"
                if let fileData = UIImagePNGRepresentation(img) {
                    DispatchQueue.main.async {
                        let filedata = FileData(name: fileName, ext: ext, data: fileData)
                        handler(filedata, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        handler(nil, NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil))
                    }
                }
            } else {
                DispatchQueue.main.async {
                    handler(nil, NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil))
                }
            }
        }
    }
}
