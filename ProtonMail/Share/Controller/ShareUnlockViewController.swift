//
//  ShareUnlockViewController.swift
//  Share - Created on 7/13/17.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import UIKit
import MBProgressHUD

var sharedUserDataService : UserDataService!

class ShareUnlockViewController: UIViewController, CoordinatedNew {
    typealias coordinatorType = ShareUnlockCoordinator
    private weak var coordinator: ShareUnlockCoordinator?
    
    func set(coordinator: ShareUnlockCoordinator) {
        self.coordinator = coordinator
    }
    
    func getCoordinator() -> CoordinatorNew? {
        return coordinator
    }
    
    @IBOutlet weak var pinUnlock: UIButton!
    @IBOutlet weak var touchID: UIButton!
    
    //
    var inputSubject : String! = ""
    var inputContent : String! = ""
    fileprivate var inputAttachments : String! = ""
    var files = [FileData]()
    fileprivate let kDefaultAttachmentFileSize : Int = 25 * 1000 * 1000
    fileprivate var currentAttachmentSize : Int = 0
    
    //
    internal lazy var documentAttachmentProvider = DocumentAttachmentProvider(for: self)
    internal lazy var imageAttachmentProvider = PhotoAttachmentProvider(for: self)
    
    // pre - defined
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
        MBProgressHUD.showAdded(to: view, animated: true)
        guard let inputitems = self.extensionContext?.inputItems as? [NSExtensionItem] else {
            self.showErrorAndQuit(errorMsg: LocalString._cant_load_share_content)
            return
        }
        
        let group = DispatchGroup()
        self.parse(items: inputitems, group: group)
        group.notify(queue: DispatchQueue.global(qos: .userInteractive)) { [unowned self] in
            DispatchQueue.main.async { [unowned self] in
                MBProgressHUD.hide(for: self.view, animated: true)
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
                    let itemProvider = att
                    if let type = itemProvider.hasItem(types: self.filetypes) {
                        group.enter() //#1
                        self.importFile(itemProvider, type: type, errorHandler: self.error) {
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
    
    internal func loginCheck() {
        switch getViewFlow() {
        case .requirePin:
            pinUnlock.alpha = 1.0
            pinUnlock.isEnabled = true
            if userCachedStatus.isTouchIDEnabled {
                touchID.alpha = 1.0
                touchID.isEnabled = true
            }

        case .requireTouchID:
            touchID.alpha = 1.0
            touchID.isEnabled = true
            self.authenticateUser()

        case .restore:
            self.signInIfRememberedCredentials()
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

    fileprivate func getViewFlow() -> SignInUIFlow {
        return UnlockManager.shared.getUnlockFlow()
    }
    
    func signInIfRememberedCredentials() {
        guard SignInManager.shared.isSignedIn(), UnlockManager.shared.isUnlocked() else {
            self.showErrorAndQuit(errorMsg: LocalString._please_use_protonmail_app_login_first)
            return
        }
        
        self.coordinator?.go(dest: .composer)
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
        self.coordinator?.go(dest: .pin)
    }
    
    func authenticateUser() {
        UnlockManager.shared.biometricAuthentication(afterBioAuthPassed: { self.coordinator?.go(dest: .composer) })
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

extension ShareUnlockViewController: AttachmentController, FileImporter {
    var barItem: UIBarButtonItem? {
        return nil
    }
    
    func error(_ description: String) {
        self.localized_errors.append(description)
    }
    
    func fileSuccessfullyImported(as fileData: FileData) {
        guard fileData.contents.dataSize < (self.kDefaultAttachmentFileSize - self.currentAttachmentSize) else {
            self.error(LocalString._the_total_attachment_size_cant_be_bigger_than_25mb)
            return
        }

        self.files.append(fileData)
    }

    
}


