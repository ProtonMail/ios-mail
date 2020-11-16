//
//  ContactImportViewController.swift
//  ProtonMail - Created on 2/7/18.
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
import Contacts

protocol ExpirationWarningVCDelegate {
    func send()
    func learnMore()
}

enum HeaderType {
    case pwd
    case pgp
}

class ExpirationWarningViewController : UIViewController, AccessibleView {
    
    fileprivate let kHeaderView : String = "ExpirationWarningHeaderCell"
    fileprivate let kHeaderID : String   = "expiration_warning_header_cell"
    fileprivate let kCellID : String     = "expiration_warning_email_cell"
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!

    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var learnMore: UIButton!
    
    var delegate : ExpirationWarningVCDelegate?
    var types : [HeaderType] = [HeaderType]()
    var expends : [HeaderType : Bool] = [HeaderType : Bool]()
    var expendsValue : [HeaderType : [String]] = [HeaderType : [String]]()
    
    var pgpEmails : [String] = [String]()
    var nonePMEmails : [String] = [String]()
    func config(needPwd: [String], pgp: [String]) {
        
        if needPwd.count > 0 {
            types.append(.pwd)
            expends[.pwd] = false
            nonePMEmails = needPwd
        }
        
        if pgp.count > 0 {
            types.append(.pgp)
            expends[.pgp] = false
            pgpEmails = pgp
        }
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        /// setup types
        let nib = UINib(nibName: kHeaderView, bundle: nil)
        self.tableView.register(nib, forHeaderFooterViewReuseIdentifier: kHeaderID)
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 60.0
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.noSeparatorsBelowFooter()
        
        
        self.tableView.tableFooterView = footerView
        textLabel.text = LocalString._tap_send_anyway_to_send_without_expiration_to_these_recipients
        let text = LocalString._learn_more_here
        learnMore.setTitle(text, for: .normal)
        headerLabel.text = LocalString._not_all_recipients_support_message_expiration
        cancelButton.layer.borderWidth = 1.0
        cancelButton.layer.borderColor = UIColor.darkGray.cgColor
        generateAccessibilityIdentifiers()
    }
    
    @IBAction func learnMoreAction(_ sender: Any) {
        self.delegate?.learnMore()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    @IBAction func cancelAction(_ sender: Any) {
        self.dismiss()
    }

    @IBAction func sendAction(_ sender: Any) {
        self.dismiss()
        delegate?.send()
    }
    
    private func dismiss() {
        self.dismiss(animated: true, completion: {

        })
    }
}


extension ExpirationWarningViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return types.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard types.count > section else {
            return 0
        }
        
        let type = types[section]
        guard let expend = self.expends[type] else {
            return 0
        }
        
        if expend {
            if type == .pwd {
                return nonePMEmails.count
            } else if type == .pgp {
                return pgpEmails.count
            }
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard types.count > section else {
            return nil
        }
        
        let type = types[section]
        guard let expend = self.expends[type] else {
            return nil
        }
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: kHeaderID) as? ExpirationWarningHeaderCell
        
        if type == .pwd {
            cell?.ConfigHeader(title: LocalString._please_add_a_password_for_the_following_recipients,
                               section: section,
                               expend: expend)
        } else {
            cell?.ConfigHeader(title: LocalString._please_disable_pgp_sending_for_following_addresses,
                               section: section,
                               expend: expend)
        }
        cell?.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 80.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.5
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell  = tableView.dequeueReusableCell(withIdentifier: kCellID, for: indexPath) as! ExpirationWarningEmailCell
        cell.selectionStyle = .none
        
        let section = indexPath.section
        let row = indexPath.row
        if types.count > section {
            let type = types[section]
            if type == .pwd {
                
                if nonePMEmails.count > row {
                    let email = nonePMEmails[row]
                    cell.configCell(email: email)
                }
                
                
            } else if type == .pgp {
                if pgpEmails.count > row {
                    let email = pgpEmails[row]
                    cell.configCell(email: email)
                }
                
            }
        }
        return cell
    }
}


extension ExpirationWarningViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        if (action == #selector(UIResponderStandardEditActions.copy(_:))) {
            return true
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
       return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

extension ExpirationWarningViewController : ExpirationWarningHeaderCellDelegate {
    func clicked(at section: Int, expend: Bool) {
        guard types.count > section else {
            return
        }
        let type = types[section]
        self.expends[type] = expend
        tableView.reloadSections([section], with: .automatic)
        if expend {
            tableView.scrollToRow(at: IndexPath(row: 0, section: section),
                                  at: UITableView.ScrollPosition.top,
                                  animated: true)
        } else {
            tableView.setContentOffset(.zero, animated: true)
        }
    }
}

