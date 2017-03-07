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
    
    fileprivate var tempSelected : AnyObject!
    //
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    // MARK: - button acitons
    @IBAction func editAction(_ sender: AnyObject) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueID:String! = segue.identifier
        if (segueID == "queue_debug_details") {
            let detailView = segue.destination as! DebugDetailViewController;
            detailView.setDetailText("\(tempSelected)")
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Headers.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "setting_debug_cell", for: indexPath) 
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
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
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  headerCell = tableView.dequeueReusableCell(withIdentifier: "setting_debug_cell") as UITableViewCell!
        headerCell?.textLabel!.text = Headers[section]
        return headerCell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return CellHeight;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0
        {
            tempSelected = sharedMessageQueue.getQueue()[indexPath.row] as? [String : AnyObject] as AnyObject!
        }
        else if indexPath.section == 1
        {
            tempSelected = sharedFailedQueue.getQueue()[indexPath.row] as? [String : AnyObject] as AnyObject!
        }
        
        self.performSegue(withIdentifier: "queue_debug_details", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.none;
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            return sourceIndexPath;
        }
        else {
            return proposedDestinationIndexPath;
        }
    }
    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        
    }
    
    
}
