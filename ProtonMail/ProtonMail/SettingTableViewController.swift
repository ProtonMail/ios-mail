//
//  SettingTableViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class SettingTableViewController: ProtonMailViewController {
    
    var setting_headers = [SettingSections.Debug, SettingSections.General, SettingSections.MultiDomain, SettingSections.Storage, SettingSections.Version]
    var setting_general_items = [SGItems.NotifyEmail, SGItems.DisplayName, SGItems.Signature, SGItems.LoginPWD, SGItems.MBP]
    var setting_debug_items = [SDebugItem.Queue, SDebugItem.ErrorLogs]
    
    var multi_domains: Array<Address>!
    var userInfo = sharedUserDataService.userInfo
    
    
    /// segues
    let NotificationSegue:String = "setting_notification"
    let DisplayNameSegue:String = "setting_displayname"
    let SignatureSegue:String = "setting_signature"
    let LoginpwdSegue:String = "setting_login_pwd"
    let MailboxpwdSegue:String = "setting_mailbox_pwd"
    
    let DebugQueueSegue : String = "setting_debug_queue_segue"
    
    
    /// cells
    let SettingGeneralCell = "setting_general"
    let SettingDomainsCell = "setting_domains"
    let SettingStorageCell = "setting_storage_cell"
    let HeaderCell = "header_cell"
    
    //
    let CellHeight : CGFloat = 30.0
    
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
        case LoginpwdSegue:
            let changeLoginPwdView = segue.destinationViewController as! ChangePasswordViewController;
            changeLoginPwdView.setViewModel(shareViewModelFactoy.getChangeLoginPassword())
            break
        case MailboxpwdSegue:
            let changeMBPView = segue.destinationViewController as! ChangePasswordViewController;
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeMailboxPassword())
            break
        case NotificationSegue:
            let changeMBPView = segue.destinationViewController as! SettingDetailViewController;
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeNotificationEmail())
            break
        case DisplayNameSegue:
            let changeMBPView = segue.destinationViewController as! SettingDetailViewController;
            changeMBPView.setViewModel(shareViewModelFactoy.getChangeDisplayName())
            break
        case SignatureSegue:
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
            editBarButton.title = NSLocalizedString("Done")
        }
        else
        {
            ActivityIndicatorHelper.showActivityIndicatorAtView(view)
            editBarButton.title = NSLocalizedString("Edit")
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
        return setting_headers.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(setting_headers[section])
        {
        case SettingSections.Debug:
            return setting_debug_items.count
        case SettingSections.General:
            return setting_general_items.count
        case SettingSections.MultiDomain:
            return multi_domains.count
        case SettingSections.Storage:
            return 1
        case SettingSections.Version:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if setting_headers[indexPath.section] == SettingSections.General {
            let cell = tableView.dequeueReusableCellWithIdentifier(SettingGeneralCell, forIndexPath: indexPath) as! GeneralSettingViewCell
            let itme: SGItems = setting_general_items[indexPath.row];
            cell.LeftText.text = itme.description;
            switch itme {
            case SGItems.NotifyEmail:
                cell.RightText.text = userInfo?.notificationEmail;
                break;
            case SGItems.DisplayName:
                cell.RightText.text = userInfo?.displayName;
                break;
            case SGItems.Signature:
                cell.RightText.text = userInfo?.signature;
                break;
            case SGItems.LoginPWD:
                cell.RightText.text = "**********"
                break;
            case SGItems.MBP:
                cell.RightText.text = "**********"
                break;
            }
            return cell
        }
        else if setting_headers[indexPath.section] == SettingSections.MultiDomain {
            let cell = tableView.dequeueReusableCellWithIdentifier(SettingDomainsCell, forIndexPath: indexPath) as! DomainsTableViewCell
            cell.domainText.text = multi_domains[indexPath.row].email
            if indexPath.row == 0
            {
                cell.defaultMark.text = NSLocalizedString("Default")
            }
            else
            {
                cell.defaultMark.text = ""
            }
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        }
        else if setting_headers[indexPath.section] == SettingSections.Storage {
            let cell = tableView.dequeueReusableCellWithIdentifier(SettingStorageCell, forIndexPath: indexPath) as! StorageViewCell
            let usedSpace = sharedUserDataService.usedSpace
            let maxSpace = sharedUserDataService.maxSpace
            cell.setValue(usedSpace, maxSpace: maxSpace)
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        }
        else if setting_headers[indexPath.section] == SettingSections.Debug {
            let cell = tableView.dequeueReusableCellWithIdentifier(SettingGeneralCell, forIndexPath: indexPath) as! GeneralSettingViewCell
            let itme: SDebugItem = setting_debug_items[indexPath.row]
            cell.LeftText.text = itme.description
            cell.RightText.text  = ""
            return cell
        }
        else
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(SettingStorageCell, forIndexPath: indexPath) as! UITableViewCell
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier(HeaderCell) as! CustomHeaderView
        if(setting_headers[section] == SettingSections.Version){
            if let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
                headerCell.headerText.text = NSLocalizedString("Version ") + version
            }
            else
            {
                headerCell.headerText.text = NSLocalizedString("Unkonw Version")
            }
        }
        else
        {
            headerCell.headerText.text = setting_headers[section].description
        }
        return headerCell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return CellHeight;
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if setting_headers[indexPath.section] == SettingSections.General {
            let itme: SGItems = setting_general_items[indexPath.row];
            switch itme {
            case SGItems.NotifyEmail:
                self.performSegueWithIdentifier(NotificationSegue, sender: self)
                break;
            case SGItems.DisplayName:
                self.performSegueWithIdentifier(DisplayNameSegue, sender: self)
                break;
            case SGItems.Signature:
                self.performSegueWithIdentifier(SignatureSegue, sender: self)
                break;
            case SGItems.LoginPWD:
                self.performSegueWithIdentifier(LoginpwdSegue, sender: self)
                break;
            case SGItems.MBP:
                self.performSegueWithIdentifier(MailboxpwdSegue, sender: self)
                break;
            }
        }
        else if setting_headers[indexPath.section] == SettingSections.Debug {
            let itme: SDebugItem = setting_debug_items[indexPath.row];
            switch itme {
            case SDebugItem.Queue:
                self.performSegueWithIdentifier(DebugQueueSegue, sender: self)
                break;
            case SDebugItem.ErrorLogs:
                break;
            }
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if setting_headers[indexPath.section] == SettingSections.MultiDomain {
            return true
        }
        return false
    }
    
    // Override to support conditional rearranging of the table view.
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if setting_headers[indexPath.section] == SettingSections.MultiDomain {
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
        if setting_headers[fromIndexPath.section] == SettingSections.MultiDomain {
            let val = self.multi_domains.removeAtIndex(fromIndexPath.row)
            self.multi_domains.insert(val, atIndex: toIndexPath.row)
            let indexSet = NSIndexSet(index:fromIndexPath.section)
            tableView.reloadData()
        }
    }
    
}

