//
//  ViewModelServiceImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import UICKeyChainStore

//keep this unique
let sharedVMService : ViewModelServiceImpl = ViewModelServiceImpl()
class ViewModelServiceImpl: ViewModelService {
    //the active view controller needs to be reset when resetComposerView be called
    private var activeViewController : ViewModelProtocol?
    //the active mailbox
    private var mailboxViewController : ViewModelProtocol?
    
    //new one
    private var activeViewControllerNew : ViewModelProtocolBase?
    
    private func setup(composer vmp: ViewModelProtocolBase, viewModel: ComposeViewModel) {
        vmp.setModel(vm: viewModel)
        self.activeViewControllerNew = vmp
    }
    
    override func signOut() {
        self.resetView()
    }
    
    override func changeIndex() {
        
    }
    
    override func resetView() {
        if activeViewController != nil {
            DispatchQueue.main.async {
                self.activeViewController?.inactiveViewModel()
                self.activeViewController = nil
            }
        }
        DispatchQueue.main.async {
            if let actived  = self.activeViewControllerNew {
                actived.inactiveViewModel()
                self.activeViewControllerNew = nil
            }
        }
    }
    
    override func newDraft(vmp: ViewModelProtocolBase) {
        let viewModel = ComposeViewModelImpl(msg: nil, action: .newDraft)
        self.setup(composer: vmp, viewModel: viewModel)
    }
    
    override func newDraft(vmp: ViewModelProtocolBase, with contact: ContactVO?) {
        let viewModel = ComposeViewModelImpl(msg: nil, action: ComposeMessageAction.newDraft)
        if let c = contact {
            viewModel.addToContacts(c)
        }
        self.setup(composer: vmp, viewModel: viewModel)
    }
    
    override func openDraft(vmp: ViewModelProtocolBase, with msg: Message!) {
        let viewModel = ComposeViewModelImpl(msg: msg, action: .openDraft)
        self.setup(composer: vmp, viewModel: viewModel)
    }
    
    override func newDraft(vmp: ViewModelProtocolBase, with msg: Message!, action: ComposeMessageAction) {
        let viewModel = ComposeViewModelImpl(msg: msg, action: action)
        self.setup(composer: vmp, viewModel: viewModel)
    }
    
    override func newDraft(vmp: ViewModelProtocolBase, with mailTo: URL?) {
        let viewModel = ComposeViewModelImpl(msg: nil, action: ComposeMessageAction.newDraft)
        if let mailTo : NSURL = mailTo as NSURL?, mailTo.scheme == "mailto", let resSpecifier = mailTo.resourceSpecifier {
            var rawURLparts = resSpecifier.components(separatedBy: "?")
            if (rawURLparts.count > 2) {
                
            } else {
                let defaultRecipient = rawURLparts[0]
                if defaultRecipient.count > 0 { //default to
                    if defaultRecipient.isValidEmail() {
                        viewModel.addToContacts(ContactVO(name: defaultRecipient, email: defaultRecipient))
                    }
                    PMLog.D("to: \(defaultRecipient)")
                }
                
                if (rawURLparts.count == 2) {
                    let queryString = rawURLparts[1]
                    let params = queryString.components(separatedBy: "&")
                    for param in params {
                        var keyValue = param.components(separatedBy: "=")
                        if (keyValue.count != 2) {
                            continue
                        }
                        let key = keyValue[0].lowercased()
                        var value = keyValue[1]
                        value = value.removingPercentEncoding ?? ""
                        if key == "subject" {
                            PMLog.D("subject: \(value)")
                            viewModel.setSubject(value)
                        }
                        
                        if key == "body" {
                            PMLog.D("body: \(value)")
                            viewModel.setBody(value)
                        }
                        
                        if key == "to" {
                            PMLog.D("to: \(value)")
                            if value.isValidEmail() {
                                viewModel.addToContacts(ContactVO(name: value, email: value))
                            }
                        }
                        
                        if key == "cc" {
                            PMLog.D("cc: \(value)")
                            if value.isValidEmail() {
                                viewModel.addCcContacts(ContactVO(name: value, email: value))
                            }
                        }
                        
                        if key == "bcc" {
                            PMLog.D("bcc: \(value)")
                            if value.isValidEmail() {
                                viewModel.addBccContacts(ContactVO(name: value, email: value))
                            }
                        }
                    }
                }
            }
        }
        self.setup(composer: vmp, viewModel: viewModel)
    }
    
    override func newDraft(vmp: ViewModelProtocolBase, with group: ContactGroupVO) {
        let viewModel = ComposeViewModelImpl(msg: nil, action: ComposeMessageAction.newDraft)
        viewModel.addToContacts(group)
        self.setup(composer: vmp, viewModel: viewModel)
    }
    
    // msg details
    override func messageDetails(fromList vmp: ViewModelProtocol) {
        activeViewController = vmp
    }
    
    override func messageDetails(fromPush vmp: ViewModelProtocol) {
        activeViewController = vmp
    }
    
    override func mailbox(fromMenu vmp : ViewModelProtocol, location : MessageLocation) -> Void {
        if let oldVC = mailboxViewController {
            oldVC.inactiveViewModel()
        }
        mailboxViewController = vmp
        let viewModel = MailboxViewModelImpl(location: location)
        vmp.setViewModel(viewModel)
    }
    override func labelbox(fromMenu vmp : ViewModelProtocol, label: Label) -> Void {
        if let oldVC = mailboxViewController {
            oldVC.inactiveViewModel()
        }
        mailboxViewController = vmp
        let viewModel = LabelboxViewModelImpl(label: label)
        vmp.setViewModel(viewModel)
    }
    
