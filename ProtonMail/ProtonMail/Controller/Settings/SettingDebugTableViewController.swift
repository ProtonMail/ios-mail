//
//  SettingDebugViewController.swift
//  ProtonMail - Created on 6/2/15.
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


import Foundation


class SettingDebugViewController: UITableViewController {
    
    //
    let cellHeight : CGFloat             = 30.0
    let headers : [String]               = ["InQueue", "InFailedQueue"]
    
    let kQueueDebugDetailsSegue : String = "queue_debug_details"
    
    fileprivate var tempSelected : Any!
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
            detailView.setDetailText("\(tempSelected!)")
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return headers.count
    }
    
    @objc override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    @objc override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "setting_debug_cell", for: indexPath) 
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        
        var element : [String : Any]!
        if indexPath.section == 0
        {
            element = sharedMessageQueue.queueArray()[indexPath.row] as! [String : Any]
        }
        else if indexPath.section == 1
        {
            element = sharedFailedQueue.queueArray()[indexPath.row] as! [String : Any]
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
    
    @objc override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerCell = tableView.dequeueReusableCell(withIdentifier: "setting_debug_cell") else {
            return nil
        }
        headerCell.textLabel!.text = headers[section]
        return headerCell
    }
    
    @objc override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return cellHeight;
    }
    
    @objc override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0
        {
            tempSelected = sharedMessageQueue.queueArray()[indexPath.row]
        }
        else if indexPath.section == 1
        {
            tempSelected = sharedFailedQueue.queueArray()[indexPath.row]
        }
        
        self.performSegue(withIdentifier: kQueueDebugDetailsSegue, sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Override to support conditional editing of the table view.
    @objc override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Override to support conditional rearranging of the table view.
    @objc override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    // Override to support editing the table view.
    @objc override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    }
    
    @objc override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none;
    }
    
    @objc override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    @objc override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            return sourceIndexPath;
        }
        else {
            return proposedDestinationIndexPath;
        }
    }
    
    // Override to support rearranging the table view.
    @objc override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        
    }
    
    
}
