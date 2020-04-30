//
//  NetworkTroubleShootViewController.swift
//  ProtonMail - Created on 3/01/2020.
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
import PMKeymaker
import MessageUI

class NetworkTroubleShootViewController: UITableViewController, ViewModelProtocol, CoordinatedNew {

    public enum Item: Int, CustomStringConvertible {
        public var description: String {
            return ""
        }
        
        case allowSwitch = 0
        case noInternetNotes = 1
        case ipsNotes = 2
        case blockNotes = 3
        case antivirusNotes = 4
        case firewallNotes = 5
        case downtimeNotes = 6
        case otherNotes = 7
        
        public var top : String {
            switch(self){
            case .allowSwitch:
                return "Allow alternative routing"
            case .noInternetNotes:
                return "No internet connection"
            case .ipsNotes:
                return "Internet Service Provider (ISP) problem"
            case .blockNotes:
                return "Government block"
            case .antivirusNotes:
                return "Antivirus interference"
            case .firewallNotes:
                return "Proxy/Firewall interference"
            case .downtimeNotes:
                return "Proton is down"
            case .otherNotes:
                return "Still can't find a solution"
            }
        }
        
        public var bottom : String {
            switch(self){
            case .allowSwitch:
                return "In case Proton sites are blocked, this setting allows the app to try alternative network routing to reach Proton, which can be useful for bypassing firewalls or network issues. We recommend keeping this setting on for greater reliability. [Learn more]"
            case .noInternetNotes:
                return "Please make sure that your internet connection is working."
            case .ipsNotes:
                return "Try connecting to Proton from a different network (or use ProtonVPN or Tor)."
            case .blockNotes:
                return "Your country may be blocking access to Proton. Try using ProtonVPN (or any other VPN) or Tor to access Proton."
            case .antivirusNotes:
                return "Temporarily disable or remove your antivirus software."
            case .firewallNotes:
                return "Disable any proxies or firewalls, or contact your network administrator."
            case .downtimeNotes:
                return "Check Proton Status for our system status."
            case .otherNotes:
                return "Contact us directly through our support form, email (support@protonmail.com), or Twitter."
            }
        }
        
        public var AttrString : NSMutableAttributedString {
            switch(self){
            case .allowSwitch:
                
                let holder = "In case Proton sites are blocked, this setting allows the app to try alternative network routing to reach Proton, which can be useful for bypassing firewalls or network issues. We recommend keeping this setting on for greater reliability. %1$@"
                let learnMore = "Learn more"
                
                let full = String.localizedStringWithFormat(holder, learnMore)
                let attributedString = NSMutableAttributedString(string: full,
                                                                 attributes: [.font : UIFont.preferredFont(forTextStyle: .caption1),
                                                                              .foregroundColor : UIColor.darkGray])
                if let subrange = full.range(of: learnMore) {
                    let nsRange = NSRange(subrange, in: full)
                    attributedString.addAttribute(.link,
                                                  value: "http://protonmail.com/blog/anti-censorship-alternative-routing",
                                                  range: nsRange)
                }
                return attributedString
                
            case .noInternetNotes:
                let full = "Please make sure that your internet connection is working."
                let attributedString = NSMutableAttributedString(string: full,
                                                                 attributes: [NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .caption1),
                                                                              NSAttributedString.Key.foregroundColor : UIColor.darkGray])
                return attributedString
                
            case .ipsNotes:
                let holder = "Try connecting to Proton from a different network (or use %1$@ or %2$@)."
                let field1 = "ProtonVPN"
                let field2 = "Tor"
                
                let full = String.localizedStringWithFormat(holder, field1, field2)
                let attributedString = NSMutableAttributedString(string: full,
                                                                 attributes: [NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .caption1),
                                                                              NSAttributedString.Key.foregroundColor : UIColor.darkGray])
                if let subrange = full.range(of: field1) {
                    let nsRange = NSRange(subrange, in: full)
                    attributedString.addAttribute(.link, value: "https://protonvpn.com", range: nsRange)
                }
                if let subrange = full.range(of: field2) {
                    let nsRange = NSRange(subrange, in: full)
                    attributedString.addAttribute(.link, value: "https://www.torproject.org", range: nsRange)
                }
                return attributedString
                
            case .blockNotes:
                let holder = "Your country may be blocking access to Proton. Try using %1$@ (or any other VPN) or %2$@ to access Proton."
                let field1 = "ProtonVPN"
                let field2 = "Tor"
                
                let full = String.localizedStringWithFormat(holder, field1, field2)
                let attributedString = NSMutableAttributedString(string: full,
                                                                 attributes: [NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .caption1),
                                                                              NSAttributedString.Key.foregroundColor : UIColor.darkGray])
                if let subrange = full.range(of: field1) {
                    let nsRange = NSRange(subrange, in: full)
                    attributedString.addAttribute(.link, value: "https://protonvpn.com", range: nsRange)
                }
                if let subrange = full.range(of: field2) {
                    let nsRange = NSRange(subrange, in: full)
                    attributedString.addAttribute(.link, value: "https://www.torproject.org", range: nsRange)
                }
                return attributedString
                