    //
    override func cleanLegacy() {
        //get current cache version
        let currentVersion = userCachedStatus.lastCacheVersion
        if currentVersion > 0 && currentVersion < 98 {
            sharedCoreDataService.cleanLegacy()//clean core data
            
            //get default sharedbased
            let oldDefault = UserDefaults.standard
            
            //keychain part
            oldDefault.removeObject(forKey: "keychainStoreKey")
            UICKeyChainStore.removeItem(forKey: "keychainStoreKey")
            
            oldDefault.removeObject(forKey: "UserTempCachedStatusKey")
            UICKeyChainStore.removeItem(forKey: "UserTempCachedStatusKey")
            
            oldDefault.synchronize()
        }
    }
    
    //contacts
    override func contactsViewModel(_ vmp: ViewModelProtocol) {
        if activeViewController != nil {
            
        }
        activeViewController = vmp
        vmp.setViewModel(ContactsViewModelImpl())
    }
    
    override func contactDetailsViewModel(_ vmp: ViewModelProtocol, contact: Contact!) {
        if activeViewController != nil {
            
        }
        activeViewController = vmp
        vmp.setViewModel(ContactDetailsViewModelImpl(c: contact))
    }
    
    override func contactAddViewModel(_ vmp: ViewModelProtocol) {
        if activeViewController != nil {
            
        }
        activeViewController = vmp
        vmp.setViewModel(ContactAddViewModelImpl())
    }
    
    override func contactAddViewModel(_ vmp: ViewModelProtocol, contactVO: ContactVO!) {
        if activeViewController != nil {
            
        }
        activeViewController = vmp
        vmp.setViewModel(ContactAddViewModelImpl(contactVO: contactVO))
    }
    
    override func contactEditViewModel(_ vmp: ViewModelProtocol, contact: Contact!) {
        if activeViewController != nil {
            
        }
        activeViewController = vmp
        vmp.setViewModel(ContactEditViewModelImpl(c: contact))
    }
    
    override func contactTypeViewModel(_ vmp : ViewModelProtocol, type: ContactEditTypeInterface) {
        
        if activeViewController != nil {
            
        }
        activeViewController = vmp
        vmp.setViewModel(ContactTypeViewModelImpl(t: type))
    }
    
    override func contactSelectContactGroupsViewModel(_ vmp: ViewModelProtocol,
                                                      selectedGroupIDs: [String],
                                                      refreshHandler: @escaping (NSSet) -> Void) {
        activeViewController = vmp
        vmp.setViewModel(ContactGroupsViewModelImpl(state: .ContactSelectGroups,
                                                    selectedGroupIDs: selectedGroupIDs,
                                                    refreshHandler: refreshHandler))
    }
    
    // contact groups
    override func contactGroupsViewModel(_ vmp: ViewModelProtocol) {
        activeViewController = vmp
        vmp.setViewModel(ContactGroupsViewModelImpl(state: .ContactGroupsView))
    }
    
    override func contactGroupDetailViewModel(_ vmp: ViewModelProtocol,
                                              groupID: String,
                                              name: String,
                                              color: String,
                                              emailIDs: NSSet) {
        activeViewController = vmp
        vmp.setViewModel(ContactGroupDetailViewModelImpl(groupID: groupID,
                                                         name: name,
                                                         color: color,
                                                         emailIDs: emailIDs))
    }
    
    override func contactGroupEditViewModel(_ vmp : ViewModelProtocol,
                                            state: ContactGroupEditViewControllerState,
                                            groupID: String? = nil,
                                            name: String? = nil,
                                            color: String? = nil,
                                            emailIDs: NSSet = NSSet()) {
        activeViewController = vmp
        vmp.setViewModel(ContactGroupEditViewModelImpl(state: state,
                                                       groupID: groupID,
                                                       name: name,
                                                       color: color,
                                                       emailIDs: emailIDs))
    }
    
    override func contactGroupSelectColorViewModel(_ vmp: ViewModelProtocol,
                                                   currentColor: String?,
                                                   refreshHandler: @escaping (String?) -> Void) {
        activeViewController = vmp
        vmp.setViewModel(ContactGroupSelectColorViewModelImpl(currentColor: currentColor,
                                                              refreshHandler: refreshHandler))
    }
    
    override func contactGroupSelectEmailViewModel(_ vmp: ViewModelProtocol,
                                                   selectedEmails: NSSet,
                                                   refreshHandler: @escaping (NSSet) -> Void) {
        activeViewController = vmp
        vmp.setViewModel(ContactGroupSelectEmailViewModelImpl(selectedEmails: selectedEmails,
                                                              refreshHandler: refreshHandler))
    }
    
    // composer
    override func buildComposer<T: ViewModelProtocolNew>(_ vmp: T, subject: String, content: String, files: [FileData]) {
        let latestComposerViewModel = ComposeViewModelImpl(subject: subject, body: content, files: files, action: .newDraftFromShare)
        guard let viewModel = latestComposerViewModel as? T.argType else {
            return
        }
        vmp.set(viewModel: viewModel)
    }
    
    func buildTerms(_ base : ViewModelProtocolBase) {
        let model = TermsWebViewModelImpl()
        base.setModel(vm: model)
    }
    
    func buildPolicy(_ base : ViewModelProtocolBase) {
        let model = PolicyWebViewModelImpl()
        base.setModel(vm: model)
    }
    
    /////////////////
    override func upgradeAlert(contacts vmp: ViewModelProtocolBase) {
        vmp.setModel(vm: ContactAlertViewModelImpl())
    }
    override func upgradeAlert(signature vmp: ViewModelProtocolBase) {
        vmp.setModel(vm: SignatureAlertViewModelImpl())
    }
}
