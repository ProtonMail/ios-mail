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
    fileprivate var files = [FileData]()
    fileprivate let kDefaultAttachmentFileSize : Int = 25 * 1000 * 1000
    fileprivate var currentAttachmentSize : Int = 0
    
    //
    fileprivate lazy var documentAttachmentProvider = DocumentAttachmentProvider(for: self)
    fileprivate lazy var imageAttachmentProvider = PhotoAttachmentProvider(for: self)
    
    // pre - defined
    private let file_types : [String]  = [kUTTypeImage as String,
                                          kUTTypeMovie as String,
                                          kUTTypeVideo as String,
                                          kUTTypeFileURL as String,
                                          kUTTypeVCard as String]
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
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel,
                                                                target: self,
                                                                action: #selector(ShareUnlockViewController.cancelButtonTapped(sender:)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ActivityIndicatorHelper.showActivityIndicator(at: view)
        guard let inputitems = self.extensionContext?.inputItems as? [NSExtensionItem] else {
            self.showErrorAndQuit(errorMsg: LocalString._cant_load_share_content)
            return
        }
        
        let group = DispatchGroup()
        self.parse(items: inputitems, group: group)
        group.notify(queue: DispatchQueue.global(qos: .userInteractive)) { [unowned self] in
            DispatchQueue.main.async { [unowned self] in
                ActivityIndicatorHelper.hideActivityIndicator(at: self.view)
                //go to composer
                guard self.localized_errors.isEmpty else {
                    self.showErrorAndQuit(errorMsg: self.localized_errors.first ?? LocalString._cant_load_share_content)
                    return
                }
                
                self.loginCheck()
            }
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
                            self.loadItem(itemProvider, type: type) {
                                 group.leave() //#1
                            }
                        } else if itemProvider.hasItemConformingToTypeIdentifier(propertylist_ket) {
                            PMLog.D("1")
                        } else if itemProvider.hasItemConformingToTypeIdentifier(url_key) {
                            group.enter()//#2
                            itemProvider.loadItem(forTypeIdentifier: url_key, options: nil) { [unowned self] url, error in
                                defer {
                                    group.leave()//#2
                                }
                                if let shareURL = url as? NSURL {
                                    self.inputSubject = plainText ?? ""
                                    let url = shareURL.absoluteString ?? ""
                                    self.inputContent = self.inputContent + "\n" + "<a href=\"\(url)\">\(url)</a>"
                                } else {
                                    self.error(LocalString._cant_load_share_content)
                                }
                            }
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
        switch getViewFlow() {
        case .requirePin:
            sharedUserDataService.isSignedIn = false
            pinUnlock.alpha = 1.0
            pinUnlock.isEnabled = true
            if userCachedStatus.isTouchIDEnabled {
                touchID.alpha = 1.0
                touchID.isEnabled = true
            }

        case .requireTouchID:
            sharedUserDataService.isSignedIn = false
            touchID.alpha = 1.0
            touchID.isEnabled = true

        case .restore:
            self.signInIfRememberedCredentials()
        }
    }
    
    private func tryTouchID() {
        switch getViewFlow() {
        case .requireTouchID:
            self.authenticateUser()
        case .restore, .requirePin:
            break
        }
    }
    
    private func showErrorAndQuit(errorMsg : String) {
        self.touchID.alpha = 0.0
        self.pinUnlock.alpha = 0.0
        
        let alertController = UIAlertController(title: LocalString._share_alert, message: errorMsg, preferredStyle: .alert)
        let action = UIAlertAction(title: LocalString._general_close_action, style: .default) { action in
            self.hideExtensionWithCompletionHandler() { _ in
                let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
                self.extensionContext?.cancelRequest(withError: cancelError)
            }
        }
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delay(0.3) {
            self.tryTouchID()
        }
    }

    fileprivate func getViewFlow() -> SignInUIFlow {
        guard sharedTouchID.showTouchIDOrPin() else {
            return SignInUIFlow.restore
        }
        
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
    }
    
    func signInIfRememberedCredentials() {
        guard sharedUserDataService.isUserCredentialStored else {
            self.showErrorAndQuit(errorMsg: LocalString._please_use_protonmail_app_login_first)
            return
        }
        userCachedStatus.lockedApp = false
        sharedUserDataService.isSignedIn = true
        self.goto_composer()
    }
    
    func goto_composer() {
        let composer = ComposerViewController(nibName: "ComposerViewController", bundle: nil) //69 mb
        sharedVMService.buildComposer(composer,
                                      subject: self.inputSubject,
                                      content: self.inputContent,
                                      files: self.files)
        
        let w = UIScreen.main.bounds.width;
        composer.view.frame = CGRect(x: 0, y: 0, width: w, height: 186 + 60)
        self.navigationController?.setViewControllers([composer], animated: true) //71mb
    }
    
    func goto_pin() {
        pinUnlock.isEnabled = false
        let pinVC = SharePinUnlockViewController(nibName: "SharePinUnlockViewController", bundle: nil)
        pinVC.viewModel = ShareUnlockPinCodeModelImpl()
        pinVC.delegate = self
        let w = UIScreen.main.bounds.width;
        let h = UIScreen.main.bounds.height;
        pinVC.view.frame = CGRect(x: 0, y: 0, width: w, height: h)
        self.present(pinVC, animated: true, completion: nil)
    }
    
    @objc func cancelButtonTapped(sender: UIBarButtonItem) {
        self.hideExtensionWithCompletionHandler() { _ in
            let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
            self.extensionContext?.cancelRequest(withError: cancelError)
        }
    }
    
    @IBAction func touch_id_action(_ sender: Any) {
        self.authenticateUser()
    }
    
    @IBAction func pin_unlock_action(_ sender: Any) {
        self.goto_pin()
    }
    
    func authenticateUser() {
        let context = LAContext() // Get the local authentication context
        context.localizedFallbackTitle = ""
        let reasonString = "\(LocalString._general_login): \(userCachedStatus.codedEmail())"
        
        // Check if the device can evaluate the policy.
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            var alertString : String = "";
            // If the security policy cannot be evaluated then show a short message depending on the error
            switch error?.code {
            case .some(LAError.Code.touchIDNotEnrolled.rawValue):
                alertString = LocalString._general_touchid_not_enrolled
                
            case .some(LAError.Code.passcodeNotSet.rawValue):
                alertString = LocalString._general_passcode_not_set
                
            default: // The LAError.TouchIDNotAvailable case
                alertString = LocalString._general_touchid_not_available
            }
            
            PMLog.D(alertString)
            PMLog.D("\(String(describing: error?.localizedDescription))")
            let alertController = alertString.alertController()
            alertController.addOKAction()
            self.present(alertController, animated: true, completion: nil)
            
            return
        }
        
        let evaluationHandler: (Bool, Error?)->Void = { (success, evalPolicyError) in
            DispatchQueue.main.async {
                guard success else {
                    switch evalPolicyError?._code {
                    case .some(LAError.Code.systemCancel.rawValue):
                        let alertController = LocalString._authentication_was_cancelled_by_the_system.alertController()
                        alertController.addOKAction()
                        self.present(alertController, animated: true, completion: nil)
                        
                    case .some(LAError.Code.userCancel.rawValue):
                        PMLog.D("Authentication was cancelled by the user")
                        
                    case .some(LAError.Code.userFallback.rawValue):
                        PMLog.D("User selected to enter custom password")
                        
                    default:
                        PMLog.D("Authentication failed")
                        let alertController = LocalString._authentication_failed.alertController()
                        alertController.addOKAction()
                        self.present(alertController, animated: true, completion: nil)
                    }
                    return
                }
                self.signInIfRememberedCredentials()
            }
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString, reply: evaluationHandler)
        
    }
    
    func hideExtensionWithCompletionHandler(completion:@escaping (Bool) -> Void) {
        UIView.animate(withDuration: 0.50,
                       animations: {
                            if let view = self.navigationController?.view {
                                view.transform = CGAffineTransform(translationX: 0, y: view.frame.size.height)
                            }
                       },
                       completion: completion)
    }
    
    func configureNavigationBar() {
        if let bar = self.navigationController?.navigationBar {
            bar.barStyle = UIBarStyle.black
            bar.barTintColor = UIColor.ProtonMail.Nav_Bar_Background;
            bar.isTranslucent = false
            bar.tintColor = UIColor.white
            bar.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.white,
                NSAttributedString.Key.font: Fonts.h2.regular
            ]
        }
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