extension SettingTableViewController {
    
    enum SDebugItem: Int, Printable {
        case Queue = 0
        case ErrorLogs = 1
        var description : String {
            switch(self){
            case Queue:
                return NSLocalizedString("Message Queue")
            case ErrorLogs:
                return NSLocalizedString("Error Logs")
            }
        }
    }
    
    enum SGItems: Int, Printable {
        case NotifyEmail = 0
        case DisplayName = 1
        case Signature = 2
        case LoginPWD = 3
        case MBP = 4
        var description : String {
            switch(self){
            case NotifyEmail:
                return NSLocalizedString("Notification Email")
            case DisplayName:
                return NSLocalizedString("Display Name")
            case Signature:
                return NSLocalizedString("Signature")
            case LoginPWD:
                return NSLocalizedString("Login Passowrd")
            case MBP:
                return NSLocalizedString("Mailbox Passowrd")
            }
        }
    }
    
    enum SettingSections: Int, Printable {
        case Debug = 0
        case General = 1
        case MultiDomain = 2
        case Storage = 3
        case Version = 4
        var description : String {
            switch(self){
            case Debug:
                return NSLocalizedString("Debug")
            case General:
                return NSLocalizedString("General Settings")
            case MultiDomain:
                return NSLocalizedString("Multiple Domains")
            case Storage:
                return NSLocalizedString("Storage")
            case Version:
                return NSLocalizedString("")
            }
        }
    }
}
