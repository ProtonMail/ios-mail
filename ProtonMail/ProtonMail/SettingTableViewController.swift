//
//  SettingTableViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class SettingTableViewController: ProtonMailViewController {
    
    var headers = ["General Settings","Multiple Domains", "Storage", ""]
    var setting_section = [SettingItem.notify_email, SettingItem.display_name, SettingItem.signature, SettingItem.login_pwd, SettingItem.mbp]
    var multi_domains: Array<Address>!
    var userInfo = sharedUserDataService.userInfo
    let notificationSegue:String = "setting_notification"
    let displaynameSegue:String = "setting_displayname"
    let signatureSegue:String = "setting_signature"
    let loginpwdSegue:String = "setting_login_pwd"
    let mailboxpwdSegue:String = "setting_mailbox_pwd"
    
    //
    @IBOutlet weak var editBarButton: UIBarButtonItem!
    @IBOutlet var settingTableView: UITableView!
    
    //
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        userInfo = sharedUserDataService.userInfo
        multi_domains = sharedUserDataService.userAddresses
        UIView.setAnimationsEnabled(false)
        settingTableView.reloadData();
        UIView.setAnimationsEnabled(true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let segueID:String! = segue.identifier
        switch segueID
        {
        case loginpwdSegue:
            let changeLoginPwdView = segue.destinationViewController as! ChangePasswordViewController;
            changeLoginPwdView.setViewModel(shareViewModelFactoy.getChangeLoginPassword())
            break
        case mailboxpwdSegue:
            let changeMBPView = segue.destinationViewController as! ChangePasswordViewController;
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeMailboxPassword())
            break
        case notificationSegue:
            let changeMBPView = segue.destinationViewController as! SettingDetailViewController;
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeNotificationEmail())
            break
        case displaynameSegue:
            let changeMBPView = segue.destinationViewController as! SettingDetailViewController;
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeDisplayName())
            break
        case signatureSegue:
            let changeMBPView = segue.destinationViewController as! SettingDetailViewController;
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeSignature())
            break
        default:
            break
        }
    }


    // MARK: - button acitons
    @IBAction func editAction(sender: AnyObject) {
        settingTableView.setEditing(!settingTableView.editing, animated: true)
        if settingTableView.editing
        {
            editBarButton.title = "Done"
        }
        else
        {
            ActivityIndicatorHelper.showActivityIndicatorAtView(view)
            editBarButton.title = "Edit"
            
            sharedUserDataService.updateUserDomiansOrder(multi_domains) { _, _, error in
                ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
                if let error = error {
                    
                } else {
                    
                }
            }
        }
    }
    
    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return setting_section.count
        }
        else if section == 1 {
            return multi_domains.count
        }
        else if section == 2 {
            return 1
        }
        else if section == 3 {
            return 0
        }
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("setting_general", forIndexPath: indexPath) as! GeneralSettingViewCell
            let itme: SettingItem = setting_section[indexPath.row];
            cell.LeftText.text = itme.identifier;
            
            switch itme {
            case SettingItem.notify_email:
                cell.RightText.text = userInfo?.notificationEmail;
                break;
            case SettingItem.display_name:
                cell.RightText.text = userInfo?.displayName;
                break;
            case SettingItem.signature:
                cell.RightText.text = userInfo?.signature;
                break;
            case SettingItem.login_pwd:
                cell.RightText.text = "**********"
                break;
            case SettingItem.mbp:
                cell.RightText.text = "**********"
                break;
            }
            return cell
        }
        else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier("setting_domains", forIndexPath: indexPath) as! DomainsTableViewCell
            cell.domainText.text = multi_domains[indexPath.row].email
            if indexPath.row == 0
            {
                cell.defaultMark.text = "Default"
            }
            else
            {
                cell.defaultMark.text = ""
            }
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        }
        else if indexPath.section == 2 {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("setting_storage_cell", forIndexPath: indexPath) as! StorageViewCell
            let usedSpace = sharedUserDataService.usedSpace
            let maxSpace = sharedUserDataService.maxSpace
            cell.setValue(usedSpace, maxSpace: maxSpace)
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
            
        }
        else
        {
            let cell = tableView.dequeueReusableCellWithIdentifier("setting_storage_cell", forIndexPath: indexPath) as! UITableViewCell
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier("header_cell") as! CustomHeaderView
        
        switch (section) {
        case 0:
            headerCell.headerText.text = headers[0]
            break
        case 1:
            headerCell.headerText.text = headers[1]
            break
        case 2:
            headerCell.headerText.text = headers[2]
            break
        case 3:
            if let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
                headerCell.headerText.text = "Version " + version
            }
            else
            {
                headerCell.headerText.text = "Unkonw Version"
            }
            break
        default:
            headerCell.headerText.text = headers[3]
            break
        }
        
        return headerCell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 30;
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 0 {
            let itme: SettingItem = setting_section[indexPath.row];
            switch itme {
            case SettingItem.notify_email:
                self.performSegueWithIdentifier("setting_notification", sender: self)
                break;
            case SettingItem.display_name:
                self.performSegueWithIdentifier("setting_displayname", sender: self)
                break;
            case SettingItem.signature:
                self.performSegueWithIdentifier("setting_signature", sender: self)
                break;
            case SettingItem.login_pwd:
                self.performSegueWithIdentifier("setting_login_pwd", sender: self)
                break;
            case SettingItem.mbp:
                self.performSegueWithIdentifier("setting_mailbox_pwd", sender: self)
                break;
            }
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 1 {
            return true
        }
        return false
    }
    
    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.None;
    }
    
    func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            
            return sourceIndexPath;
        }
        else {
            
            return proposedDestinationIndexPath;
        }
    }
    
    // Override to support rearranging the table view.
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        if fromIndexPath.section == 1 {
            let val = self.multi_domains.removeAtIndex(fromIndexPath.row)
            self.multi_domains.insert(val, atIndex: toIndexPath.row)
            let indexSet = NSIndexSet(index:fromIndexPath.section)
            tableView.reloadData()
        }
    }
    
    // Override to support conditional rearranging of the table view.
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 1 {
            return true
        }
        return false
    }
}

extension SettingTableViewController {
    enum SettingItem: String {
        case notify_email = "Notification Email"
        case display_name = "Display Name"
        case signature = "Signature"
        case login_pwd = "Login Passowrd"
        case mbp = "Mailbox Passowrd"
        
        var identifier: String { return rawValue }
    }
}