extension ShareUnlockViewController: AttachmentController {
    func error(_ description: String) {
        self.localized_errors.append(description)
    }
    
    func finish(_ fileData: FileData) {
        guard fileData.contents.dataSize < ( self.kDefaultAttachmentFileSize - self.currentAttachmentSize) else {
            self.error(LocalString._the_total_attachment_size_cant_be_bigger_than_25mb)
            return
        }

        self.files.append(fileData)
    }

    func loadItem(_ itemProvider: NSItemProvider, type: String, handler: @escaping ()->Void) {
        itemProvider.loadItem(forTypeIdentifier: type, options: nil) { item, error in // async
            defer {
                // important: whole this closure contents will be run synchronously, so we can call the handler in the end of scope
                // if this situation will change some day, handler should be passed over
                handler()
            }
            
            guard error == nil else {
                self.error(error?.localizedDescription ?? "")
                return
            }
        
            //TODO:: the process(XXX:) functions below. they could be abstracted out. all type of process in the same place.
            if let url = item as? URL {
                self.documentAttachmentProvider.process(fileAt: url) // sync
            } else if let img = item as? UIImage {
                self.imageAttachmentProvider.process(original: img) // sync
            } else if (type as CFString == kUTTypeVCard), let data = item as? Data {
                var fileName = "\(NSUUID().uuidString).vcf"
                if #available(iOSApplicationExtension 11.0, *), let name = itemProvider.suggestedName {
                    fileName = name
                }
                let fileData = ConcreteFileData<Data>(name: fileName, ext: "text/vcard", contents: data)
                self.finish(fileData)
            } else if let data = item as? Data {
                var fileName = NSUUID().uuidString
                if #available(iOSApplicationExtension 11.0, *), let name = itemProvider.suggestedName {
                    fileName = name
                }
                
                let type = (itemProvider.registeredTypeIdentifiers.first ?? type) as CFString
                // this method does not work correctly with "text/vcard" mime by some reson, so VCards have separate `else if`
                guard let filetype = UTTypeCopyPreferredTagWithClass(type, kUTTagClassFilenameExtension)?.takeRetainedValue() as String?,
                    let mimetype = UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType)?.takeRetainedValue() as String? else
                {
                    self.error(LocalString._failed_to_determine_file_type)
                    return
                }
                let fileData = ConcreteFileData<Data>(name: fileName + "." + filetype, ext: mimetype, contents: data)
                self.finish(fileData)
            } else {
                self.error(LocalString._unsupported_file)
            }
        }
    }
}

extension NSItemProvider {
    func hasItem(types: [String]) -> String? {
        return types.first(where: self.hasItemConformingToTypeIdentifier)
    }
}
