//
//  SettingDebugViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/2/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


class SettingDebugViewController: UITableViewController {
    
    //
    let CellHeight : CGFloat = 30.0
    
    
    let Headers = ["InQueue", "InFailedQueue"]
    
    private var tempSelected : AnyObject!
    //
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    // MARK: - button acitons
    @IBAction func editAction(sender: AnyObject) {
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let segueID:String! = segue.identifier
        if (segueID == "queue_debug_details") {
            let detailView = segue.destinationViewController as! DebugDetailViewController;
            detailView.setDetailText("\(tempSelected)")
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Headers.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0
        {
            let count = sharedMessageQueue.count
            return count
        }
        else if section == 1
        {
            let count = sharedFailedQueue.count
            return count
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("setting_debug_cell", forIndexPath: indexPath) as! UITableViewCell
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        var element : [String : AnyObject]!
        if indexPath.section == 0
        {
            element = sharedMessageQueue.getQueue()[indexPath.row] as! [String : AnyObject]
        }
        else if indexPath.section == 1
        {
            element = sharedFailedQueue.getQueue()[indexPath.row] as! [String : AnyObject]
        }
        
        if let element = element["object"] as? [String : String] {
            if let action = element["action"] {
                if let time = element["time"] {
                   cell.textLabel!.text = "\(action) -- \(time) "
                }
            }
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier("setting_debug_cell") as! UITableViewCell
        headerCell.textLabel!.text = Headers[section]
        return headerCell
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return CellHeight;
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 0
        {
            tempSelected = sharedMessageQueue.getQueue()[indexPath.row] as? [String : AnyObject]
        }
        else if indexPath.section == 1
        {
            tempSelected = sharedFailedQueue.getQueue()[indexPath.row] as? [String : AnyObject]
        }
        
        self.performSegueWithIdentifier("queue_debug_details", sender: self)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.None;
    }
    
    override func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    override func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            return sourceIndexPath;
        }
        else {
            return proposedDestinationIndexPath;
        }
    }
    
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        
    }
    
    
}