            case .antivirusNotes:
                let full = "Temporarily disable or remove your antivirus software."
                let attributedString = NSMutableAttributedString(string: full,
                                                                 attributes: [NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .caption1),
                                                                              NSAttributedString.Key.foregroundColor : UIColor.darkGray])
                return attributedString
                
            case .firewallNotes:
                let full = "Disable any proxies or firewalls, or contact your network administrator."
                let attributedString = NSMutableAttributedString(string: full,
                                                                 attributes: [NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .caption1),
                                                                              NSAttributedString.Key.foregroundColor : UIColor.darkGray])
                return attributedString
                
            case .downtimeNotes:
                let holder = "Check Proton Status for our system status."
                let field1 = "Proton Status"
                let full = String.localizedStringWithFormat(holder, field1)
                let attributedString = NSMutableAttributedString(string: full,
                                                                 attributes: [NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .caption1),
                                                                              NSAttributedString.Key.foregroundColor : UIColor.darkGray])
                if let subrange = full.range(of: field1) {
                    let nsRange = NSRange(subrange, in: full)
                    attributedString.addAttributes([.link: "http://protonstatus.com"], range: nsRange)
                }
                return attributedString
                
            case .otherNotes:
                let holder = "Contact us directly through our support form, email (support@protonmail.com), or Twitter."
                let field1 = "support form"
                let field2 = "email"
                let field3 = "Twitter"
                
                let full = String.localizedStringWithFormat(holder, field1, field2, field3)
                let attributedString = NSMutableAttributedString(string: full,
                                                                 attributes: [NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .caption1),
                                                                              NSAttributedString.Key.foregroundColor : UIColor.darkGray])
                if let subrange = full.range(of: field1) {
                    let nsRange = NSRange(subrange, in: full)
                    attributedString.addAttributes([.link: "https://protonmail.com/support-form"], range: nsRange)
                }
                if let subrange = full.range(of: field2) {
                    let nsRange = NSRange(subrange, in: full)
                    attributedString.addAttributes([.link: "mailto:support@protonmail.com"], range: nsRange)
                }
                if let subrange = full.range(of: field3) {
                    let nsRange = NSRange(subrange, in: full)
                    attributedString.addAttributes([.link: "https://twitter.com/ProtonMail"], range: nsRange)
                }
                return attributedString
                
            }
        }
    }
    
    internal var viewModel : NetworkTroubleShootViewModel!
    internal var coordinator : NetworkTroubleShootCoordinator?
    
    func set(viewModel: NetworkTroubleShootViewModel) {
        self.viewModel = viewModel
    }
    
    func set(coordinator: NetworkTroubleShootCoordinator) {
        self.coordinator = coordinator
    }
    
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
    
    ///
    var items : [Item] = [.allowSwitch,.noInternetNotes,.ipsNotes,.blockNotes,.antivirusNotes,.firewallNotes,.downtimeNotes,.otherNotes]
    
    /// cells
    let HeaderCell                    = "header_cell"
    let SwitchTwolineCell             = "switch_two_line_cell"
    
    //
    let CellHeight : CGFloat = 30.0
    var cleaning : Bool      = false
    
    //
    @IBOutlet var settingTableView: UITableView!
    
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateTitle()
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: HeaderCell)
        
        self.tableView.estimatedSectionHeaderHeight = CellHeight
        self.tableView.sectionHeaderHeight = UITableView.automaticDimension
        
        self.tableView.estimatedRowHeight = CellHeight
        self.tableView.rowHeight = UITableView.automaticDimension
        
        self.tableView.noSeparatorsBelowFooter()
        
        
        let newBackButton = UIBarButtonItem(title: LocalString._general_back_action,
                                            style: UIBarButtonItem.Style.plain,
                                            target: self,
                                            action: #selector(NetworkTroubleShootViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
    }
    
    @objc func back(sender: UIBarButtonItem) {
        if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func updateTitle() {
        self.title = "TroubleShooting"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    ///MARK: -- table view delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTwolineCell, for: indexPath)
        if let cellout = cell as? SwitchTwolineCell {
            if item == .allowSwitch {
                cellout.accessoryType = UITableViewCell.AccessoryType.none
                cellout.selectionStyle = UITableViewCell.SelectionStyle.none
                cellout.configCell(item.top, bottomLine: item.AttrString, showSwitcher: true, status: DoHMail.default.status == .on) { cell, newStatus, feedback in
                    if newStatus {
                        DoHMail.default.status = .on
                        userCachedStatus.isDohOn = true
                    } else {
                        DoHMail.default.status = .off
                        userCachedStatus.isDohOn = false
                    }
                }
            } else {
                cellout.accessoryType = UITableViewCell.AccessoryType.none
                cellout.selectionStyle = UITableViewCell.SelectionStyle.none
                cellout.configCell(item.top, bottomLine: item.AttrString, showSwitcher: false, status: false, complete: nil)
                cellout.delegate = self
            }
        }
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 8
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.none
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            return sourceIndexPath
        }
        else {
            return proposedDestinationIndexPath
        }
    }
}



extension NetworkTroubleShootViewController : SwitchTwolineCellDelegate, MFMailComposeViewControllerDelegate {
    func mailto() {
        openMFMail()
    }
    
    func openMFMail(){
        let mailComposer = MFMailComposeViewController()
        mailComposer.setToRecipients(["support@protonmail.com"])
        mailComposer.setSubject("Subject..")
        mailComposer.setMessageBody("Please share your problem.", isHTML: false)
        present(mailComposer, animated: true, completion: nil)
    }
}
