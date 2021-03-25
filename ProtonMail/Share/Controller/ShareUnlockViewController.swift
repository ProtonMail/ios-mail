//
//  ShareUnlockViewController.swift
//  Share - Created on 7/13/17.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import UIKit
import MBProgressHUD
import PromiseKit
import PMCommon

var sharedUserDataService : UserDataService!

class ShareUnlockViewController: UIViewController, CoordinatedNew, BioCodeViewDelegate {
    typealias coordinatorType = ShareUnlockCoordinator
    private weak var coordinator: ShareUnlockCoordinator?
    
    func set(coordinator: ShareUnlockCoordinator) {
        self.coordinator = coordinator
    }
    
    func getCoordinator() -> CoordinatorNew? {
        return coordinator
    }
    
    @IBOutlet weak var bioCodeView: BioCodeView!
    
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
        
        sharedUserDataService = UserDataService(api: PMAPIService.shared)
        LanguageManager.setupCurrentLanguage()
        configureNavigationBar()
        
        self.bioCodeView.delegate = self
        self.bioCodeView.setup()
        
        // Do any additional setup after loading the view.
        self.navigationItem.title = ""
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel,
                                                                target: self,
                                                                action: #selector(ShareUnlockViewController.cancelButtonTapped(sender:)))
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.didUnlock, object: nil, queue: .main) { [weak self] _ in
            self?.signInIfRememberedCredentials()
        }
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
                guard sharedServices.get(by: UsersManager.self).hasUsers() else {
                    self.showErrorAndQuit(errorMsg: LocalString._please_use_protonmail_app_login_first)
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
    
    // set up UI only
    internal func loginCheck() {
        let unlockManager = sharedServices.get(by: UnlockManager.self)
        switch unlockManager.getUnlockFlow() {
        case .requirePin:
            self.bioCodeView.loginCheck(.requirePin)

        case .requireTouchID:
            self.bioCodeView.loginCheck(.requireTouchID)
            self.authenticateUser()

        case .restore:
            unlockManager.initiateUnlock(flow: .restore, requestPin: { }, requestMailboxPassword: {})
        }
    }
    
    private func showErrorAndQuit(errorMsg : String) {
        self.bioCodeView.showErrorAndQuit(errorMsg: errorMsg)
        
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
    
    func signInIfRememberedCredentials() {
        self.coordinator?.go(dest: .composer)
    }
    
    @objc func cancelButtonTapped(sender: UIBarButtonItem) {
        self.hideExtensionWithCompletionHandler() { _ in
            let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
            self.extensionContext?.cancelRequest(withError: cancelError)
        }
    }
    
    func touch_id_action(_ sender: Any) {
        self.authenticateUser()
    }
    
    func pin_unlock_action(_ sender: Any) {
        self.coordinator?.go(dest: .pin)
    }
    
    func authenticateUser() {
        let unlockManager = sharedServices.get(by: UnlockManager.self)
        unlockManager.biometricAuthentication(afterBioAuthPassed: {
            unlockManager.unlockIfRememberedCredentials(requestMailboxPassword: { })
        })
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
    
    func fileSuccessfullyImported(as fileData: FileData) -> Promise<Void> {
        return Promise { seal in
            guard fileData.contents.dataSize < (self.kDefaultAttachmentFileSize - self.currentAttachmentSize) else {
                self.error(LocalString._the_total_attachment_size_cant_be_bigger_than_25mb)
                seal.fulfill_()
                return
            }

            self.files.append(fileData)
            seal.fulfill_()
        }
    }
}


