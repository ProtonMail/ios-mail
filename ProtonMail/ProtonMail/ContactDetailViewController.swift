//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import UIKit

class ContactDetailViewController: ProtonMailViewController, ViewModelProtocol {
    
    fileprivate var viewModel : ContactDetailsViewModel!
    
    private let kInvalidEmailShakeTimes: Float         = 3.0
    private let kInvalidEmailShakeOffset: CGFloat      = 10.0
    
    
    fileprivate let kContactDetailsHeaderView : String      = "ContactSectionHeadView"
    fileprivate let kContactDetailsHeaderID : String        = "contact_section_head_view"
    
    fileprivate let kContactDetailsDisplayCell : String     = "contacts_details_display_cell"
    
    fileprivate let kEditContactSegue : String              = "toEditContactSegue"
    fileprivate let kToComposeSegue : String                = "toCompose"
    
    
    let sections: [ContactEditSectionType] = [.display_name,
                                              .emails,
                                              .encrypted_header,
                                              .cellphone,
                                              .home_address,
                                              .information,
                                              .custom_field,
                                              .notes]
    
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var doneItem: UIBarButtonItem!
    
    func inactiveViewModel() {
    }
    
    func setViewModel(_ vm: Any) {
        viewModel = vm as! ContactDetailsViewModel
    }
    
    ///
    override func viewDidLoad() {
        super.viewDidLoad()
        self.doneItem = UIBarButtonItem(title: NSLocalizedString("Edit", comment: "Action"),
                                        style: UIBarButtonItemStyle.plain,
                                        target: self, action: #selector(didTapEditButton(sender:)))
        self.navigationItem.rightBarButtonItem = doneItem
        
        viewModel.getDetails(loading: {
            ActivityIndicatorHelper.showActivityIndicator(at: self.view)
        }) { (contact, error) in
            if nil != contact {
                self.tableView.reloadData()
            }
            ActivityIndicatorHelper.hideActivityIndicator(at: self.view)
        }
        
        let nib = UINib(nibName: kContactDetailsHeaderView, bundle: nil)
        tableView.register(nib, forHeaderFooterViewReuseIdentifier: kContactDetailsHeaderID)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 60.0
        tableView.noSeparatorsBelowFooter()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.zeroMargin()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == kEditContactSegue) {
            let contact = sender as! Contact
            let addContactViewController = segue.destination.childViewControllers[0] as! ContactEditViewController
            addContactViewController.delegate = self
            sharedVMService.contactEditViewModel(addContactViewController, contact: contact)
        } else if (segue.identifier == kToComposeSegue) {
            let composeViewController = segue.destination.childViewControllers[0] as! ComposeEmailViewController
            let contact = sender as? ContactVO
            sharedVMService.newDraftViewModelWithContact(composeViewController, contact: contact)
        }
    }
    
    @objc func didTapEditButton(sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: kEditContactSegue, sender: viewModel.getContact())
    }
    
    override func shouldShowSideMenu() -> Bool {
        return false
    }
}

extension ContactDetailViewController: ContactEditViewControllerDelegate {
    func deleted() {
        self.navigationController?.popViewController(animated: true)
    }
    func updated() {
        self.tableView.reloadData()
    }
}


// MARK: - UITableViewDataSource
extension ContactDetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let s = sections[section]
        switch s {
        case .display_name:
            return 1
        case .emails:
            return viewModel.getOrigEmails().count
        case .encrypted_header:
            return 0
        case .cellphone:
            return viewModel.getOrigCells().count
        case .home_address:
            return viewModel.getOrigAddresses().count
        case .information:
            return viewModel.getOrigInformations().count
        case .custom_field:
            return viewModel.getOrigFields().count
        case .notes:
            return viewModel.getOrigNotes().count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: kContactDetailsHeaderID) as? ContactSectionHeadView       
        let s = sections[section]
        switch s {
        case .display_name:
            let signed = viewModel.statusType2()
            cell?.ConfigHeader(title: NSLocalizedString("Contact Details", comment: "contact section title"), signed: signed)
        case .encrypted_header:
            let signed = viewModel.statusType3()
            cell?.ConfigHeader(title: NSLocalizedString("Encrypted Contact Details", comment: "contact section title"), signed: signed)
        default:
            cell?.ConfigHeader(title: NSLocalizedString("Contact Details", comment: "contact section title"), signed: false)
        }
        if .display_name == s {
            
        } else {
            
        }
        return cell;
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let s = sections[section]
        if (s == .encrypted_header ||
            s == .display_name) {
            return 38.0
        }
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell  = tableView.dequeueReusableCell(withIdentifier: kContactDetailsDisplayCell, for: indexPath) as! ContactDetailsDisplayCell
        let section = indexPath.section
        let row = indexPath.row
        let s = sections[section]
        cell.selectionStyle = .none
        switch s {
        case .display_name:
            let profile = viewModel.getProfile();
            cell.configCell(title: NSLocalizedString("Display Name", comment: "title"), value: profile.newDisplayName)
            cell.selectionStyle = .none
        case .emails:
            let emails = viewModel.getOrigEmails()
            let email = emails[row]
            cell.configCell(title: email.newType, value: email.newEmail)
            cell.selectionStyle = .default
        case .encrypted_header:
            assert(false, "Code should not be here")
        case .cellphone:
            let cells = viewModel.getOrigCells()
            let tel = cells[row]
            cell.configCell(title: tel.newType, value: tel.newPhone)
            cell.selectionStyle = .default
            break
        case .home_address:
            let addrs = viewModel.getOrigAddresses()
            let addr = addrs[row]
            cell.configCell(title: addr.newType, value: addr.newStreet)
            cell.selectionStyle = .default
            break
        case .information:
            let infos = viewModel.getOrigInformations()
            let info = infos[row]
            cell.configCell(title: info.infoType.type, value: info.newValue)
            cell.selectionStyle = .default
            break
        case .custom_field:
            let fields = viewModel.getOrigFields()
            let field = fields[row]
            cell.configCell(title: field.newType, value: field.newField)
            cell.selectionStyle = .default
            break
        case .notes:
            let notes = viewModel.getOrigNotes()
            let note = notes[row]
            cell.configCell(title: NSLocalizedString("Notes", comment: "title"), value: note.newNote)
            cell.selectionStyle = .default
            break
        default:
            break
        }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ContactDetailViewController: UITableViewDelegate {
   
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let s = sections[indexPath.section]
        switch s {
        case .display_name, .emails, .cellphone, .home_address, .information, .custom_field, .notes:
            return UITableViewAutomaticDimension
        case .encrypted_header:
            return 0
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        let s = sections[section]
        switch s {
        case .emails:
            let emails = viewModel.getOrigEmails()
            let email = emails[row]
            let contact = viewModel.getContact()
            let contactVO = ContactVO(id: contact.contactID,
                                      name: contact.name,
                                      email: email.newEmail,
                                      isProtonMailContact: false)
            self.performSegue(withIdentifier: kToComposeSegue, sender: contactVO)
        case .encrypted_header:
            break
        case .cellphone:
            //TODO::bring up the phone call
            break
        case .home_address:
            //TODO::switch to map
            break
        default:
            break
        }
        tableView.reloadSections([section], with: .automatic)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

